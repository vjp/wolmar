#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin;
use lib "$FindBin::Bin/local/lib/perl5";
use LWP::UserAgent;
use Mojo::DOM;
use URI;
use JSON::PP;
use Getopt::Long;
use Mail::IMAPClient;
use MIME::QuotedPrint;
use POSIX qw(strftime);

my (
    $opt_url,
    $opt_email,
    $opt_config,
    $opt_output,
    $opt_no_open,
    $opt_verbose,
    $opt_count,
    $opt_help,
);

GetOptions(
    'url=s'    => \$opt_url,
    'email'    => \$opt_email,
    'config=s' => \$opt_config,
    'output=s' => \$opt_output,
    'count=i'  => \$opt_count,
    'no-open'  => \$opt_no_open,
    'verbose!' => \$opt_verbose,
    'help|h'   => \$opt_help,
) or die usage();

die usage() if $opt_help;
die "Укажите --url или --email\n" unless $opt_url || $opt_email;

$opt_verbose //= 1;
$opt_count   //= 1;
$opt_count    = 1 if $opt_count < 1;

my $config_file = $opt_config || 'numizmatik_vip.conf.json';
my $cfg = {};
if (-e $config_file) {
    my $json = do {
        open my $fh, '<:raw', $config_file or die "Не могу открыть $config_file: $!\n";
        local $/;
        <$fh>;
    };
    $cfg = decode_json($json);
} elsif ($opt_email) {
    die "Для режима --email нужен конфиг $config_file (см. numizmatik_vip.conf.json.example)\n";
}

# Загружаем тот же конфиг монет, что и mparser.pl
my $coins_config_file = 'coins_config.json';
my $coins_json = do {
    open my $fh, '<:raw', $coins_config_file or die "Не могу открыть $coins_config_file: $!\n";
    local $/;
    <$fh>;
};
my $coins = decode_json($coins_json);

my $ex_sr    = $coins->{imperial_silver}      // {};
my $ex_md    = $coins->{imperial_copper}      // {};
my $ex_ssr_m = $coins->{ussr_russia_regular}  // {};
my $ex_ssr   = $coins->{commemorative}        // {};

my @urls;
my %url_email_date;
if ($opt_url) {
    @urls = ($opt_url);
} else {
    @urls = fetch_viporder_urls_from_imap($cfg, $opt_count);
}

die "Не удалось получить ссылки на VIP-распродажи\n" unless @urls;
print "Найдено ссылок на распродажи: " . scalar(@urls) . "\n" if $opt_verbose;

my $ua = build_ua();

my @matched;
my @near;
my %seen_id;

for my $url (@urls) {
    print "Ссылка на распродажу: $url\n" if $opt_verbose;

    my $response = fetch_url($ua, $url);
    my $dom = Mojo::DOM->new($response->decoded_content);
    my @products = $dom->find('div.product.shopitem')->each;
    print "Найдено товаров на странице: " . scalar(@products) . "\n" if $opt_verbose;

    for my $p (@products) {
        my $item = parse_product($p);
        next unless $item && $item->{year};

        $item->{source_url}  = $url;
        $item->{source_date} = extract_campaign_date($url);

        my $res = match_config($item);
        next unless $res;

        # Дедупликация по id товара (одна монета может повторяться в разных распродажах)
        my $dedup_key = $item->{id} || join('|', $item->{title}, $item->{year}, $item->{mint});
        next if $seen_id{$dedup_key}++;

        if ($res == 1) {
            push @matched, $item;
            print "+ Подходит: [$item->{matched_section}] $item->{title} — $item->{price_text}\n" if $opt_verbose;
        } elsif ($res == 2) {
            push @near, $item;
            print "~ Близко: [$item->{matched_section}] $item->{title} — $item->{price_text} ($item->{near_reason})\n" if $opt_verbose;
        }
    }
}

generate_html(\@matched, \@near, \@urls);

exit 0;

# ---------------------------------------------------------------------------
sub usage {
    return <<"USAGE";
Использование: $0 [опции]

Опции:
  --url URL      Ссылка на страницу VIP-распродажи numizmatik.ru
  --email        Взять ссылки из писем на Gmail (требуется конфиг)
  --count N      Сколько последних писем обработать (по умолчанию 1)
  --config FILE  Файл конфигурации IMAP (по умолчанию: numizmatik_vip.conf.json)
  --output FILE  Имя выходного HTML-файла (по умолчанию: numizmatik_vip.html)
  --no-open      Не открывать отчёт в браузере
  --verbose      Подробный вывод (по умолчанию включён)
  --no-verbose   Тихий режим
  --help         Эта справка

Примеры:
  $0 --url "https://www.numizmatik.ru/shopcoins/?page=viporder&id=...&sing=..."
  $0 --email
  $0 --email --count 10
  $0 --email --config my_imap.json --output report.html
USAGE
}

sub build_ua {
    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    $ua->default_header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8');
    $ua->default_header('Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7');
    $ua->default_header('Referer' => 'https://www.numizmatik.ru/');
    $ua->default_header('DNT' => '1');
    $ua->timeout(30);
    return $ua;
}

sub fetch_url {
    my ($ua, $url, $retries) = @_;
    $retries //= 5;
    my $last_error;
    for my $attempt (1 .. $retries) {
        my $response = $ua->get($url);
        return $response if $response->is_success;
        $last_error = $response->status_line;
        print "  Попытка $attempt/$retries не удалась: $last_error\n" if $opt_verbose && $attempt < $retries;
        if ($attempt < $retries) {
            my $delay = 3 + $attempt * 2;
            sleep($delay);
        }
    }
    die "Ошибка загрузки страницы $url: $last_error\n";
}

sub fetch_viporder_urls_from_imap {
    my ($cfg, $count) = @_;
    $count //= 1;
    my $imap_cfg = $cfg->{imap} // {};

    my $server   = $imap_cfg->{server}   or die "В конфиге не задан imap.server\n";
    my $port     = $imap_cfg->{port}     // 993;
    my $user     = $imap_cfg->{username} or die "В конфиге не задан imap.username\n";
    my $pass     = $imap_cfg->{password} or die "В конфиге не задан imap.password\n";
    my $folder   = $imap_cfg->{folder}   // 'INBOX';
    my $from     = $imap_cfg->{from}     // 'numizmatik.ru';
    my $max_scan = $imap_cfg->{max_scan} // 100;

    print "Подключаюсь к IMAP $server:$port как $user...\n" if $opt_verbose;

    my $imap = Mail::IMAPClient->new(
        Server   => $server,
        Port     => $port,
        User     => $user,
        Password => $pass,
        Ssl      => 1,
        Uid      => 1,
        Timeout  => 30,
    ) or die "Не удалось подключиться к IMAP: \$@\n";

    $imap->select($folder) or die "Не удалось выбрать папку $folder: \$@\n";

    # Gmail IMAP не поддерживает поиск по телу письма, поэтому сканируем
    # последние max_scan писем от отправителя (от новых к старым).
    my @msgs = $imap->search('FROM', $from);
    if (!@msgs) {
        $imap->logout;
        die "Не найдено писем от $from\n";
    }
    @msgs = sort { $b <=> $a } @msgs;
    @msgs = @msgs[0 .. ($#msgs < $max_scan - 1 ? $#msgs : $max_scan - 1)];
    print "Сканирую последние " . scalar(@msgs) . " писем от $from\n" if $opt_verbose;

    my @found;
    for my $uid (@msgs) {
        my $raw = $imap->message_string($uid) // '';
        # Письма от numizmatik.ru закодированы в quoted-printable: декодируем
        my $decoded = decode_qp($raw);

        my @urls = $decoded =~ m{(https?://www\.numizmatik\.ru/shopcoins/\?page=viporder[^"'\s<>]+)}gi;
        if (!@urls) {
            @urls = $raw =~ m{(https?://www\.numizmatik\.ru/shopcoins/\?page=viporder[^"'\s<>]+)}gi;
        }
        if (@urls) {
            my $hdr = $imap->parse_headers($uid, 'Date') || {};
            my $ed = $hdr->{Date}[0] // '';
            $ed =~ s/\s+\+\d{4}\s*$//;
            $url_email_date{ $urls[0] } = $ed;
            push @found, $urls[0];
            last if @found >= $count;
        }
    }

    $imap->logout;
    return @found;
}

sub parse_product {
    my ($p) = @_;

    my $id = $p->attr('data-id') // '';

    my $title_node = $p->at('div.product_title span[itemprop="name"]');
    return undef unless $title_node;

    my $title = trim($title_node->text);
    return undef unless $title;

    # Ссылка на товар
    my $link = '';
    my $url_meta = $p->at('meta[itemprop="url"]');
    if ($url_meta) {
        $link = $url_meta->attr('content') // $url_meta->attr('href') // '';
    }
    if (!$link) {
        my $a = $p->at('div.product_title > a');
        $link = $a->attr('href') // '' if $a;
    }
    $link = URI->new_abs($link, 'https://www.numizmatik.ru/')->as_string if $link;

    # Цена: в приоритете meta[itemprop="price"], иначе самый вложенный div.product_price
    my $price_text = '';
    my $price = 0;
    my $price_meta = $p->at('meta[itemprop="price"]');
    if ($price_meta) {
        my $pc = $price_meta->attr('content') // '';
        $price = clean_price($pc);
        $price_text = format_price($price) . ' ₽';
    } else {
        my @price_divs = $p->find('div.product_price')->each;
        my $last = $price_divs[-1];
        if ($last) {
            $price_text = trim($last->all_text);
            $price = clean_price($price_text);
        }
    }

    # Характеристики
    my %features;
    $p->find('ul.product_feat li')->each(sub {
        my $li = shift;
        my $name  = trim($li->at('div[itemprop="name"]')->text // '');
        my $value = trim($li->at('span[itemprop="value"]')->text // '');
        $name =~ s/:\s*$//;
        $features{$name} = $value if $name;
    });

    my $metal_raw = $features{'Металл'} // '';
    my $year      = $features{'Год'}      // '';
    my $condition = $features{'Состояние'} // '';
    my $country   = $features{'Страна'}   // '';

    my $denomination = extract_denomination($title);
    my $mint         = extract_mint($title, $year, $metal_raw, $denomination);
    $condition       = extract_condition($title) unless $condition;

    my $metal_code = '';
    if ($metal_raw =~ /серебро/i) {
        $metal_code = 'Ag';
    } elsif ($metal_raw =~ /медь|бронза/i) {
        $metal_code = 'Cu';
    } elsif ($metal_raw =~ /золото/i) {
        $metal_code = 'Au';
    }

    return {
        id           => $id,
        title        => $title,
        link         => $link,
        price        => $price,
        price_text   => $price_text,
        metal        => $metal_code,
        metal_raw    => $metal_raw,
        year         => $year,
        condition    => $condition,
        denomination => $denomination,
        mint         => $mint,
        country      => $country,
    };
}

sub trim {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/^\s+|\s+$//g;
    $s =~ s/\s+/ /g;
    return $s;
}

sub extract_denomination {
    my ($title) = @_;
    my $d = '';

    if ($title =~ /(\d+\/\d+\s*копейки)/i) {
        $d = $1;
    } elsif ($title =~ /\b(полтинник|полтина)\b/i) {
        $d = '50 копеек';
    } elsif ($title =~ /\b(денежка)\b/i) {
        $d = 'Денежка';
    } elsif ($title =~ /\b(полушка)\b/i) {
        $d = 'Полушка';
    } elsif ($title =~ /\b(\d+)\s*(рубл[а-я]+)\b/i) {
        my $n = $1;
        $d = "$n " . plural_ruble($n);
    } elsif ($title =~ /\b(\d+)\s*(копе[а-я]+)\b/i) {
        my $n = $1;
        $d = "$n " . plural_kopeika($n);
    }

    return $d;
}

sub plural_ruble {
    my ($n) = @_;
    my $m = $n % 100;
    return 'рубль' if $m == 1;
    return 'рубля' if $m >= 2 && $m <= 4;
    return 'рублей';
}

sub plural_kopeika {
    my ($n) = @_;
    my $m = $n % 100;
    return 'копейка' if $m == 1;
    return 'копейки' if $m >= 2 && $m <= 4;
    return 'копеек';
}

sub extract_mint {
    my ($title, $year, $metal_raw, $denom) = @_;
    return '' unless $year && $metal_raw;

    my $y = quotemeta($year);
    my $m = quotemeta($metal_raw);

    # Привязка к номиналу+году надёжнее, чем к году (год может повторяться в диапазоне "1855 – 1881")
    if ($denom) {
        my $d = quotemeta($denom);
        if ($title =~ /$d\s+$y\s+(.*?)\s+$m/i) {
            my $mint = $1;
            $mint =~ s/^\s+|\s+$//g;
            return $mint;
        }
    }

    if ($title =~ /$y\s+(.*?)\s+$m/i) {
        my $mint = $1;
        $mint =~ s/^\s+|\s+$//g;
        return $mint;
    }
    return '';
}

sub extract_condition {
    my ($title) = @_;
    if ($title =~ /\b(XF|VF|F|UNC|AU|EF|VG|G|AG|PF|MS|Proof|CAMEO)\b/i) {
        return uc($1);
    }
    return '';
}

sub extract_campaign_date {
    my ($url) = @_;
    return '' unless defined $url;
    my ($d) = $url =~ /utm_campaign=([^&]+)/i;
    return '' unless defined $d;
    $d =~ s/\+/ /g;
    return $d;
}

sub extract_source_label {
    my ($url) = @_;
    my $d = extract_campaign_date($url);
    return $d if $d;
    if (my $ed = $url_email_date{$url}) {
        $ed =~ s/^\s+|\s+$//g;
        return $ed;
    }
    my ($id) = $url =~ /[?&]id=(\d+)/i;
    return $id ? "id=$id" : $url;
}

sub clean_price {
    my ($p) = @_;
    return 0 unless defined $p;
    $p =~ s/[^\d.,]//g;
    $p =~ s/,/./;
    return $p eq '' ? 0 : 0 + $p;
}

sub match_config {
    my ($item) = @_;

    my $title = $item->{denomination};
    my $year  = $item->{year};
    my $mint  = $item->{mint} // '';
    my $price = $item->{price};
    my $metal = $item->{metal};
    my $condition = $item->{condition} // '';

    return 0 unless $title && $year;

    # Дополнительные правила (не зависят от coins_config.json):
    # любые серебряные 25 рублей < 15000₽ и серебряные 3 рубля < 5000₽.
    # Монеты дороже порога здесь не показываются (не попадают в близкие совпадения).
    if ($metal eq 'Ag') {
        if ($title eq '25 рублей') {
            return 0 unless $price < 15000;
            $item->{matched_section} = 'silver_25rub';
            return 1;
        }
        if ($title eq '3 рубля') {
            return 0 unless $price < 5000;
            $item->{matched_section} = 'silver_3rub';
            return 1;
        }
    }

    # Имперские монеты
    if ($year <= 1917) {
        if ($metal eq 'Ag' && $ex_sr->{$title} && $ex_sr->{$title}->{$year}) {
            return 0 if $mint =~ /$ex_sr->{$title}->{$year}/;
            $item->{matched_section} = 'imperial_silver';
            if ($price >= 10000) {
                $item->{near_reason} = 'цена ≥ 10000₽';
                return 2;
            }
            if ($condition =~ /(AU|MS|PL|UNC|XF|F) (\d+|Det)/) {
                $item->{near_reason} = 'высокая сохранность';
                return 2;
            }
            return 1;
        }
        if ($metal eq 'Cu' && $ex_md->{$title} && $ex_md->{$title}->{$year}) {
            return 0 if $mint =~ /$ex_md->{$title}->{$year}/;
            if ($ex_md->{$title}->{$year} ne '-' && !$mint) {
                return 0;
            }
            $item->{matched_section} = 'imperial_copper';
            if ($price >= 10000) {
                $item->{near_reason} = 'цена ≥ 10000₽';
                return 2;
            }
            if ($condition =~ /(AU|MS) (\d+|Det)/) {
                $item->{near_reason} = 'высокая сохранность';
                return 2;
            }
            return 1;
        }
    }

    # СССР / РСФСР 1918–1991
    if ($year >= 1918 && $year <= 1991 && $ex_ssr_m->{$title} && $ex_ssr_m->{$title}->{$year}) {
        return 0 if $mint =~ /$ex_ssr_m->{$title}->{$year}/;
        $item->{matched_section} = 'ussr_russia_regular';
        if ($price >= 15000) {
            $item->{near_reason} = 'цена ≥ 15000₽';
            return 2;
        }
        if ($condition =~ /(AU|MS|PL|UNC|XF) (\d+|Det)/) {
            $item->{near_reason} = 'высокая сохранность';
            return 2;
        }
        return 1;
    }

    # Памятные монеты России (только современная Россия)
    if ($year >= 1992) {
        my $comm_key = find_commemorative_key($item);
        if ($comm_key && exists $ex_ssr->{$comm_key}) {
            return 0 if defined $ex_ssr->{$comm_key} && $ex_ssr->{$comm_key} eq $year;
            $item->{matched_section} = 'commemorative';
            $item->{comm_key} = $comm_key;
            if ($price >= 10000) {
                $item->{near_reason} = 'цена ≥ 10000₽';
                return 2;
            }
            if ($condition =~ /(CAMEO|PF \d)/) {
                $item->{near_reason} = 'высокая сохранность';
                return 2;
            }
            return 1;
        }
    }

    return 0;
}

sub find_commemorative_key {
    my ($item) = @_;
    my $title = $item->{title};
    my $year  = $item->{year};
    my $denom = $item->{denomination};

    return undef unless $title && $year;

    # Выделяем часть между годом и металлом/состоянием как название монеты
    my $name = '';
    if ($title =~ /$year\s+(.*?)(?:\s+(?:Серебро|Медь|Бронза|Золото|Медно-никель|Латунь|Proof|UNC|XF|VF|PF|MS|AU|EF|VG|F)\b)/i) {
        $name = $1;
        $name =~ s/^\s+|\s+$//g;
    }
    return undef unless $name;

    # Ищем в конфиге ключ вида "N рубля. Название" или "N рублей. Название"
    # Сравниваем только "значащие" слова названия (длина >= 3), чтобы не ловить
    # ложные совпадения вида "ПЛ" внутри "Мореплаватель".
    my @name_words = grep { length($_) >= 3 } split(/\s+/, $name);
    return undef unless @name_words;
    my $name_pat = join('.*?', map { quotemeta($_) } @name_words);

    for my $key (keys %$ex_ssr) {
        next unless $key;
        my $kd = trim($key);

        if ($kd =~ /^\Q$denom\E\.?\s+(.*)/i) {
            my $key_name = $1;
            if ($key_name =~ /$name_pat/i || $name =~ /\Q$key_name\E/i) {
                return $key;
            }
        }
    }

    return undef;
}

sub format_price {
    my ($n) = @_;
    $n = int($n + 0.5);
    my $s = reverse $n;
    $s =~ s/(\d{3})(?=\d)/$1 /g;
    return scalar reverse $s;
}

sub generate_html {
    my ($items, $near, $urls) = @_;

    my $count = scalar @$items;
    my $near_count = scalar @$near;
    my $pages = scalar @$urls;
    my $now = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $filename = $opt_output || 'numizmatik_vip.html';

    my $section_badges = {
        imperial_silver     => 'Серебро империи',
        imperial_copper     => 'Медь империи',
        ussr_russia_regular => 'СССР/РСФСР',
        commemorative       => 'Памятные монеты',
        silver_25rub        => 'Серебро 25 руб.',
        silver_3rub         => 'Серебро 3 руб.',
    };

    my $html = <<'HTML_HEADER';
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VIP-распродажа Numizmatik.ru</title>
    <style>
        * { box-sizing: border-box; font-family: Arial, sans-serif; }
        body { background-color: #f5f5f5; padding: 20px; margin: 0; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); padding: 20px; }
        h1 { color: #333; text-align: center; margin-bottom: 10px; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .subtitle { text-align: center; color: #666; margin-bottom: 20px; }
        .info-bar { background-color: #e8f5e9; padding: 10px 15px; border-radius: 4px; margin-bottom: 20px; font-size: 14px; color: #2e7d32; display: flex; justify-content: space-between; flex-wrap: wrap; }
        .section-title { background: #f1f1f1; padding: 8px 12px; margin-top: 20px; margin-bottom: 10px; border-left: 4px solid #4CAF50; font-weight: bold; color: #333; }
        .section-title-near { border-left: 4px solid #ff9800; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th { background-color: #4CAF50; color: white; padding: 10px; text-align: left; font-weight: bold; position: sticky; top: 0; white-space: nowrap; }
        .near-table th { background-color: #ff9800; }
        td { padding: 8px 10px; border-bottom: 1px solid #ddd; vertical-align: top; }
        tr:hover { background-color: #f1f1f1; }
        .id-cell { font-family: monospace; font-weight: bold; color: #555; white-space: nowrap; }
        .price-cell { font-weight: bold; color: #e53935; white-space: nowrap; }
        .title-cell a { color: #2196F3; text-decoration: none; }
        .title-cell a:hover { text-decoration: underline; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; color: white; background: #607D8B; }
        .badge-silver { background: #9E9E9E; }
        .badge-copper { background: #8D6E63; }
        .badge-ussr { background: #3F51B5; }
        .badge-comm { background: #E91E63; }
        .badge-25 { background: #00acc1; }
        .badge-3 { background: #7e57c2; }
        .date-cell { color: #777; white-space: nowrap; }
        .reason-cell { color: #e65100; white-space: nowrap; }
        .footer { margin-top: 30px; text-align: center; color: #777; font-size: 12px; border-top: 1px solid #eee; padding-top: 15px; }
        .empty { text-align: center; padding: 40px; color: #999; font-size: 16px; }
        @media (max-width: 768px) { table { font-size: 12px; } th, td { padding: 6px; } }
    </style>
</head>
<body>
    <div class="container">
        <h1>VIP-распродажа Numizmatik.ru</h1>
        <div class="subtitle">Отфильтровано по coins_config.json</div>
HTML_HEADER

    $html .= "        <div class=\"info-bar\">\n";
    $html .= "            <span>Подходящих монет: <b>$count</b></span>\n";
    $html .= "            <span>Близких совпадений: <b>$near_count</b></span>\n";
    $html .= "            <span>Распродаж проверено: <b>$pages</b></span>\n";
    $html .= "            <span>Сгенерировано: $now</span>\n";
    $html .= "        </div>\n";

    my @source_links = map { qq{<a href="$_" target="_blank">${\extract_source_label($_)}</a>} } @$urls;
    if (@source_links) {
        $html .= "        <div class=\"info-bar\">\n";
        $html .= "            <span>Источники: " . join(', ', @source_links) . "</span>\n";
        $html .= "        </div>\n";
    }

    # --- Подходящие монеты ---
    if ($count == 0) {
        $html .= "        <div class=\"empty\">Подходящих монет не найдено.</div>\n";
    } else {
        $html .= render_table($items, $section_badges, 'match', "Подходящие монеты ($count)");
    }

    # --- Близкие совпадения ---
    if ($near_count == 0) {
        $html .= "        <div class=\"empty\">Близких совпадений нет.</div>\n";
    } else {
        $html .= render_table($near, $section_badges, 'near', "Близкие совпадения ($near_count)");
    }

    $html .= <<'HTML_FOOTER';
        <div class="footer">
            Сгенерировано numizmatik_vip.pl
        </div>
    </div>
</body>
</html>
HTML_FOOTER

    open my $fh, '>:utf8', $filename or die "Не могу создать $filename: $!\n";
    print $fh $html;
    close $fh;

    print "Отчёт сохранён: $filename (подходящих: $count, близких: $near_count)\n";

    unless ($opt_no_open) {
        if ($^O eq 'darwin') {
            system('open', $filename);
        } elsif ($^O eq 'MSWin32' || $^O eq 'Windows_NT') {
            system('start', $filename);
        } else {
            system('xdg-open', $filename);
        }
    }
}

sub render_table {
    my ($items, $section_badges, $kind, $title) = @_;

    my $html = '';
    $html .= "        <div class=\"section-title" . ($kind eq 'near' ? ' section-title-near' : '') . "\">$title</div>\n";
    $html .= "        <div class=\"table-wrap\">\n";
    $html .= "        <table class=\"" . ($kind eq 'near' ? 'near-table' : '') . "\">\n";
    $html .= "            <thead>\n";
    $html .= "                <tr>\n";
    $html .= "                    <th>ID</th>\n";
    $html .= "                    <th>Раздел</th>\n";
    $html .= "                    <th>Название</th>\n";
    $html .= "                    <th>Год</th>\n";
    $html .= "                    <th>Металл</th>\n";
    $html .= "                    <th>Чеканка</th>\n";
    $html .= "                    <th>Сохр.</th>\n";
    $html .= "                    <th>Цена</th>\n";
    $html .= "                    <th>Распродажа</th>\n";
    if ($kind eq 'near') {
        $html .= "                    <th>Причина</th>\n";
    }
    $html .= "                </tr>\n";
    $html .= "            </thead>\n";
    $html .= "            <tbody>\n";

    for my $item (@$items) {
        my $section = $item->{matched_section} // '';
        my $badge_class = 'badge';
        $badge_class .= ' badge-silver' if $section eq 'imperial_silver';
        $badge_class .= ' badge-copper' if $section eq 'imperial_copper';
        $badge_class .= ' badge-ussr'   if $section eq 'ussr_russia_regular';
        $badge_class .= ' badge-comm'   if $section eq 'commemorative';
        $badge_class .= ' badge-25'     if $section eq 'silver_25rub';
        $badge_class .= ' badge-3'      if $section eq 'silver_3rub';
        my $badge_text = $section_badges->{$section} // $section;

        my $title_html = $item->{link}
            ? qq{<a href="$item->{link}" target="_blank">$item->{title}</a>}
            : $item->{title};

        my $price_fmt = format_price($item->{price});
        my $date = $item->{source_date} // '';
        my $reason = $item->{near_reason} // '';

        $html .= "                <tr>\n";
        $html .= "                    <td class=\"id-cell\">$item->{id}</td>\n";
        $html .= "                    <td><span class=\"$badge_class\">$badge_text</span></td>\n";
        $html .= "                    <td class=\"title-cell\">$title_html</td>\n";
        $html .= "                    <td>$item->{year}</td>\n";
        $html .= "                    <td>$item->{metal_raw}</td>\n";
        $html .= "                    <td>$item->{mint}</td>\n";
        $html .= "                    <td>$item->{condition}</td>\n";
        $html .= "                    <td class=\"price-cell\">$price_fmt ₽</td>\n";
        $html .= "                    <td class=\"date-cell\">$date</td>\n";
        if ($kind eq 'near') {
            $html .= "                    <td class=\"reason-cell\">$reason</td>\n";
        }
        $html .= "                </tr>\n";
    }

    $html .= "            </tbody>\n";
    $html .= "        </table>\n";
    $html .= "        </div>\n";

    return $html;
}

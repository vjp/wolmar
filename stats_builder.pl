#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use URI;
use DBI;
use Getopt::Long;

my $verbose = 1;
my $count = 20;
my $db_file = 'coins_stats.db';
my $init = 0;

Getopt::Long::GetOptions(
    'count=i' => \$count,
    'init'    => \$init,
    'verbose!' => \$verbose,
);

my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
$ua->default_header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8');
$ua->default_header('Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7');
$ua->default_header('Referer' => 'https://www.wolmar.ru/');
$ua->default_header('DNT' => '1');
$ua->default_header('Connection' => 'keep-alive');
$ua->timeout(30);

my $dbh = init_db($db_file, $init);

my $response = $ua->get("https://www.wolmar.ru/");
my $content = $response->decoded_content;

my %all_past_ids;
while ($content =~ m{<div class="right_box_dark">.*?</div>}gs) {
    my $box = $&;
    while ($box =~ m{/auction/(\d+)}g) {
        $all_past_ids{$1} = 1;
    }
}

my @all_past = sort { $b <=> $a } keys %all_past_ids;
if (@all_past > $count) {
    @all_past = @all_past[0 .. $count - 1];
}

print "Найдено прошедших аукционов для парсинга: " . scalar(@all_past) . "\n";
print "ID: " . join(", ", @all_past) . "\n\n";

my $total_new = 0;
my $total_skipped = 0;
my $total_errors = 0;

for my $aid (@all_past) {
    print "Обрабатываю аукцион #$aid...\n";
    my $added = process_auction($aid, $dbh);
    $total_new += $added;
    print "  Добавлено лотов: $added\n\n";
}

$dbh->disconnect;

print "\nГотово! Всего добавлено: $total_new, пропущено (уже есть): $total_skipped, ошибок: $total_errors\n";
print "База данных: $db_file\n";

sub init_db {
    my ($file, $do_init) = @_;
    my $exists = -e $file;

    if ($do_init && $exists) {
        unlink $file or die "Не могу удалить $file: $!";
        $exists = 0;
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
        sqlite_unicode => 1,
    }) or die "Не могу подключиться к БД: $DBI::errstr";

    $dbh->do("PRAGMA journal_mode=WAL");
    $dbh->do("PRAGMA synchronous=NORMAL");

    $dbh->do(<<'SQL');
        CREATE TABLE IF NOT EXISTS lots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            auction_id INTEGER NOT NULL,
            lot_id TEXT,
            title TEXT NOT NULL,
            year TEXT,
            metal TEXT,
            mint TEXT,
            condition TEXT,
            price REAL,
            seller TEXT,
            bids INTEGER,
            url TEXT,
            raw_title TEXT,
            category TEXT,
            parsed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(auction_id, lot_id)
        )
SQL

    $dbh->do("CREATE INDEX IF NOT EXISTS idx_lots_title ON lots(title)");
    $dbh->do("CREATE INDEX IF NOT EXISTS idx_lots_title_year ON lots(title, year)");
    $dbh->do("CREATE INDEX IF NOT EXISTS idx_lots_auction ON lots(auction_id)");

    print "База данных: $file (" . ($exists ? "существует" : "создана") . ")\n";
    return $dbh;
}

sub process_auction {
    my ($aid, $dbh) = @_;

    my @categories = (
        { slug => 'monety-rossii-do-1917-med',      name => 'md' },
        { slug => 'monety-rossii-do-1917-serebro',   name => 'sr' },
        { slug => 'monety-rsfsr-sssr-rossii',        name => 'ss' },
    );

    my $added = 0;

    for my $cat (@categories) {
        my $url = "https://www.wolmar.ru/auction/$aid/$cat->{slug}?all=1";
        print "  Загружаю: $url\n" if $verbose;

        my $response = $ua->get($url);
        unless ($response->is_success) {
            print "  Ошибка: " . $response->status_line . "\n";
            $total_errors++;
            next;
        }

        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($response->decoded_content);
        $tree->eof;

        my @lots = $tree->findnodes('//tr[@lot_id]');
        print "  Найдено лотов в $cat->{name}: " . scalar(@lots) . "\n" if $verbose;

        for my $lot (@lots) {
            my @cells = $lot->findnodes('.//td');
            next unless @cells >= 10;

            my $lot_id = $lot->attr('lot_id') || '';

            my $title_element = $cells[1]->findnodes('.//a[@class="title lot"]')->[0];
            my $raw_title = $title_element ? $title_element->as_trimmed_text : '';
            next unless $raw_title;

            my $link = '';
            if ($title_element) {
                my $href = $title_element->attr('href');
                $link = URI->new_abs($href, $url)->as_string if $href;
            }

            my $year = $cells[2]->as_trimmed_text;
            my $mint = $cells[3]->as_trimmed_text;
            my $metal = $cells[4]->as_trimmed_text;
            my $condition = $cells[5]->as_trimmed_text;
            my $seller = $cells[6]->as_trimmed_text;
            my $bids_text = $cells[7]->as_trimmed_text;
            my $price_text = $cells[8]->as_trimmed_text;
            my $end_time = $cells[9]->as_trimmed_text;

            my $title = clean_title($raw_title);
            my $price = clean_price($price_text);
            my $bids = $bids_text =~ /^\d+$/ ? int($bids_text) : 0;

            my $inserted = $dbh->do(
                "INSERT OR IGNORE INTO lots (auction_id, lot_id, title, year, metal, mint, condition, price, seller, bids, url, raw_title, category) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                {},
                $aid, $lot_id, $title, $year, $metal, $mint, $condition,
                $price, $seller, $bids, $link, $raw_title, $cat->{name}
            );
            if ($inserted && $inserted > 0) {
                $added++;
            } else {
                $total_skipped++;
            }
        }

        $tree->delete;
    }

    return $added;
}

sub clean_title {
    my ($t) = @_;
    $t =~ s/ R\d+.*//;
    $t =~ s/ Петров.*//;
    $t =~ s/ Ильин.*//;
    $t =~ s/\s+$//;
    return $t;
}

sub clean_price {
    my ($p) = @_;
    $p =~ s/[^\d.,]//g;
    $p =~ s/,/./;
    return $p eq '' ? 0 : 0 + $p;
}

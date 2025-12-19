#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use URI;
use Getopt::Long;
use Text::CSV;




my $ex_sr={
        '5 копеек' => {
             1858=>'-',
             1859=>'-',
             1860=>'-',
             1865=>'-',
             1866=>'-',
             1870=>'-',
             1872=>'-',
             # 1874=>'-',
             1878=>'СПБ НI',
             1883=>'СПБ ДС',
             1899=>'СПБ АГ',
             1901=>'СПБ ФЗ',
             1913=>'СПБ ВС',
        }, 
        '10 копеек' => {
             1866=>'СПБ НФ',
             1877=>'СПБ НI',
             1878=>'СПБ НФ',     
             1883=>'-',
             1913=>'СПБ ВС',
        },
        '15 копеек' => {
             1877=>'СПБ HI',
             1882=>'СПБ ДС',
             1885=>'-',
             1887=>'-',
             1888=>'-',
             1896=>'-',
             1912=>'СПБ ЭБ',
             1913=>'СПБ ВС',
        },
        '20 копеек' => {
             1878 => 'СПБ НФ',     
             1901 => 'СПБ ФЗ',
             1912 => 'СПБ ЭБ',
             1917 => '-',        
        },
        '25 копеек' => {
             1858 => 'СПБ ФБ',     
             1860=>'-',
             1861=>'-',
             1862=>'-',
             1863=>'-',
             1864=>'-',
             1865=>'-',
             1866=>'-',
             1867=>'-',
             1868=>'-',
             1869=>'-',
             1870=>'-',
             1871=>'-',
             1872=>'-',
             1873=>'-',
             1874=>'-',
             1875=>'-',
             1876=>'-',
             1879=>'-',
             1880=>'-',
        },    


};        


my $ex_md={
        '5 копеек' => {
             1916=>'-',
             1917=>'-',
             1870=>'ЕМ',
        }, 
        '3 копейки' => {
                1856=>'ЕМ',
                1857=>'ЕМ',
                1859=>'ЕМ',
                1860=>'ЕМ',
                1861=>'ЕМ',
                1862=>'ЕМ',
                1864=>'-',
                1865=>'-',
                1866=>'-',
                1867=>'СПБ',
                1868=>'ЕМ',
                1869=>'ЕМ',
                1870=>'ЕМ',
                1876=>'СПБ',
                1917=>'-',
        },
        '2 копейки' => {
                1856=>'ЕМ',
                1858=>'ЕМ',
                1861=>'ЕМ',
                1862=>'ЕМ',
                1867=>'СПБ',
                1868=>'ЕМ',
                1869=>'ЕМ',
                1870=>'ЕМ',
                1917=>'-',
        },
        '1 копейка' => {
                1858=>'ЕМ',
                1864=>'ЕМ',
                1867=>'-',
                1870=>'ЕМ',
                1884=>'-',  
                1876=>'СПБ',
                1917=>'-',          
        },
        'Денежка' => {
            1858=>'ЕМ',
            1863=>'ЕМ',
            1865=>'-',
            1867=>'-',
        },        

        '1/2 копейки' => {
              1867=>'-',
              1868=>'ЕМ',
              1869=>'-',
              1870=>'ЕМ',
              1872=>'-',
              1875=>'-',
              1881=>'-',
              1894=>'-',
              1916=>'-',

        },
        '1/4 копейки' => {
            1867=>'-',
            1868=>'-',
            1869=>'-',
            1870=>'-',
            1871=>'-',
            1874=>'-',
            1875=>'-',
            1876=>'-',
            1877=>'-',
            1878=>'-',
            1879=>'-',
            1880=>'-',
            1881=>'-',
            1882=>'-',
            1883=>'-',
            1884=>'-',
            1887=>'-',
            1888=>'-',
            1889=>'-',
            1890=>'-',
            1891=>'-',
            1893=>'-',
            1894=>'-',
            1895=>'-',
            1915=>'-',
            1916=>'-',
        },
        'Полушка' => {
            1855=>'ЕМ',
            1860=>'-',
            1862=>'-',
            1863=>'-',
            1865=>'-',
            1866=>'-',
            1867=>'-',
        }        
};

my $ex_ssr ={
    '3 рубля. Московский кремль' => '-',
    '3 рубля. Экспедиция Кука в Русскую Америку' => '-',
    '3 рубля. Петропавловская крепость' => '-',
    '3 рубля. Встреча в верхах в интересах детей' => '-',
    '3 рубля. Форт Росс' => '-',   

    '2 рубля. 200-летие со дня рождения Е.А. Баратынского' => '-',
    '2 рубля. 150-летие со дня рождения Ф.А. Васильева'=>'-',
    '2 рубля. 100-летие со дня рождения Л.П. Орловой' => '-',
    '2 рубля. 100-летие со дня рождения В.П. Чкалова' => '-',
    '2 рубля. Лев' => '2002',
    '2 рубля. Стрелец' => '2002',
    '2 рубля. Академик В.П. Глушко - 100 лет со дня рождения' => '-',
    '2 рубля. Учёный-энциклопедист Д.И. Менделеев - 175 лет со дня рождения' => '-',   
    '2 рубля. Художник И.И. Левитан - 150-летие со дня рождения' => '-',
    '2 рубля. Художник М.В. Нестеров - 150-летие со дня рождения' => '-',
    '2 рубля. Государственный деятель П.А. Столыпин - к 150-летию со дня рождения' => '-',
    '2 рубля. Композитор А.К. Глазунов' => '-',
    '2 рубля. Писатель А.И. Солженицын, к 100-летию со дня рождения (11.12.1918)' => '-',
};


my $verbose=1;

# Создаем User-Agent с полным набором заголовков
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
$ua->default_header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8');
$ua->default_header('Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7');
$ua->default_header('Referer' => 'https://www.wolmar.ru/');
$ua->default_header('DNT' => '1');
$ua->default_header('Connection' => 'keep-alive');
$ua->timeout(30);



my $response = $ua->get("https://www.wolmar.ru/");
my ($aid)=($response->decoded_content=~/<a href="\/auction\/(\d+)">Аукцион VIP №\d+<\/a>/);

my $md_url="https://www.wolmar.ru/auction/$aid/monety-rossii-do-1917-med?all=1";
my $sr_url="https://www.wolmar.ru/auction/$aid/monety-rossii-do-1917-serebro?all=1";
my $ss_url="https://www.wolmar.ru/auction/$aid/monety-rsfsr-sssr-rossii?all=1";
print "AID:>> $aid\n";


my $tree = HTML::TreeBuilder::XPath->new;


# Получаем страницу
my $url=$md_url;

print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
# Используем XPath для более гибкого поиска
$tree->parse($response->decoded_content);
$tree->eof;


$url=$ss_url;
print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
$tree->parse($response->decoded_content);
$tree->eof;

$url=$sr_url;
print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
$tree->parse($response->decoded_content);
$tree->eof;

my @lots = $tree->findnodes('//tr[@lot_id]');


print "Найдено лотов: " . scalar(@lots) . "\n\n";

my $found_count = 0;
my $skipped_count = 0;

foreach my $lot (@lots) {
    # Получаем все ячейки <td> в строке
    my @cells = $lot->findnodes('.//td');
    
    # Пропускаем, если ячеек недостаточно
    next unless @cells >= 10;
    
    # Название лота
    my $title_element = $cells[1]->findnodes('.//a[@class="title lot"]')->[0];
    my $title = $title_element ? $title_element->as_trimmed_text : 'Нет названия';
    
    # Извлекаем данные из названия
    my ($country, $period, $denomination, $year, $condition) = ('', '', '', '', '');
    
    # Извлекаем номинал (копейки, рубль и т.д.)
    if ($title =~ /(\d+\s*(?:рубл[яьи]|копе[йек]|денег|полушек))/i) {
        $denomination = $1;
        # Приводим к стандартному виду
        $denomination =~ s/рубл[яьи]/рубль/i;
        $denomination =~ s/копе[йек]/копеек/i;
        $denomination =~ s/денег/деньга/i;
        $denomination =~ s/полушек/полушка/i;
    }
    
    # Извлекаем год (ищем 4-значное число)
    if ($title =~ /(\b\d{4}\b)/) {
        $year = $1;
    }
    
    # Определяем страну и период по году
    if ($year && $year <= 1917) {
        $country = "Российская империя";
        # Определяем период (император) по году
        if ($year >= 1894 && $year <= 1917) {
            $period = "Император Николай II";
        } elsif ($year >= 1881 && $year <= 1894) {
            $period = "Император Александр III";
        } elsif ($year >= 1855 && $year <= 1881) {
            $period = "Император Александр II";
        }
    } elsif ($year && $year >= 1918 && $year <= 1991) {
        $country = "СССР";
        $period = "Советский период";
    } elsif ($year && $year >= 1992) {
        $country = "Российская Федерация";
        $period = "Современная Россия";
    }
    
    # Извлекаем состояние (XF, VF, F и т.д.)
    if ($title =~ /\b(XF|VF|F|UNC|AU|EF|VG|G|AG|PF|MS)\b/i) {
        $condition = uc($1);
    }
    
    # Формируем ключ для поиска
    my $key = join('|', 
        $country,
        $period,
        $denomination,
        $year,
        $condition,
    );
    

    
    
    # ID лота
    my $lot_id = $lot->attr('lot_id') || '';
    
    # Ссылка на лот
    my $link = '';
    if ($title_element) {
        my $href = $title_element->attr('href');
        $link = URI->new_abs($href, $url)->as_string if $href;
    }
    
    # Год
    my $lot_year = $cells[2]->as_trimmed_text;
    
    # Металл
    my $metal = $cells[4]->as_trimmed_text;
    
    # Чеканка
    my $mint = $cells[3]->as_trimmed_text;
    
    # Состояние
    my $lot_condition = $cells[5]->as_trimmed_text;
    
    # Продавец
    my $seller = $cells[6]->as_trimmed_text;
    
    # Ставки
    my $bids = $cells[7]->as_trimmed_text;
    
    # Текущая цена
    my $price = $cells[8]->as_trimmed_text;
    
    # Окончание
    my $end_time = $cells[9]->as_trimmed_text;
    
    if ($lot_year && $lot_year<1855) {
        $skipped_count++;
        next;
    }


    
    $title=~s/ R.*//;
    $title=~s/ Петров.*//;
    $title=~s/ Ильин.*//;

    $price=~s/ //g;
    if ($ex_md->{$title}->{$lot_year} && $ex_md->{$title}->{$lot_year} ne $mint && $price<10000 && $metal eq 'Cu' && $lot_condition!~/(AU|MS) (\d+|Det)/) {
        if ($ex_md->{$title}->{$lot_year} ne '-'  && !$mint) {
            next
        } else {
            $found_count++;
        }    
    }elsif ($ex_sr->{$title}->{$lot_year} && $ex_sr->{$title}->{$lot_year} ne $mint && $price<10000 && $metal eq 'Ag' && $lot_condition!~/(AU|MS) \d/) {
        $found_count++;

    } elsif ($ex_ssr->{$title} && $ex_ssr->{$title} ne $lot_year && $price<10000 && $lot_condition!~/(CAMEO|PF \d)/) {
        $found_count++;

    } else {
        $skipped_count++;
        next;
    }



    # Вывод информации
    print "ID лота: $lot_id\n";
    print "Название: $title\n";
    print "Ссылка: $link\n" if $link;
    print "Год: $lot_year\n";
    print "Металл: $metal\n";
    print "Чеканка: $mint\n";
    print "Состояние: $lot_condition\n";
    print "Ставки: $bids\n";
    print "Текущая цена: $price\n";
    print "Окончание: $end_time\n";
    print "-" x 60 . "\n";
}

$tree->delete;
print "\nГотово! ";
print "Найдено новых лотов: $found_count. ";
print "Пропущено (уже в коллекции): $skipped_count. ";
print "\n";
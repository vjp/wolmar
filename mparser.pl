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
use DBI;




my $ex_sr={
        '5 копеек' => {
             1858=>'-',
             1859=>'-',
             1860=>'-',
             1865=>'-',
             1866=>'-',
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
             1883=>'СПБ ДС',
             1913=>'СПБ ВС',
        },
        '15 копеек' => {
             1877=>'(HI|НI)',
             1882=>'СПБ НФ',
             1883=>'СПБ ДС',
             1885=>'-',
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
             1881=>'-',
             1882=>'-',
             1883=>'-',
             1884=>'-',
             1885=>'-',
             1886=>'-',
             1887=>'-',
             1888=>'-',
             1889=>'-',
             1890=>'-',
             1891=>'-',
             1892=>'-',
             1893=>'-',
             1894=>'-',
        },  
        'Полтина' =>{
             1855=>'-',
             1856=>'-',
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
             1877=>'(HI|НI)',
             1879=>'-',
             1880=>'-',
             1881=>'-',
             1882=>'-',
             1883=>'-',
             1884=>'-',
             1885=>'-',
        },

        '50 копеек' => {
             1886=>'-',
             1887=>'-',
             1888=>'-',
             1889=>'-',
             1890=>'-',
             1892=>'-',
             1893=>'-',
             1898=>'-',
             1901=>'ФЗ',
             1902=>'-',
             1903=>'-',
             1904=>'-',
             1905=>'-',
             1906=>'-',
             1907=>'-',
             1908=>'-',
             1909=>'-',
             #1910=>'-',
             1914=>'-',
        },
'1 рубль' => {
             1855=>'-',
             1856=>'-',
             1857=>'-',
             1858=>'-',
             1859=>'-',
             1860=>'-',
             1861=>'-',
             1862=>'-',
             1863=>'-',
             1864=>'-',
             1865=>'-',
             1866=>'-',
             1867=>'-',
             1868=>'-',
             1870=>'-',
             1871=>'-',
             1872=>'-',
             1873=>'-',
             1874=>'-',
             1875=>'-',
             1881=>'-',
             1882=>'-',
             1883=>'-',
             1884=>'-',
             1885=>'-',
             1888=>'-',
             1889=>'-',
             1890=>'-',
             1893=>'-',
             1895=>'-',
             1901=>'ФЗ',
             1902=>'-',
             1903=>'-',
             1904=>'-',
             1905=>'-',
             1906=>'-',
             1907=>'-',
             1908=>'-',
             1909=>'-',
             1910=>'-',
             1912=>'-',
             1913=>'-',
             1914=>'-',
             1915=>'-',
        }

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
                #1867=>'СПБ',
                1868=>'ЕМ',
                1869=>'ЕМ',
                1870=>'ЕМ',
                1917=>'-',
        },
        '2 копейки' => {
                1856=>'ЕМ',
                1858=>'ЕМ|EM',
                1861=>'ЕМ',
                1862=>'ЕМ',
                1867=>'СПБ',
                1869=>'ЕМ',
                1870=>'ЕМ',
                1917=>'-',
        },
        '1 копейка' => {
                1858=>'ЕМ',
                1864=>'ЕМ',
                1867=>'СПБ',
                1870=>'ЕМ',
                1917=>'-',          
        },
        'Денежка' => {
            1858=>'ЕМ',
            1863=>'ЕМ',
            1865=>'-',
            1867=>'-',
        },        

        '1/2 копейки' => {
              1867=>'СПБ',
              1868=>'ЕМ',
              1869=>'-',
              1870=>'ЕМ',
              1872=>'-',
              1875=>'-',
              1881=>'-',
              1894=>'-',

        },
        '1/4 копейки' => {
            1867=>'-',
            1868=>'ЕМ',
            1869=>'-',
            1870=>'-',
            1871=>'-',
            1874=>'-',
            #1875=>'-',
            1876=>'-',
            1877=>'-',
            1878=>'-',
            1879=>'-',
            1880=>'-',
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
            1863=>'-',
            1865=>'-',
            1866=>'-',
            1867=>'-',
        }        
};


my $ex_ssr_m={
    '20 копеек' => {
             1970=>'-',
             1971=>'-',
    },
    '15 копеек' => {
             1970=>'-',
             1971=>'-',        
    },
    


} ;       

my $ex_ssr ={

    '3 рубля. Форт Росс' => '-',   
    '3 рубля. Памятник Гагарину в Москве' => '-',

    '2 рубля. 140-летие со дня рождения К.Л.Хетагурова' => '-',
    '2 рубля. 200-летие со дня рождения Е.А. Баратынского' => '-',
    '2 рубля. 150-летие со дня рождения Ф.А. Васильева'=>'-',
    '2 рубля. Лев' => '2002',
    '2 рубля. Стрелец' => '2002',
    '2 рубля. Близнецы' => '2003',

    '2 рубля. 100-летие со дня рождения С.П. Королева' => '-',
    '2 рубля. Детский писатель Н.Н. Носов - 100 лет со дня рождения (23.11.1908 г.)' => '-',
    

    '2 рубля. Учёный-энциклопедист Д.И. Менделеев - 175 лет со дня рождения' => '-',   
    '2 рубля. Выдающиеся спортсмены России (хоккей). А.Н. Мальцев' => '-',  
    '2 рубля. Э.А. Стрельцов. Выдающиеся спортсмены России (футбол)' => '-',
    '2 рубля. К.И. Бесков. Выдающиеся спортсмены России (футбол). К.И. Бесков' => '-',
    '2 рубля. Выдающиеся спортсмены России (хоккей). В.М. Бобров' => '-',
    '2 рубля. Выдающиеся спортсмены России (хоккей). В.Б. Харламов' => '-',
    
    '2 рубля. Л.И. Яшин. Выдающиеся спортсмены России (футбол)' => '-',

    '2 рубля. Шахматист М.М. Ботвинник - 100-летие со дня рождения' => '-',
    '2 рубля. Актер А.И. Райкин - 100-летие со дня рождения' => '-',
    
    '2 рубля. Художник М.В. Нестеров - 150-летие со дня рождения' => '-',
    
    '2 рубля. Небесный усач' => '-',
  
    '2 рубля. 250-летие Генерального штаба Вооруженных сил Российской Федерации' => '-',
    '2 рубля. Сом Солдатова' => '-',
    '2 рубля. Каравайка' => '-',
    '2 рубля. Кулан' => '-',
    # челомей 2014
    # латынина 2014
    #   андрианов 2014


    '2 рубля. Композитор А.К. Глазунов' => '-',
    '2 рубля. Пианист С.Т. Рихтер' => '-',
    '2 рубля. Художник В.А. Серов' => '-',
    # чайковский 2015

    # коршун 2016 
    # манул 2016
    # карамзин 2016
    # гипельс 2016 

    # бальмонт 2017
    # айвазовский 2017 

    '2 рубля. Писатель А.И. Солженицын, к 100-летию со дня рождения (11.12.1918)' => '-',
    '2 рубля. Астроном, геодезист В.Я. Струве, к 225-летию со дня рождения (15.04.1793)' => '-',
    '2 рубля. Писатель Максим Горький, к 150-летию со дня рождения (28.03.1868)' => '-',
    '2 рубля. Балетмейстер М.И. Петипа, к 200-летию со дня рождения (11.03.1818)' => '-',
    '2 рубля. Поэт, актер В.С. Высоцкий' => '-',
    
    '2 рубля. Конструктор оружия М.Т. Калашников, к 100-летию со дня рождения (10.11.1919)' => '-',
    # ибис 2019
    # леопард 2019

    '2 рубля. Писатель И.А. Бунин, к 150-летию со дня рождения (22.10.1870)' => '-',
    '2 рубля. Мореплаватель И.Ф. Крузенштерн, к 250-летию со дня рождения (19.11.1770)' => '-',

    '2 рубля. Поэт Н.А. Некрасов, к 200-летию со дня рождения (10.12.1821)' => '-',
    '2 рубля. Академик А.Д. Сахаров, к 100-летию со дня рождения (21.05.1921)' => '-',
    # достоевский 2021

    '2 рубля. Амет-Хан Султан' => '-',
    '2 рубля. И.Н. Кожедуб' => '-',
    # фиалка 2022

    '2 рубля. Композитор С.В. Рахманинов, к 150-летию со дня рождения' => '-', 
    '2 рубля. Драматург А.Н. Островский, к 200-летию со дня рождения' => '-',
    '2 рубля. Певец Ф.И. Шаляпин, к 150-летию со дня рождения' => '-',
    '2 рубля. Писатель М.М. Пришвин, к 150-летию со дня рождения' => '-',
    # газматов 2023

    '2 рубля. Б.Ф. Сафонов' => '-',
    '2 рубля. Хирург А.В. Вишневский, к 150-летию со дня рождения' => '-',
    
    '2 рубля. Ученый-просветитель Каюм Насыри, к 200-летию со дня рождения' => '-',
    # можайский 2025
    # ламанский 2025
    
    '2 рубля. Писатель М.Е. Салтыков-Щедрин, к 200-летию со дня рождения' => '-',

    # А.П. Маресьев 2026
    # И.А. Плиев 2026
    # Бурденко 2026
    # Кадыров

    '1 рубль. Чёрный журавль' => '-',
    '1 рубль. Выхухоль' => '-',
    '1 рубль. Леопардовый полоз' => '-',

    '1 рубль. Cахалинский осетр' => '-',
    '1 рубль. Алтайский горный баран' => '-',
    '1 рубль. Воздушно-десантные войска. Парашютисты' => '-',
    '1 рубль. Воздушно-десантные войска. Десантник' => '-',
    
    '1 рубль. СУ-25' => '-',
    '1 рубль. Казначейство России' => '-',
    #cк россии 2017
    '1 рубль. Московский метрополитен' => '-',
    #спартак 2024
};

my $html = <<'HTML_HEADER';
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Аукционные лоты</title>
    <style>
        * {
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }
        body {
            background-color: #f5f5f5;
            padding: 20px;
            margin: 0;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 20px;
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }
        .info-bar {
            background-color: #e8f5e9;
            padding: 10px 15px;
            border-radius: 4px;
            margin-bottom: 20px;
            font-size: 14px;
            color: #2e7d32;
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
        }
        .table-wrap {
            overflow-x: auto;
            margin-top: 20px;
        }
        .table-wrap table {
            min-width: 1100px;
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .table-wrap th {
            background-color: #4CAF50;
            color: white;
            padding: 10px 10px;
            text-align: left;
            font-weight: bold;
            position: sticky;
            top: 0;
            white-space: nowrap;
        }
        .table-wrap td {
            padding: 8px 10px;
            border-bottom: 1px solid #ddd;
            white-space: nowrap;
        }
        .trgreen {
            background-color: #f0fff0;
        }
        .trred {
            background-color: #fff0f0;
        }
        
        tr:hover {
            background-color: #f1f1f1;
        }
        .link-cell a {
            color: #2196F3;
            text-decoration: none;
        }
        .link-cell a:hover {
            text-decoration: underline;
            color: #0d8bf2;
        }
        .price-cell {
            font-weight: bold;
            color: #e53935;
            white-space: nowrap;
        }
        .price-cell small {
            font-weight: normal;
            color: #888;
            display: block;
            font-size: 11px;
        }
        .id-cell {
            font-family: monospace;
            font-weight: bold;
            color: #555;
        }
        .status-cell {
            color: #666;
            font-size: 0.9em;
        }
        .metal-cell {
            color: #555;
        }
        .year-cell {
            color: #777;
        }
        .bids-low {
            color: #757575;
        }
        .bids-medium {
            color: #fb8c00;
        }
        .bids-high {
            color: #e53935;
            font-weight: bold;
        }
        .hist-section {
            margin-top: 30px;
            border-top: 2px solid #4CAF50;
            padding-top: 20px;
        }
        .hist-section h2 {
            color: #333;
            font-size: 18px;
            margin-bottom: 15px;
        }
        .hist-section table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        .hist-section th {
            background-color: #607D8B;
            color: white;
            padding: 8px 12px;
            text-align: left;
            font-weight: bold;
            white-space: nowrap;
        }
        .hist-section td {
            padding: 6px 12px;
            border-bottom: 1px solid #ddd;
        }
        .hist-section tr:hover {
            background-color: #f5f5f5;
        }
        .hist-section .hist-title {
            color: #333;
            font-weight: bold;
        }
        .hist-section .hist-price {
            font-weight: bold;
            color: #e53935;
        }
        .hist-detail {
            display: none;
        }
        .hist-detail td {
            padding: 0;
            border: none;
            background: #fafafa;
        }
        .hist-detail .hist-inner {
            padding: 10px 20px 10px 40px;
        }
        .hist-detail .hist-inner table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }
        .hist-detail .hist-inner th {
            background: #cfd8dc;
            color: #333;
            padding: 5px 10px;
            text-align: left;
            font-weight: bold;
            font-size: 11px;
        }
        .hist-detail .hist-inner td {
            padding: 4px 10px;
            border-bottom: 1px solid #eee;
            background: none;
        }
        .lot-row {
            cursor: pointer;
        }
        .lot-row .expand-icon {
            font-size: 10px;
            color: #999;
            margin-left: 4px;
        }
        .lot-row.expanded .expand-icon {
            transform: rotate(90deg);
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #777;
            font-size: 12px;
            border-top: 1px solid #eee;
            padding-top: 15px;
        }
        @media (max-width: 768px) {
            .table-wrap table {
                font-size: 12px;
            }
            .table-wrap th, .table-wrap td {
                padding: 6px 6px;
            }
            .container {
                padding: 10px;
            }
            .info-bar {
                flex-direction: column;
                gap: 5px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Аукционные лоты монет</h1>
HTML_HEADER

$html .= <<"INFO_BAR";
        <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Название</th>
                    <th>Год</th>
                    <th>Металл</th>
                    <th>Чеканка</th>
                    <th>Сохр.</th>
                    <th>Ставки</th>
                    <th>Лидер</th>
                    <th>Текущая цена</th>
                    <th>Средняя цена</th>
                    <th>Окончание</th>
                    <th>Ссылка</th>
                </tr>
            </thead>
            <tbody>
INFO_BAR


my $verbose=1;
my $db_file = 'coins_stats.db';
my $dbh;
if (-e $db_file) {
    $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
        RaiseError => 0,
        AutoCommit => 1,
        sqlite_unicode => 1,
    });
    print "Подключена база исторических цен: $db_file\n" if $verbose;
}

sub format_price {
    my ($n) = @_;
    $n = int($n + 0.5);
    my $s = reverse $n;
    $s =~ s/(\d{3})(?=\d)/$1 /g;
    return scalar reverse $s;
}

sub get_history {
    my ($title, $year, $mint) = @_;
    return undef unless $dbh;
    return undef unless $title;
    my $sql = "SELECT price, condition, lot_id, auction_id, parsed_at, mint FROM lots WHERE title = ? AND year = ? AND price > 0";
    my @bind = ($title, $year);
    if ($mint) {
        $sql .= " AND mint = ?";
        push @bind, $mint;
    }
    $sql .= " ORDER BY auction_id DESC LIMIT 20";
    my $rows = $dbh->selectall_arrayref($sql, {}, @bind);
    return undef unless $rows && @$rows > 0;
    my $count = scalar @$rows;
    my $sum = 0;
    my $min_price = 9e999;
    my $max_price = 0;
    for my $r (@$rows) {
        my $p = $r->[0];
        $sum += $p;
        $min_price = $p if $p < $min_price;
        $max_price = $p if $p > $max_price;
    }
    return {
        count => $count,
        avg   => $sum / $count,
        min   => $min_price,
        max   => $max_price,
        last  => $rows->[0]->[0],
        last_auction => $rows->[0]->[3],
        last_cond    => $rows->[0]->[1],
        rows  => $rows,
    };
}

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
my ($aids)=($response->decoded_content=~/<a href="\/auction\/(\d+)">Аукцион Standart №\d+<\/a>/);


if ($ARGV[0]) {
    $aid=$ARGV[0];
    undef $aids
}    


my $md_url="https://www.wolmar.ru/auction/$aid/monety-rossii-do-1917-med?all=1";
my $sr_url="https://www.wolmar.ru/auction/$aid/monety-rossii-do-1917-serebro?all=1";
my $ss_url="https://www.wolmar.ru/auction/$aid/monety-rsfsr-sssr-rossii?all=1";

my $md2_url="https://www.wolmar.ru/auction/$aids/monety-rossii-do-1917-med?all=1";
my $sr2_url="https://www.wolmar.ru/auction/$aids/monety-rossii-do-1917-serebro?all=1";
my $ss2_url="https://www.wolmar.ru/auction/$aids/monety-rsfsr-sssr-rossii?all=1";



print "AID:>> $aid ($aids)\n";
my $filename="au$aid.html";
open(FH, '>:utf8', $filename) or die "Не могу создать файл $filename: $!";

my $tree = HTML::TreeBuilder::XPath->new;


# Получаем страницу
my $url=$sr_url;
print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
$tree->parse($response->decoded_content);
$tree->eof;
my $url=$md_url;
print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
# Используем XPath для более гибкого поиска
$tree->parse($response->decoded_content);
$tree->eof;
my $url=$ss_url;
print "Загружаем страницу: $url\n" if $verbose;
my $response = $ua->get($url);
die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
$tree->parse($response->decoded_content);
$tree->eof;


if ($aids) {
    my $url=$sr2_url;
    print "Загружаем страницу: $url\n" if $verbose;
    my $response = $ua->get($url);
    die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
    $tree->parse($response->decoded_content);
    $tree->eof;
    my $url=$md2_url;
    print "Загружаем страницу: $url\n" if $verbose;
    my $response = $ua->get($url);
    die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
    # Используем XPath для более гибкого поиска
    $tree->parse($response->decoded_content);
    $tree->eof;
    my $url=$ss2_url;
    print "Загружаем страницу: $url\n" if $verbose;
    my $response = $ua->get($url);
    die "Ошибка загрузки страницы: " . $response->status_line unless $response->is_success;
    $tree->parse($response->decoded_content);
    $tree->eof;
}


my @lots = $tree->findnodes('//tr[@lot_id]');


print "Найдено лотов: " . scalar(@lots) . "\n\n";

my $found_count = 0;
my $skipped_count = 0;
my $hist_row_id = 0;






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
    if ($ex_md->{$title}->{$lot_year} && ($mint!~/$ex_md->{$title}->{$lot_year}/) && $price<10000 && $metal eq 'Cu' && $lot_condition!~/(AU|MS) (\d+|Det)/) {
        if ($ex_md->{$title}->{$lot_year} ne '-'  && !$mint) {
            next
        } else {
            $found_count++;
        }    
    }elsif ($ex_sr->{$title}->{$lot_year} && ($mint!~/$ex_sr->{$title}->{$lot_year}/) && $price<10000 && ($metal eq 'Ag') && $lot_condition!~/(AU|MS|PL|UNC|XF|F) (\d+|Det)/) {
        $found_count++;

    } elsif ($ex_ssr->{$title} && $ex_ssr->{$title} ne $lot_year && $price<10000 && $lot_condition!~/(CAMEO|PF \d)/) {
        $found_count++;

    } elsif ($ex_ssr_m->{$title}->{$lot_year} && ($mint!~/$ex_ssr_m->{$title}->{$lot_year}/) && $price<15000 && $lot_condition!~/(AU|MS|PL|UNC|XF) (\d+|Det)/) {
        $found_count++;


    } else {
        $skipped_count++;
        next;
    }

    my $hist = get_history($title, $lot_year, $mint);
    my $hist_html = '<td class="price-cell">—</td>';
    my $detail_row = '';
    if ($hist) {
        $hist_row_id++;
        my $hid = "hist-$hist_row_id";
        $hist_html = sprintf(
            '<td class="price-cell">%s ₽ <span class="expand-icon">▶</span><br><small>%d шт., ср. %s ₽</small></td>',
            format_price($hist->{last}),
            $hist->{count},
            format_price(int($hist->{avg} + 0.5)),
        );
        $detail_row .= qq{<tr class="hist-detail" id="$hid">\n};
        $detail_row .= qq{    <td colspan="11">\n};
        $detail_row .= qq{        <div class="hist-inner">\n};
        $detail_row .= qq{            <table>\n};
        $detail_row .= qq{                <tr>\n};
        $detail_row .= qq{                    <th>Сохранность</th>\n};
        $detail_row .= qq{                    <th>МД</th>\n};
        $detail_row .= qq{                    <th>Цена</th>\n};
        $detail_row .= qq{                    <th>Аукцион</th>\n};
        $detail_row .= qq{                </tr>\n};
        for my $r (@{$hist->{rows}}) {
            my ($price, $cond, $l_id, $auc_id, $parsed_at, $h_mint) = @$r;
            $detail_row .= qq{                <tr>\n};
            $detail_row .= qq{                    <td>$cond</td>\n};
            $detail_row .= qq{                    <td>$h_mint</td>\n};
            $detail_row .= qq{                    <td class="hist-price">} . format_price($price) . qq{ ₽</td>\n};
            $detail_row .= qq{                    <td><a href="https://www.wolmar.ru/auction/$auc_id/$l_id" target="_blank">#$auc_id</a></td>\n};
            $detail_row .= qq{                </tr>\n};
        }
        $detail_row .= qq{            </table>\n};
        $detail_row .= qq{        </div>\n};
        $detail_row .= qq{    </td>\n};
        $detail_row .= qq{</tr>\n};
    }

    # Вывод информации
    print "ID лота: $lot_id\n";
    print "Название: $title\n";
    print "Ссылка: $link\n" if $link;
    print "Год: $lot_year\n";
    print "Металл: $metal\n";
    print "Чеканка: $mint\n";
    print "Состояние: $lot_condition\n";
    print "Ставки: $bids \n";
    print "Лидер: $seller \n";
    
    print "Текущая цена: $price\n";
    if ($hist) {
        my $avg_int = int($hist->{avg} + 0.5);
        print "История: $hist->{count} продаж, ср. ${avg_int}₽, последняя $hist->{last}₽\n";
    }
    print "Окончание: $end_time\n";
    print "-" x 60 . "\n";

    my $bids_class = 'bids-low';
    $bids_class = 'bids-medium' if $bids >= 1 && $bids <= 5;
    $bids_class = 'bids-high' if $bids > 5;

    my $row_class = '';
    if ($seller ne 'vjpcoins' && $price<3000) {
        $row_class = 'trred';
    } elsif ($seller eq 'vjpcoins') {
        $row_class = 'trgreen';
    }
    if ($detail_row) {
        $row_class .= ' lot-row';
    }
    if ($row_class) {
        $html .= "<tr class=\"$row_class\">\n";
    } else {
        $html .= "<tr>\n";
    }

    $html .= "    <td class=\"id-cell\">$lot_id</td>\n";
    $html .= "    <td>$title</td>\n";
    $html .= "    <td class=\"year-cell\">$lot_year</td>\n";
    $html .= "    <td class=\"metal-cell\">$metal</td>\n";
    $html .= "    <td>$mint</td>\n";
    $html .= "    <td class=\"status-cell\">$lot_condition</td>\n";
    $html .= "    <td class=\"$bids_class\">$bids</td>\n";
    $html .= "    <td>$seller</td>\n";
    $html .= "    <td class=\"price-cell\">$price ₽</td>\n";
    $html .= "    $hist_html\n";
    $html .= "    <td>$end_time</td>\n";
    $html .= "    <td class=\"link-cell\"><a href=\"$link\" target=\"_blank\">🔗 Перейти</a></td>\n";
    $html .= "</tr>\n";
    if ($detail_row) {
        $html .= $detail_row;
    }


}

$tree->delete;

$html .= "        </tbody>\n";
$html .= "    </table>\n";
$html .= "    </div>\n";

$html .= "        <div class=\"footer\">\n";
$html .= "            Сгенерировано Wolmar Parser\n";
$html .= "        </div>\n";
$html .= "    </div>\n";
$html .= "<script>\n";
$html .= "document.addEventListener('DOMContentLoaded', function() {\n";
$html .= "    var rows = document.querySelectorAll('tr.lot-row');\n";
$html .= "    for (var i = 0; i < rows.length; i++) {\n";
$html .= "        rows[i].addEventListener('click', function(e) {\n";
$html .= "            if (e.target.closest('a')) return;\n";
$html .= "            var detail = this.nextElementSibling;\n";
$html .= "            if (detail && detail.classList.contains('hist-detail')) {\n";
$html .= "                var isVisible = detail.style.display === 'table-row';\n";
$html .= "                detail.style.display = isVisible ? 'none' : 'table-row';\n";
$html .= "                var icon = this.querySelector('.expand-icon');\n";
$html .= "                if (icon) icon.textContent = isVisible ? '▶' : '▼';\n";
$html .= "            }\n";
$html .= "        });\n";
$html .= "    }\n";
$html .= "});\n";
$html .= "</script>\n";
$html .= "</body>\n";
$html .= "</html>\n";

print "\nГотово! ";
print "Найдено новых лотов: $found_count. ";
print "Пропущено (уже в коллекции): $skipped_count. ";
print "\n";

print FH $html;
close FH;

if ($^O eq 'MSWin32' || $^O eq 'Windows_NT') {
    system("start $filename");
} elsif ($^O eq 'darwin') {
    system("open $filename");
} else {
    system("xdg-open $filename");
}



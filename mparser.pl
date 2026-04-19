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
             1872=>'-',
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
             1877=>'(HI|НI)',
             1882=>'СПБ НФ',
             1885=>'-',
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
             1901=>'-',
             1902=>'-',
             1903=>'-',
             1904=>'-',
             1905=>'-',
             1906=>'-',
             1907=>'-',
             1908=>'-',
             1909=>'-',
             1910=>'-',
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
             1869=>'-',
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
                1866=>'-',
                #1867=>'СПБ',
                1868=>'ЕМ',
                1869=>'ЕМ',
                1870=>'ЕМ',
                1876=>'СПБ',
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
                1867=>'-',
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


my $ex_ssr_m={
    '50 копеек' => {
             1971=>'-',
    },
    '20 копеек' => {
             1966=>'-',
             1970=>'-',
             1971=>'-',
    },
    '15 копеек' => {
             1965 =>'-',
             1966=>'-',
             1970=>'-',
             1971=>'-',        
    },
    '10 копеек' => {
            1965 =>'-',
    },
    


} ;       

my $ex_ssr ={
    '3 рубля. Встреча в верхах в интересах детей' => '-',
    '3 рубля. Форт Росс' => '-',   
    '3 рубля. Памятник Гагарину в Москве' => '-',

    '2 рубля. 140-летие со дня рождения К.Л.Хетагурова' => '-',
    '2 рубля. 200-летие со дня рождения Е.А. Баратынского' => '-',
    '2 рубля. 150-летие со дня рождения Ф.А. Васильева'=>'-',
    '2 рубля. Лев' => '2002',
    '2 рубля. Стрелец' => '2002',
    '2 рубля. Близнецы' => '2003',

    '2 рубля. 100-летие со дня рождения С.П. Королева' => '-',
    '2 рубля. Академик В.П. Глушко - 100 лет со дня рождения' => '-',
    '2 рубля. Детский писатель Н.Н. Носов - 100 лет со дня рождения (23.11.1908 г.)' => '-',
    

    '2 рубля. Учёный-энциклопедист Д.И. Менделеев - 175 лет со дня рождения' => '-',   
    '2 рубля. Выдающиеся спортсмены России (хоккей). А.Н. Мальцев' => '-',  
    '2 рубля. Э.А. Стрельцов. Выдающиеся спортсмены России (футбол)' => '-',
    '2 рубля. К.И. Бесков. Выдающиеся спортсмены России (футбол). К.И. Бесков' => '-',
    '2 рубля. Выдающиеся спортсмены России (хоккей). В.М. Бобров' => '-',
    '2 рубля. Выдающиеся спортсмены России (хоккей). В.Б. Харламов' => '-',
    
    '2 рубля. Л.И. Яшин. Выдающиеся спортсмены России (футбол)' => '-',

    '2 рубля. Художник И.И. Левитан - 150-летие со дня рождения' => '-',

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
    # андрианов 2014


    '2 рубля. Композитор А.К. Глазунов' => '-',
    '2 рубля. Пианист С.Т. Рихтер' => '-',
    '2 рубля. Художник В.А. Серов' => '-',
    # чайковский 2015

    '2 рубля. Поэт Г.М. Тукай, к 130-летию со дня рождения (26.04.1886)' => '-',
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

    '2 рубля. Сетконоска сдвоенная' => '-',
    '2 рубля. Амет-Хан Султан' => '-',
    '2 рубля. И.Н. Кожедуб' => '-',
    # одуванчик 2022
    # фиалка 2022

    '2 рубля. Композитор С.В. Рахманинов, к 150-летию со дня рождения' => '-', 
    '2 рубля. Драматург А.Н. Островский, к 200-летию со дня рождения' => '-',
    '2 рубля. Певец Ф.И. Шаляпин, к 150-летию со дня рождения' => '-',
    '2 рубля. Писатель М.М. Пришвин, к 150-летию со дня рождения' => '-',
    # газматов 2023

    '2 рубля. Б.Ф. Сафонов' => '-',
    '2 рубля. Хирург А.В. Вишневский, к 150-летию со дня рождения' => '-',
    # гнесина 2024
    
    '2 рубля. Л.А. Говоров' => '-',
    # насыри 2025
    # можайский 2025
    # ламанский 2025
    
    # салтыков-щедрин 2026

    '1 рубль. Гусь-белошей' => '-',

    '1 рубль. Чёрный журавль' => '-',
    '1 рубль. Выхухоль' => '-',
    '1 рубль. Леопардовый полоз' => '-',

    '1 рубль. Cахалинский осетр' => '-',
    '1 рубль. Западносибирский бобр' => '-',
    '1 рубль. Алтайский горный баран' => '-',

    '1 рубль. Красный волк' => '-',
    
    '1 рубль. Воздушно-десантные войска. Парашютисты' => '-',
    '1 рубль. Воздушно-десантные войска. Десантник' => '-',
    
    '1 рубль. СУ-25' => '-',
    '1 рубль. Казначейство России' => '-',
    #cк россии 2017
    #росреестр 2018
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
            max-width: 1200px;
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
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background-color: #4CAF50;
            color: white;
            padding: 12px 15px;
            text-align: left;
            font-weight: bold;
            position: sticky;
            top: 0;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #ddd;
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
            word-break: break-all;
        }
        .link-cell a:hover {
            text-decoration: underline;
            color: #0d8bf2;
        }
        .price-cell {
            font-weight: bold;
            color: #e53935;
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
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #777;
            font-size: 12px;
            border-top: 1px solid #eee;
            padding-top: 15px;
        }
        @media (max-width: 768px) {
            table {
                font-size: 14px;
            }
            th, td {
                padding: 8px 10px;
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
        <table>
            <thead>
                <tr>
                    <th>ID лота</th>
                    <th>Название</th>
                    <th>Год</th>
                    <th>Металл</th>
                    <th>Чеканка</th>
                    <th>Состояние</th>
                    <th>Ставки</th>
                    <th>Лидер</th>
                    <th>Текущая цена</th>
                    <th>Окончание</th>
                    <th>Ссылка</th>
                </tr>
            </thead>
            <tbody>
INFO_BAR


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
    print "Окончание: $end_time\n";
    print "-" x 60 . "\n";

    my $bids_class = 'bids-low';
    $bids_class = 'bids-medium' if $bids >= 1 && $bids <= 5;
    $bids_class = 'bids-high' if $bids > 5;

   if ($seller ne 'vjpcoins' && $price<3000) {
      $html .= "<tr class=\"trred\">\n";
   } elsif ($seller eq 'vjpcoins') {
     $html .= "<tr class=\"trgreen\">\n";
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
    $html .= "    <td>$end_time</td>\n";
    $html .= "    <td class=\"link-cell\"><a href=\"$link\" target=\"_blank\">🔗 Перейти</a></td>\n";


}

$tree->delete;
print "\nГотово! ";
print "Найдено новых лотов: $found_count. ";
print "Пропущено (уже в коллекции): $skipped_count. ";
print "\n";

print FH $html;
close FH;

system("open $filename");


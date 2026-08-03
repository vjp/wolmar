#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use HTTP::Daemon;
use HTTP::Status;
use JSON::PP;
use Encode qw(encode_utf8);

my $port = $ARGV[0] || 8081;
my $config_file = 'coins_config.json';

sub load_config_raw {
    open my $fh, '<:raw', $config_file or die "Не могу открыть $config_file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub load_config {
    my $raw = load_config_raw();
    return decode_json($raw);
}

sub save_config {
    my ($json_text) = @_;
    my $data = decode_json($json_text);
    open my $fh, '>:raw', $config_file or die "Не могу записать $config_file: $!";
    print $fh $json_text;
    close $fh;
    return $data;
}

my $d = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    ReuseAddr => 1,
) or die "Не могу запустить сервер на порту $port: $!";

print "Редактор конфига запущен: http://127.0.0.1:$port\n";
print "Нажмите Ctrl+C для остановки.\n";

my $url = "http://127.0.0.1:$port";
if ($^O eq 'MSWin32' || $^O eq 'Windows_NT') {
    system("start $url");
} elsif ($^O eq 'darwin') {
    system("open $url");
} else {
    system("xdg-open $url");
}

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        my $path = $r->uri->path;
        my $method = $r->method;

        if ($path eq '/' && $method eq 'GET') {
            $c->send_response(
                HTTP::Response->new(
                    RC_OK,
                    'OK',
                    ['Content-Type' => 'text/html; charset=utf-8'],
                    encode_utf8(editor_html())
                )
            );
        }
        elsif ($path eq '/api/config' && $method eq 'GET') {
            $c->send_response(
                HTTP::Response->new(
                    RC_OK,
                    'OK',
                    ['Content-Type' => 'application/json; charset=utf-8'],
                    load_config_raw()
                )
            );
        }
        elsif ($path eq '/api/config' && $method eq 'POST') {
            my $body = $r->content;
            eval {
                save_config($body);
                $c->send_response(
                    HTTP::Response->new(
                        RC_OK,
                        'OK',
                        ['Content-Type' => 'application/json; charset=utf-8'],
                        '{"ok":true}'
                    )
                );
            };
            if ($@) {
                my $err = $@;
                $err =~ s/"/\\"/g;
                $err =~ s/\n/ /g;
                $c->send_response(
                    HTTP::Response->new(
                        RC_BAD_REQUEST,
                        'Bad Request',
                        ['Content-Type' => 'application/json; charset=utf-8'],
                        encode_utf8(qq{{"ok":false,"error":"$err"}})
                    )
                );
            }
        }
        else {
            $c->send_response(HTTP::Response->new(RC_NOT_FOUND, 'Not Found'));
        }
    }
    $c->close;
    undef $c;
}

sub editor_html {
    return <<'HTML';
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Редактор конфига монет</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
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
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }
        .tabs {
            display: flex;
            gap: 8px;
            margin-bottom: 15px;
            flex-wrap: wrap;
        }
        .tab {
            padding: 10px 16px;
            cursor: pointer;
            border: 1px solid #ccc;
            background: #f9f9f9;
            border-radius: 4px 4px 0 0;
            user-select: none;
        }
        .tab:hover { background: #eee; }
        .tab.active {
            background: #4CAF50;
            color: white;
            border-color: #4CAF50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 6px 8px;
            text-align: left;
        }
        th {
            background: #4CAF50;
            color: white;
            font-weight: bold;
        }
        td input {
            width: 100%;
            border: none;
            padding: 4px;
            font: inherit;
            background: transparent;
        }
        td input:focus {
            outline: 2px solid #81C784;
            background: #f0fff0;
        }
        tr:hover { background: #f9f9f9; }
        tr.inactive {
            background: #fafafa;
            opacity: 0.65;
        }
        td input[type="checkbox"] {
            width: auto;
            cursor: pointer;
            transform: scale(1.2);
        }
        td.center { text-align: center; }
        .actions {
            margin-top: 15px;
            display: flex;
            gap: 10px;
            align-items: center;
        }
        button {
            padding: 8px 16px;
            cursor: pointer;
            border: 1px solid #ccc;
            background: #f5f5f5;
            border-radius: 4px;
            font-size: 14px;
        }
        button:hover { background: #e0e0e0; }
        button.primary {
            background: #4CAF50;
            color: white;
            border-color: #4CAF50;
        }
        button.primary:hover { background: #43A047; }
        button.danger { color: #c62828; }
        .status {
            margin-left: 10px;
            font-weight: bold;
        }
        .status.ok { color: #2e7d32; }
        .status.err { color: #c62828; }
        .hint {
            color: #666;
            font-size: 12px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Редактор coins_config.json</h1>
        <div class="tabs" id="tabs"></div>
        <div id="editor"></div>
        <div class="actions">
            <button id="saveBtn" class="primary">Сохранить</button>
            <button id="addRow">Добавить строку</button>
            <span id="status" class="status"></span>
        </div>
        <div class="hint">
            Изменения сохраняются напрямую в файл coins_config.json. Перед сохранением они валидируются как JSON.
        </div>
    </div>

    <script>
        const categories = [
            { key: 'imperial_silver', label: 'Серебро империи', type: 'year_mint' },
            { key: 'imperial_copper', label: 'Медь империи', type: 'year_mint' },
            { key: 'ussr_russia_regular', label: 'СССР/Россия обычные', type: 'year_mint' },
            { key: 'commemorative', label: 'Памятные монеты', type: 'key_value' }
        ];

        let config = {};
        let activeCat = categories[0].key;

        function esc(s) {
            return String(s)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;');
        }

        async function load() {
            try {
                const resp = await fetch('/api/config');
                if (!resp.ok) throw new Error('HTTP ' + resp.status);
                config = await resp.json();
                renderTabs();
                render();
            } catch (e) {
                setStatus('Ошибка загрузки: ' + e.message, true);
            }
        }

        function renderTabs() {
            const el = document.getElementById('tabs');
            el.innerHTML = categories.map(c =>
                `<div class="tab ${c.key === activeCat ? 'active' : ''}" data-cat="${esc(c.key)}">${esc(c.label)}</div>`
            ).join('');
            el.querySelectorAll('.tab').forEach(tab => {
                tab.onclick = () => setActive(tab.dataset.cat);
            });
        }

        function getDataFromUI() {
            const cat = categories.find(c => c.key === activeCat);
            const rows = document.querySelectorAll('#editor tbody tr');
            const result = {};
            rows.forEach(row => {
                const inputs = row.querySelectorAll('input');
                const name = inputs[0].value.trim();
                if (!name) return;
                if (cat.type === 'year_mint') {
                    const year = inputs[1].value.trim();
                    const active = inputs[3].checked;
                    if (!year) return;
                    if (!result[name]) result[name] = {};
                    result[name][year] = active ? inputs[2].value.trim() : null;
                } else {
                    const active = inputs[2].checked;
                    result[name] = active ? inputs[1].value.trim() : null;
                }
            });
            return result;
        }

        function setActive(cat) {
            config[activeCat] = getDataFromUI();
            activeCat = cat;
            renderTabs();
            render();
        }

        function render() {
            const cat = categories.find(c => c.key === activeCat);
            const data = config[activeCat] || {};
            let html = '';
            if (cat.type === 'year_mint') {
                html += '<table><thead><tr><th>Название</th><th>Год</th><th>Чеканка</th><th class="center">Акт.</th><th></th></tr></thead><tbody>';
                for (const [name, years] of Object.entries(data)) {
                    for (const [year, mint] of Object.entries(years)) {
                        const active = mint !== null && mint !== undefined;
                        html += '<tr class="' + (active ? '' : 'inactive') + '">' +
                            '<td><input value="' + esc(name) + '"></td>' +
                            '<td><input value="' + esc(year) + '"></td>' +
                            '<td><input class="value-input" value="' + (active ? esc(mint) : '') + '" ' + (active ? '' : 'disabled') + '></td>' +
                            '<td class="center"><input type="checkbox" ' + (active ? 'checked' : '') + ' onchange="toggleActive(this)"></td>' +
                            '<td><button class="danger" onclick="deleteRow(this)">×</button></td>' +
                            '</tr>';
                    }
                }
                html += '</tbody></table>';
            } else {
                html += '<table><thead><tr><th>Название</th><th>Год / Значение</th><th class="center">Акт.</th><th></th></tr></thead><tbody>';
                for (const [name, value] of Object.entries(data)) {
                    const active = value !== null && value !== undefined;
                    html += '<tr class="' + (active ? '' : 'inactive') + '">' +
                        '<td><input value="' + esc(name) + '"></td>' +
                        '<td><input class="value-input" value="' + (active ? esc(value) : '') + '" ' + (active ? '' : 'disabled') + '></td>' +
                        '<td class="center"><input type="checkbox" ' + (active ? 'checked' : '') + ' onchange="toggleActive(this)"></td>' +
                        '<td><button class="danger" onclick="deleteRow(this)">×</button></td>' +
                        '</tr>';
                }
                html += '</tbody></table>';
            }
            document.getElementById('editor').innerHTML = html;
        }

        function toggleActive(chk) {
            const row = chk.closest('tr');
            row.classList.toggle('inactive', !chk.checked);
            const valueInput = row.querySelector('input.value-input');
            if (valueInput) {
                valueInput.disabled = !chk.checked;
                if (chk.checked && valueInput.value === '') {
                    valueInput.value = '-';
                }
            }
        }

        function addRow() {
            config[activeCat] = getDataFromUI();
            const cat = categories.find(c => c.key === activeCat);
            if (cat.type === 'year_mint') {
                if (!config[activeCat]['']) config[activeCat][''] = {};
                config[activeCat][''][''] = '';
            } else {
                config[activeCat][''] = '';
            }
            render();
        }

        function deleteRow(btn) {
            config[activeCat] = getDataFromUI();
            const row = btn.closest('tr');
            const inputs = row.querySelectorAll('input');
            const name = inputs[0].value.trim();
            if (name && Object.prototype.hasOwnProperty.call(config[activeCat], name)) {
                delete config[activeCat][name];
            }
            render();
        }

        window.toggleActive = toggleActive;

        async function save() {
            config[activeCat] = getDataFromUI();
            try {
                const resp = await fetch('/api/config', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(config, null, 2)
                });
                const result = await resp.json();
                if (resp.ok && result.ok) {
                    setStatus('Сохранено', false);
                } else {
                    setStatus('Ошибка: ' + (result.error || 'unknown'), true);
                }
            } catch (e) {
                setStatus('Ошибка сохранения: ' + e.message, true);
            }
        }

        function setStatus(text, isError) {
            const el = document.getElementById('status');
            el.textContent = text;
            el.className = 'status ' + (isError ? 'err' : 'ok');
        }

        document.getElementById('saveBtn').onclick = save;
        document.getElementById('addRow').onclick = addRow;

        load();
    </script>
</body>
</html>
HTML
}

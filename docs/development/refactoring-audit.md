# Аудит рефакторинга проекта (2026-09-02)

> **Статус на 2026-09-05 (после завершения шагов 6-12).** Отчёт ниже —
> снимок на момент обхода; большинство находок уже закрыто на этой ветке.
> Выполнено: §3.3 `tmp/` (abe57fd); §3.5 и §4.3 (be61544); §3.6 — утечка
> battery-подписки, залипшие contact-запросы, гонка скана и dispose-гонки
> (fe53ec5, 0f8f49d); §3.6 импорт БД и дыры экспорта §3.7 (64d362d);
> §3.7 пароль в secure storage и §3.8 зависимости (b1fc778); формулировка
> AGENTS.md (606e94f); §5.4 переносы тестов из корня (2bfadf5) и harness
> `pumpDialog` (4ca67ae); дубль upload-цикла (ea81281); дубли протокола и
> мёртвый парсер (7f7edb4); §3.10 и §5.5 — обновление доков, пометка
> upstream-MQTT разделов (f33a782); все 12 шагов плана из §5.1, включая
> шаг 6 (e19e418), шаг 11 (23438ea) и шаг 12 / этап 5 (b7679a7), плюс
> фасады entity-диалогов (b0d448a) и lifecycle трекинга (b3b3d17) —
> `map_screen.dart` сокращён 3261 → 2093 строк (актуальный чек-лист —
> в `docs/development/map-screen-refactoring.md`, этап 6).
>
> Открытыми остаются: §3.9 гигиена манифеста (требует ручной проверки на
> устройстве) и фазное разбиение сервисов из §5.2.

Подробный обход репозитория с целью найти точки рефакторинга: кандидатов на
разбиение больших файлов, проблемы тестового набора, вопросы структуры
каталогов и общей гигиены. Каждая находка отнесена к одной из категорий:
**стоит поправить** (с планом и оценкой риска), **мелкий мусор** (можно
поправить в любой момент, низкой ценности), **оставить как есть**.

## 1. Методика и базовое состояние

- Тулчейн: репозиторный `.toolchain/`, Flutter 3.47.1 stable, Dart SDK ^3.13.
- Точка отсчёта: коммит `8d9f32e`, рабочее дерево чистое (кроме локального
  `tmp/`).
- Базовая верификация перед аудитом:
  - `dart format --output=none --set-exit-if-changed lib test` — 0 изменений;
  - `flutter analyze` — 0 ошибок и предупреждений, 12 существующих
    info-замечаний (список в §4.3);
  - `flutter test` — 382 теста, все проходят.
- Объём: 112 dart-файлов в `lib/`, 65 в `test/`.
- Метод: ручной обход плюс пять параллельных субагентов — god-file карты,
  крупные сервисы, UI-слой и каталоги, тестовый набор, гигиена репозитория.

### Крупнейшие файлы (физические строки, без сгенерированных `lib/l10n/generated/*`)

| Файл | Строк |
| --- | --- |
| `lib/screens/map_screen.dart` | 3261 |
| `lib/services/lora_companion_service.dart` | 2011 |
| `lib/screens/analytics_screen.dart` | 1735 |
| `lib/services/location_service.dart` | 1708 |
| `lib/services/meshcore_protocol.dart` | 1282 |
| `lib/services/settings_service.dart` | 1054 |
| `lib/screens/repeater_health_screen.dart` | 969 |
| `lib/services/database_service.dart` | 970 |
| `lib/screens/settings/settings_page.dart` (part) | 947 |

Примечание: `map_screen.dart` — уже результат рефакторинга: по
`docs/development/map-screen-refactoring.md` он был сокращён с ~5750 строк
(этапы 1–4 плана закрыты). Оставшиеся точки роста описаны ниже.

## 2. Резюме: главное

Кодовая база в хорошем рабочем состоянии (формат чистый, 382 теста зелёные,
0 ошибок анализатора), архитектурные границы AGENTS.md в основном соблюдаются,
и большой рефакторинг map screen уже наполовину сделан по существующему
плану. Главные находки аудита:

1. **Реальные дефекты, а не только стиль** (§3.6): утечка BLE-подписки
   батареи, залипший набор ожидающих contact-запросов, гонка таймера скана,
   dispose-гонки в трёх сервисах, неатомарный построчный импорт в БД. Все
   чинится точечно с низким риском.
2. **Безопасность** (§3.7): пароль Carpeater хранится в plaintext и уходит в
   JSON-экспорт настроек — нарушение собственной конвенции AGENTS.md; плюс
   дыры в составе экспорта.
3. **God-file'ы** (§5.1, §5.2): `map_screen.dart` (3261 + part-файл настроек
   на 947 строк — незакрытый этап 5 плана), `LoRaCompanionService` (2011),
   `LocationService` (1708) — для каждого есть поэтапный план разбиения с
   оценкой риска; `analytics_screen`/`repeater_health` дублируют друг друга.
4. **Тесты** (§5.4): 22 из 65 тестов лежат в корне `test/` в обход
   конвенции (переносятся почти бесплатно — правки в 5 файлах); совсем не
   покрыты `location_service`, `database_service`, большая часть
   `lora_companion_service`; в крупных тестах — дублируемые setUp и каркасы,
   просящиеся в хелперы.
5. **Гигиена** (§3.8–§3.10, §5.5): три неиспользуемые зависимости,
   устаревший гайд про удалённый MQTT, легаси-разрешения манифеста,
   `tmp/` вне `.gitignore` (закрыто в этом аудите).
6. **Реструктуризация каталогов**: глобально **не нужна** — раскладка lib/
   соответствует AGENTS.md, плоские экраны переносить в подкаталоги не стоит;
   реальные нарушения точечны (§3.5: два UI-виджета в `lib/utils/`).

Порядок рекомендуемых работ по соотношению выигрыш/риск: §3.6 → §3.7 →
переносы тестов (§5.4) → §3.5/§3.8 → этапы плана из §5.1 (1–9, затем 12) →
фазное разбиение сервисов (§5.2) → доки/манифест (§3.9, §3.10). Каждый шаг —
отдельный коммит с полной верификацией.

## 3. Стоит поправить

### 3.1. Завершить этап 5 плана map screen: убрать `part`-связку настроек

- `lib/screens/settings/settings_page.dart` (947 строк) объявлен как
  `part of '../map_screen.dart'` (`lib/screens/map_screen.dart:115`), то есть
  страницы настроек — это методы-расширения (`extension _SettingsPageNavigation
  on _MapScreenState`, `settings_page.dart:39`) приватного State-класса.
  Это единственная оставшаяся `part`-связка в `lib/` и прямо названный
  незакрытый пункт этапа 5 в `docs/development/map-screen-refactoring.md`
  (строки 129–135).
- Extension напрямую читает/пишет ~40 приватных полей State
  (`settings_page.dart:195–631`), поэтому шаг «высокого» риска — делать его
  последним, после дешёвых извлечений из плана §5.1.
- Следствие: настройки нельзя тестировать и переиспользовать отдельно от
  экрана карты; плюс ~10 полей State живут только ради этого part-файла.
- План: шаг 12 из §5.1 — неизменяемый `MapUiSnapshot` (расширение
  `MapSettingsSnapshot`) + `MapUiActions`, страница настроек становится
  обычным виджетом; тесты `test/settings/` обновляются вместе с ним.
- Риск: высокий (широкая поверхность State-класса), выигрыш: −947 строк из
  связки и развязка фичи настроек; сам `map_screen.dart` худеет ещё на ~120
  строк импортов/`_loadSettings`.

### 3.2. Тесты в корне `test/` нарушают конвенцию каталогов

AGENTS.md требует размещать тесты в подкаталоге по префиксу имени
(например `test/bluetooth/`), общие хелперы — в `test/helpers/`. В корне
`test/` лежит 22 файла из 65 тестов, при том что 17 тестов уже разложены по
подкаталогам. Полная таблица переносов «файл → целевой подкаталог» — в §5.4.

Проверено: у большинства переносимых тестов package-импорты, поэтому реальные
правки при переносе нужны только в 5 файлах — 4 пути к
`helpers/l10n_harness.dart` (`appearance_dialogs_test.dart:6`,
`connection_dialogs_test.dart:5`, `marker_dialogs_test.dart:6`,
`tracking_play_button_test.dart:6`) и 1 путь к `../tool/version.dart`
(`version_tool_test.dart:3`). Отдельно: `snr_quarter_db_test.dart`
целенаправленно переносится в новый `test/snr/`, а **не** в защищённый
`test/meshcore/` (добавление файла туда требует отдельного одобрения).

### 3.3. `tmp/` не покрыт `.gitignore`

В корне репозитория есть незакоммиченный `tmp/` (`analyze_export.ps1`,
`analyze_export2.ps1`, `meshcore_export_20260825_203017.csv`) — локальные
скрипты анализа и выгрузка данных. `.gitignore` их не игнорирует, их можно
случайно закоммитить. Правка добавлена в этом аудите (строка `/tmp/` в
`.gitignore`, проверено `git check-ignore`); удаление содержимого — на
усмотрение владельца (см. §7).

### 3.4. Зависимости: отмеченные ограничения и discontinued-пакет

- Пины версий в `pubspec.yaml` (flutter_map 7, geolocator 13,
  permission_handler 11 и др.) снабжены комментариями-причинами — это
  осознанные ограничения, не долг (хорошо).
- `dio_cache_interceptor_file_store` официально discontinued (заменён на
  `http_cache_file_store`) — миграция возможна только вместе с обновлением
  стека flutter_map/dio; отдельно не трогать, зафиксировать как задачу
  «на потом» в связке с переездом на flutter_map 8.

### 3.5. Виджеты в `lib/utils/` — нарушение собственной конвенции

AGENTS.md: «utils — reusable helpers without UI responsibilities». Из 15
файлов два содержат полноценные виджеты:

- `lib/utils/ping_distance_options.dart:33-59` — `PingDistanceDropdown`;
- `lib/utils/discovery_timeout_options.dart:23-59` — `DiscoveryTimeoutDropdown`.

Используются только из UI (`map_quick_settings_panel.dart:4-5`,
`discovery_section.dart:6`). Решение: перенести только классы-дропдауны в
`lib/widgets/`, опции-классы (`presets`, `labelFor`, `menuItems`) оставить в
utils; обновить 2 импорта в `lib/` и 2 в `test/`. Риск: минимальный.

### 3.6. Реальные дефекты в сервисах: утечки, гонки, teardown

Найдены при чтении кода (детали и точные строки — §5.2); каждый пункт —
небольшая точечная правка с низким риском:

- **Утечка BLE-подписки батареи**: `lora_companion_service.dart:700` —
  `listen()` не сохраняется и не отменяется; каждое переподключение BLE
  добавляет «вечную» подписку и дубли событий.
- **Залипший `_pendingContactRequests`**: при неответе устройства ключ
  остаётся навсегда (`:339`, `:1329`, удаление только в `:1448`) — повторные
  запросы контакта блокируются до перезапуска приложения; на disconnect
  не чистится.
- **Гонка таймера `scanForRepeaters`** (`lora_companion_service.dart:897-906`):
  старый таймер может завершить новый completer частичными данными.
- **dispose-гонки**: `lora_companion_service.dart:2004-2009` (add в закрытые
  контроллеры, `_failPendingPings` не вызывается), `location_service.dart:1688-1700`
  (9 контроллеров закрываются после незawaitленного `stopTracking`),
  `carpeater_service.dart:505-510` (цикл обнаружения может писать в закрытые
  контроллеры).
- **Медленный неатомарный импорт БД**: `database_service.dart:563-594` —
  SELECT+INSERT на каждую строку без транзакции, хотя batch-механизм уже
  есть (`insertSamples`, `:323-334`).

### 3.7. Пароль Carpeater хранится в открытом виде и уезжает в экспорт

- `settings_service.dart:66, 681-693` — пароль ретранслятора лежит в
  SharedPreferences (plaintext) и включён в `_exportKeys` (`:965`) — то есть
  попадает в JSON-файл экспорта настроек. Это прямое нарушение конвенции
  AGENTS.md («Store runtime credentials with the existing secure-storage
  abstraction»).
- Решение: перенести в secure storage с миграцией существующего значения
  (read-old → write-secure → remove-old, иначе пользователи потеряют пароль
  при обновлении); из экспорта убрать, при импорте старых файлов —
  игнорировать ключ.
- Заодно: в `_exportKeys` (`:921-986`) отсутствуют ключи
  `_deadZoneAlertsKey` (`:78`) и `_newRepeaterAlertsKey` (`:79`) —
  переключатели теряются при export/import; чужие ключи
  `'upload_api_url'` и др. (`:978-981`) продублированы строковыми
  литералами вместо констант из `upload_service.dart:26-32`.
- Риск: средний (миграция значения), выигрыш: безопасность + целостность
  экспорта.

### 3.8. Неиспользуемые зависимости и устаревшая формулировка AGENTS.md

Проверено grep-ом dart-импортов по всему репозиторию — три зависимости без
единого использования:

- `flutter_secure_storage` (`pubspec.yaml:67`);
- `pointycastle` (`pubspec.yaml:69`);
- `cupertino_icons` (`pubspec.yaml:32`; ни одного `CupertinoIcons`).

При этом `AGENTS.md:100-101` ссылается на «existing secure-storage
abstraction», которой в коде нет (креды хранятся в `shared_preferences`
через `SettingsService`, см. §3.7). Решение: удалить три зависимости
(с прогоном `flutter pub get` / `analyze` / `test`), поправить формулировку
в AGENTS.md — а по §3.7 появление secure-storage станет реальностью.

### 3.9. Гигиена AndroidManifest.xml (требует ручной проверки на устройстве)

- `AndroidManifest.xml:25-26` — легаси `WRITE/READ_EXTERNAL_STORAGE` без
  `maxSdkVersion`: на современных targetSdk это no-op (SAF/MediaStore через
  file_picker/saver_gallery). Кандидат на удаление.
- `AndroidManifest.xml:29-30` — старые `BLUETOOTH`/`BLUETOOTH_ADMIN` без
  `android:maxSdkVersion="30"` (рекомендация flutter_blue_plus).
- `AndroidManifest.xml:35` — `uses-feature android.hardware.usb.host` без
  `required="false"`: устройства без USB-хоста (но рабочие по BLE)
  отфильтровываются при установке — для приложения с dual-транспортом это
  реальное сужение аудитории.
- Вопрос для ручной проверки: на Android 13+ для Wi-Fi-скана формально нужен
  `NEARBY_WIFI_DEVICES`; в манифесте его нет, `WifiLocationService`/beaconDB
  (`wifi_location_service.dart:176`, `MainActivity.kt:147-189`) может
  получать пустые результаты на API 33+. По AGENTS.md это случай «describe
  manual device testing» — проверить с устройством до любых правок.

### 3.10. Устаревший гайд `docs/guides/lora-companion.md`

Разделы «Customization» (строки 115-153) описывают удалённую
MQTT-функциональность: `defaultMqttBroker` (`:119-126`), топик-паттерн и
`ping $pingId` (`:130-140`), «`location_service.dart:71`:
`distanceFilter: 5`» (`:148-151`) — ничего из этого в коде нет (MQTT удалён:
`lora_companion_service.dart:870`, no-op `disconnectMqtt` `:1907-1908`).
Переписать раздел под реальный код (discovery/ping через `MeshCoreProtocol`)
или явно пометить документ как описание апстрима с удалением неверных
номеров строк.

## 4. Мелкий мусор

### 4.1. Одинаковые базовые имена файлов

`lib/utils/compass_calibration.dart` (чистая политика калибровки, 112 строк)
и `lib/widgets/compass_calibration.dart` (баннер/шит, 323 строки) —
размещение обоих корректно, но одинаковые базовые имена провоцируют неверные
импорты (виджет уже импортирует utils: `widgets/compass_calibration.dart:8`).
Предложение: переименовать виджет-файл в `compass_calibration_sheet.dart`
(тест уже называется `compass_calibration_sheet_test.dart`). Косметика.

### 4.2. Каталог `lib/constants/` ради одного файла

`lib/constants/app_version.dart` — 2 строки, константа синхронизируется
`tool/version.dart`. Допустимо, но каталог на один файл — пограничный случай;
можно оставить как есть.

### 4.3. Существующие info-замечания анализатора (12 штук)

Все легко устранимы, поведение не меняют:

| Локация | Линт |
| --- | --- |
| `lib/main.dart:29` | `library_private_types_in_public_api` |
| `lib/screens/map/map_screen_controller.dart:59` | `prefer_initializing_formals` |
| `lib/screens/map/map_settings_controller.dart:118` | `prefer_initializing_formals` |
| `lib/screens/map/map_settings_controller.dart:153` | `prefer_initializing_formals` |
| `lib/screens/map/map_settings_controller.dart:154` | `prefer_initializing_formals` |
| `lib/services/location_quality_filter.dart:14` | `prefer_initializing_formals` |
| `lib/screens/repeater_health_screen.dart:748` | `unnecessary_underscores` |
| `lib/services/sound_service.dart:8` | `constant_identifier_names` (`TONE_PROP_BEEP`) |
| `lib/services/sound_service.dart:9` | `constant_identifier_names` (`TONE_PROP_ACK`) |
| `lib/services/sound_service.dart:10` | `constant_identifier_names` (`TONE_PROP_NACK`) |
| `lib/services/sound_service.dart:11` | `constant_identifier_names` (`TONE_CDMA_ABBR_ALERT`) |
| `lib/services/sound_service.dart:12` | `constant_identifier_names` (`TONE_CDMA_MED_L`) |

Проверено дополнительно:

- Звуковые константы используются только внутри
  `lib/services/sound_service.dart` и один раз в
  `test/sound/sound_service_test.dart:47`; платформенный
  `android/.../MainActivity.kt:57` берёт `ToneGenerator.TONE_PROP_BEEP`
  из Android SDK и от имён в Dart не зависит. Переименование в
  lowerCamelCase (`tonePropBeep`, …) затрагивает 2 файла и безопасно;
  имена сейчас зеркалируют константы `ToneGenerator` — при переименовании
  стоит сохранить эту связь в doc-комментарии.
- `lib/main.dart:29` — `static _MyAppState? of(...)` в публичном `MyApp`
  возвращает приватный State (4 вызова из `lib/screens/map_screen.dart`).
  Классическое лечение — сделать State-класс публичным
  (`class MyAppState extends State<MyApp>`), поведение не меняется.

### 4.4. Сервисный мелкий мусор (сводка; детали в §5.2)

- Мёртвый код: `parseRawLogFrame` (~110 строк,
  `meshcore_protocol.dart:751-860`) без единого вызова; `getMostRecentSample`
  (`database_service.dart:450-460`) без вызывающих; deprecated-обёртка
  `uploadNewSamples` (`upload_service.dart:239-243`); no-op `disconnectMqtt`
  (`lora_companion_service.dart:1907-1908`).
- Копипаста-комментарий «Standard baud rate for **Meshtastic**»
  (`lora_companion_service.dart:815`) — проект про MeshCore.
- Режим пинга строковыми литералами `'distance'/'time'/'both'`
  (`location_service.dart:112-114`, те же литералы в
  `settings_service.dart:613-621`) — просится enum.
- Несоответствие имени и логики: достижение `smolensk_legend`
  (`achievement_service.dart:52`) проверяет префиксы `'ya_', 'yakut', 'якут'`
  (`:57`).
- Зашитый URL устаревшего домена в миграции v5
  (`database_service.dart:210-216`) — не трогать, пометить как исторический.
- Прочее: дубли `_startingPing = false` в try и finally
  (`lora_companion_service.dart:1098`, `:1171`); магия 3000/1200 mV батареи
  без профиля (`:1521-1524`); `{s}` тайл-субдомен всегда `'a'`
  (`tile_download_service.dart:72`); `flush: true` на каждую строку лога
  (`persistent_debug_logger.dart:93-97`) — осознанный трейдофф;
  `dispose()` синглтона `debug_log_service.dart:61-63` навсегда закрывает
  контроллер (никем не вызывается).

## 5. Детальные находки субагентов

### 5.1. `lib/screens/map_screen.dart` — god-file (3261 строка)

Файл — уже результат рефакторинга (5750 → 3261 строк по плану
`docs/development/map-screen-refactoring.md`, этапы 1–4 закрыты). Весь файл
после строки 115 — один State-класс `_MapScreenState`
(`map_screen.dart:124`); вместе с part-файлом настроек (947 строк) god-модуль
составляет ~4200 строк. Публичная поверхность минимальна: `MapScreen`
импортируется только из `lib/main.dart:7`, тесты сам экран не импортируют —
это делает дальнейшую резку безопасной по контрактам.

Ключевые блоки внутри State (диапазоны строк `map_screen.dart`):

| Строки | Блок |
| --- | --- |
| 124–319 | Поля: 9 сервисов, контроллеры, ~45 display-флагов настроек |
| 334–637 | `_initialize`: 16 stream-подписок, загрузки, алерты (304 строки) |
| 639–692 | `_loadSettings`: ручная раскладка 44 полей снапшота по State |
| 694–807 | Компас: подписка, калибровка, сглаживание heading (таймер 80 мс) |
| 1025–1135 | Разрешения Android (location/precise/always/battery/wifi-throttling) |
| 1137–1501 | Ввод-вывод: экспорт/импорт данных, настроек, БД (365 строк) |
| 1503–1701 | Маркеры, privacy/impossible зоны, delete mode |
| 1770–1824 | Проверка обновлений (HTTP к GitHub API) |
| 1873–1942 | Скриншоты (дублируется с `_shareCoverageMap` 3044–3113) |
| 1955–2295 | `build` + `_buildMap`: панели по 13–16 параметров, стек ~14 слоёв |
| 2313–2417 | `_manualPing`: пинг, звуки, конструирование и вставка Sample в БД |
| 2419–2624 | Подключение USB/BLE, контакты, сканирование ретрансляторов |
| 2664–2756 | Тема/язык: 7 методов через `MyApp.of(context)` |
| 2789–2897 | Инфо-диалоги sample/cluster/repeater/coverage |
| 2899–3240 | Upload, offline-тайлы, share coverage, фильтры, community coverage |

Оценка уже сделанного разбиения: `map_screen_controller.dart` (365 строк,
`MapDataStore` + fingerprint-кэш + LOD, покрыт тестом) — образец; 
`map_settings_controller.dart` (221 строка) хорош, но снапшот всё равно
вручную раскладывается по 45 полям State (`_loadSettings`, 639–692);
`map_runtime_bindings.dart` владеет подписками/таймерами, но сами подписки
описаны инлайн в `_initialize`; layers/dialogs/widgets вынесены чисто.
Итог: UI-«листья» вынесены (~30% по строкам), но подготовлено ~70%
архитектурных швов — оставшиеся извлечения дешёвые.

План дальнейшего разбиения (каждый шаг = отдельный коммит + полная
верификация; новые файлы — в существующие подкаталоги `lib/screens/map/`,
без новых архитектурных слоёв — по AGENTS.md):

| # | Шаг | Новый файл | Диапазон | Выигрыш | Риск |
| --- | --- | --- | --- | --- | --- |
| 1 | Проверка обновлений (`_checkForUpdates`, `_openGitHub`) | `map/dialogs/update_flow.dart` | 1770–1824 | ~55 | низкий |
| 2 | Экспорт/импорт данных, настроек, БД (`MapDataIo`) | `map/data_io.dart` | 1137–1501 | ~365 | низкий-средний |
| 3 | Маркеры, зоны, delete mode (`MapAnnotationsController`) | `map/map_annotations_controller.dart` | 1503–1701 | ~165 | низкий |
| 4 | Permission-преамбула трекинга | `map/tracking_permissions.dart` | 1025–1135 | ~110 | низкий |
| 5 | Подключение USB/BLE, контакты (`ConnectionFlow`) | `map/connection_flow.dart` | 2419–2624 | ~180 | средний |
| 6 | Скриншоты + дедупликация двух потоков | `map/screenshot_flow.dart` | 1873–1942, 3044–3113 | ~140 | средний |
| 7 | Upload / community-coverage потоки | `map/dialogs/upload_flows.dart` | 2899–2983, 3181–3240 | ~145 | низкий |
| 8 | Тема/язык + ducting-хелперы | `map/map_theme_helpers.dart` + utils | 2558–2582, 2664–2756 | ~120 | низкий |
| 9 | `_initialize` → биндеры `bindRadio/bindLocation/bindAlerts/bindTelemetry` | дополнить `map_runtime_bindings.dart` | 334–637 | ~250 из State | средний |
| 10 | Вставку Sample из `_manualPing` — в сервис | `services/manual_ping_service.dart` | 2313–2417 | ~70 | средний |
| 11 | `MapLayerStack` + viewState вместо 13–16 параметров панелей | `map/widgets/map_layer_stack.dart` | 1955–2295 | −200 котла | средний |
| 12 | Отклеить `settings_page.dart` от State (см. §3.1) | `MapUiSnapshot` + `MapUiActions` | part целиком | −947 | высокий |

Эффект: шаги 1–9 сокращают `map_screen.dart` до ~1800–1900 строк, после
шага 12 — до ~1300–1500 строк (композитор, в пределах цели существующего
плана «600–900» + запас на специфику экрана). Общие правила для всех шагов:
не менять поведение `if (!mounted) return`; таймеры/подписки — только через
`MapRuntimeBindings`; сохранять точные l10n-строки и тайминги (300 мс
скриншот, 80 мс heading, 2 с pingPulse).

Мелкий мусор в `map_screen.dart` (path — `lib/screens/map_screen.dart`):

- Поля State, живущие только ради part-файла настроек: `_ignoredRepeaterPrefix`
  (183, запись 657; в сервис применяется независимо через
  `map_settings_controller.dart:142–144`), `_fuelUnit` (215/664),
  `_pingTimeInterval` (283/674), `_keepScreenOn` (232/678),
  `_batterySaverEnabled` (300/686), alert-флаги (306–308/683–685),
  `_soundEnabled`/`_vibrationEnabled` (278–279/675–676) — единственный
  читатель `settings_page.dart:195–631`.
- Бессмысленный `setState` вокруг мутации контроллера:
  `setState(() => _mapDataController.replaceRepeaters(...))` — 2612.
- `void ... async` (async без Future, глушит unawaited-ошибки):
  1554, 1672, 1686, 2419, 3115, 3161.
- Дубли URL тайлов OSM/Carto: 2136–2137 и 3003–3005 — вынести в константу
  (рядом с `lib/utils/initial_map_camera.dart`).
- Дубли скриншот-последовательности (скрытие UI + задержка 300 мс +
  `capture(pixelRatio: 2.0)`): 1876–1886 и 3047–3054.
- Дубли расчёта success-rate: 851–855 и 3069–3079 — один хелпер.
- Магические числа: zoom 15.0 — 2837, 2893, 3178; 300 мс — 1881, 3050;
  порог heading 0.25° — 798; `Duration(minutes: 2)` протухания радио-позиции
  в двух независимых местах — 384 и 2302–2303.
- Сиротский комментарий от удалённого поля — 125; пустой колбэк прогресса
  с комментарием-заглушкой — 3205–3207.
- Не относящийся к карте код в `_initialize`: проверка обновлений и
  achievement-check (562–577, 1770).

### 5.2. Сервисы (25 файлов, ~10,6 тыс. строк)

Границы из AGENTS.md в целом соблюдены: протокол не зависит от виджетов,
экраны не занимаются фреймингом. Главные проблемы — god-объекты
`LoRaCompanionService` и `LocationService`, несколько реальных
утечек/гонок (см. §3.6), plaintext-пароль (см. §3.7) и медленный импорт в БД.

**`lora_companion_service.dart` (2011 строк).** Ответственностей 7+:
BLE-транспорт (637-768), USB-транспорт (797-867), BLE-скан для UI (498-591),
авто-reconnect с backoff (1772-1905), диспетчер кадров (1176-1287),
ping/discovery-сессии, книга повторителей-контактов + алерты (342-366,
1290-1514), батарея, мост Carpeater (1916-2000). План разбиения фазами:
- Фаза A (низкий риск): `RepeaterDirectory` (6 коллекций + обработчики
  контактов), `BatteryMonitor` (таймер 1642-1669 + BLE-char), carpeater-команды
  → в `CarpeaterService` (у него уже есть свой `_protocol`,
  `carpeater_service.dart:30`).
- Фаза B (средний): транспорт — интерфейс `RadioTransport` + BLE/USB
  реализации; осторожно: порядок MTU→notify→battery и `_serializeConnect`
  (:600-622) хрупкий. Не совмещать с другими правками.
- Фаза C (средний): `PingSessionManager` (tracker + `_pendingPings`/таймеры).
- Итог: 2011 → 4 файла по 400-600 строк, тестируемость без железа.
- Длинные методы: `ping` :1034-1173 (~140), `_connectBluetoothDevice`
  :637-768 (~132), `watchBluetoothScan` :498-591 (~94). Дубли
  connect/disconnect-хвостов BLE (:741-757) и USB (:846-858) → общий
  `_finishConnection`/`_handleLinkLost` (−70 строк). Незафиксированная
  зависимость: `SettingsService()` создаётся ad-hoc в `:993` и `:999` —
  принимать в конструктор.

**`location_service.dart` (1708 строк).** Ответственностей 12+ (GPS-стрим +
watchdog, Wi-Fi позиционирование, auto-ping time/distance, исполнение пинга,
battery-saver, dead-zone, ducting, Carpeater-оркестрация, foreground-сервис,
сессии, wakelock/sound/widget, CRUD pass-through). Ключевое:
- `_handleNewPosition` (:980-1201) — 222 строки и `void … async`: события
  позиций обрабатываются fire-and-forget, порядок не гарантирован. Разбить на
  qualityGate → fusedSourceSwitch → pingDecision → recordSample (риск
  средний — сначала покрыть тестами).
- Async-void по файлу: `:922`, `:1279`, `:1303`, `:1575`.
- 2-4 запроса БД/prefs на каждый GPS-фикс (~5 с): зоны `:1008`, precision
  `:1282`, dead-zone `:1290`, ducting `:1174` → кэшировать в памяти с
  инвалидацией.
- Дубли триггеров пинга (:949-967 и :1118-1143) → `_maybeTriggerPing`.
- `startTracking` 159 строк (:664-822) с частичным откатом при ошибке.
- Владение сервисами: `map_screen.dart:127` создаёт `LocationService()`,
  который сам создаёт `LoRaCompanionService()` (:37) — единственность держится
  на соглашении; минимальное лечение — factory с кэшем инстанса или создание
  в `main` и проброс.
- План разбиения: `PositionStreamManager` (477-634, целиком — паттерн
  поколений корректен), `AutoPingScheduler`, carpeater-оркестрация →
  `CarpeaterService`, `NotificationPresenter`.

**`meshcore_protocol.dart` (1282 строки) — особые риски.** Это контракт
радио-обмена: layout-версия задаёт формат ответов прошивки (:12-18), форма
`Map<String,dynamic>` де-факто API и зафиксирована в защищённых тестах.
- Разрешено и безопасно (механика без поведения): 11 повторов
  `if (x > 127) x -= 256` → `_readInt8` (:760, :765, :815, :870, :872, :891,
  :924, :980, :985, :1035, :1262); 5 инлайновых LE-чтений → существующий
  `_readUint32LE` (:616). −40 строк; обязательно прогонять защищённые тесты
  (запуск разрешён) и проверять с реальным радио.
- Не делать сейчас: типизация результатов (правки API + защищённых тестов),
  смена `codeUnits` на utf8 для пароля/команд (:1104, :1127) — изменит байты
  логина «в эфире» (если чинить не-ASCII — только валидация с явной ошибкой).
- Не трогать: resync-логику `parseIncomingData` (:253-311, корректная), BLE
  допущение «1 notification = 1 кадр» (:240-251, известное ограничение),
  канальные методы без вызывающих в lib/ — они покрыты защищёнными
  контракт-тестами, это сознательная «библиотека протокола».

**`settings_service.dart` (1054 строки).** Границы соблюдает;
`await SharedPreferences.getInstance()` ~120 раз → кэширующий геттер
(−~100 строк, механически). Безопасность и экспорт — см. §3.7. Деление на
доменные классы не рекомендуется (AGENTS.md: слой ради одного use case).

**`database_service.dart` (970 строк).** Импорт — см. §3.6. Плюс: дубли
гаверсинуса приват-зон (:895-906 и :909-925) → один хелпер; `database`-геттер
без мемоизации Future (:31-35); `getSessionSampleCounts` (:627-653) — три
COUNT → один с `SUM(CASE…)`. `_onUpgrade` (:172-310) длинный, но это нормальная
хронология миграций.

**`carpeater_service.dart` (511 строк).** Три одинаковых retry-скелета
(:375-462) → хелпер `_awaitAck`; общий `_sentCompleter` (:57) для разных
команд — запоздалый ack может confirm-нуть не ту команду (маловероятно,
цикл последовательный — как минимум комментарий); dispose (:505-510) может
закрыть контроллеры, пока летит `_runDiscoveryCycle`.

**`upload_service.dart` (638 строк).** Вербальный дубликат ~60 строк
(батч+retry: `:151-216` ↔ `:531-596`) → делегирование;
`uploadNewSamples` (:239-243) — deprecated-обёртка без вызывающих → удалить.

**Сквозное дублирование между сервисами:** ignored-prefix матчинг
(`location_service.dart:1596-1610` ≈ `lora_companion_service.dart:435-445`);
ducting-risk «получить+unknown→null» ×3; префикс pubkey
`substring(0,8).toUpperCase()` вручную дублируют lora (:1297, :1326, :1381) и
location (:1589-1592, :1639-1641), хотя канонизирован в
`AggregationService.repeaterLookupKey` (`aggregation_service.dart:16-21`);
`achievement_service.dart:127` хардкодит geohash-прецизию 6 мимо
`GeohashUtils.coverageKey` — при смене дефолта (:260) достижения разъедутся
с картой.

**Оставить как есть:** `aggregation_service.dart` (чистые статические
функции; `buildIndexes` ~195 строк — связный алгоритм весов, не дробить);
`map_lod_service`, `radio_position_estimator`, `location_quality_filter`,
`bad_fix_monitor`, `wifi_location_service`, `database_backup_service`
(образцовый restore с откатом :164-203), `sound_service`, `screen_wake_service`
и остальные мелкие — чистые, с DI/фейками; `ReconnectBackoff` +
`_serializeConnect` — тонкий, но работающий механизм; генерации стрима
позиций (`location :539-604`) — корректный паттерн против гонок.

Итоговый порядок работ по сервисам (выигрыш/риск): 1) утечка battery-подписки
+ dispose-guard'ы; 2) `_pendingContactRequests` и гонка скана; 3) пароль →
secure storage + дыры экспорта; 4) импорт БД в транзакции; 5) дедупликация
upload и connect-хвостов; 6) фазное разбиение lora/location — только после
пунктов 1-5, каждая фаза отдельным коммитом.

### 5.3. UI-слой и структура каталогов

Раскладка: `screens/` — 60 файлов (`map/` — 28, `settings/` — 20, плоско —
10 + `map_screen.dart`), `services/` — 30, `utils/` — 15, `widgets/` — 4,
`models/` — 3 (см. также §3.5 про виджеты в utils).

**Вердикты по реструктуризации каталогов:**

- Плоские экраны → подкаталоги: **не стоит**. У каждого плоского экрана
  1–2 сайта импорта (`analytics/achievements/device_comparison/debug_*` —
  только `map_screen.dart:80-94`; `session_history` — ещё и
  `test/session/session_history_hint_test.dart:3`; `repeater_health`/
  `signal_trend` — `diagnostics_section.dart:5-6`; `ducting_forecast` —
  `location_section.dart:6`). Перенос создаст 9 подкаталогов по одному
  файлу — против духа AGENTS.md. Исключение: `lib/screens/analytics/`
  возникнет естественно, если резать `analytics_screen.dart` (ниже).
- `lib/models/models.dart` (баррел на 6 типов: `Sample`, `Coverage`,
  `Repeater`, `Edge`, `WSession`, `NodeData`): делить **можно, но низкий
  приоритет** — 31 импорт через баррел не сломается, типы маленькие и
  связные.
- `lib/widgets/`: все 4 файла на своих местах; экранно-локальные виджеты
  корректно лежат в `screens/*/widgets/`.

**Крупные экраны:**

- `lib/screens/analytics_screen.dart` (1735 строк) = shell (33-89) + 5
  самодостаточных табов: `_CoverageScoreTab` (95-304), `_TimeOfDayTab`
  (310-551), `_CoverageGoalTab` (557-990), `_CoverageComparisonTab`
  (996-1408), `_RepeaterReliabilityTab` (1414-1735). Чистые расчёты
  (score 106-183, goal 777-874, session diff 1028-1122, repeater stats
  1644-1712) можно вынести в тестируемый модуль; полный вариант —
  `lib/screens/analytics/` с файлом на таб.
- `lib/screens/repeater_health_screen.dart` (969 строк): почти полностью
  дублирует repeater-статистику analytics с уже разъехавшимися порогами
  тренда (analytics 7d/prev-7d ±0.1, `analytics_screen.dart:1690-1694` vs
  health 7d/30d −0.15, `repeater_health_screen.dart:249-254` — вероятно,
  намеренно; сохранить как параметры). `_RepeaterDetailScreen` (448-931,
  ~484 строки) — кандидат на собственный файл.
- `lib/screens/settings/settings_page.dart`: `sections/` использован полно
  (13 секций вынесены), но внутри остались `_buildSettingsCategories`
  (103-591, ~489 строк, 13 категорий в одном методе — режется на 5
  групп-методов по `_SettingsOverviewGroupId`, enum на строке 8),
  `_setMapDisplaySetting` (649-728, два параллельных switch на 16 значений —
  сворачивается в таблицу) и близнецы-подтверждения 846-918. part-связка —
  см. §3.1.

**Главные дубли UI-кода:**

| Что | Где |
| --- | --- |
| `_miniStat` байт-в-байт ×3 | `analytics_screen.dart:1630-1642`, `repeater_health_screen.dart:403-419`, `device_comparison_screen.dart:445-457` |
| Группировка+статистика повторов ×2 (и два класса `_RepeaterStats`) | `analytics_screen.dart:1430-1712` ↔ `repeater_health_screen.dart:197-285`, 937-969 |
| Sort-бар с одинаковыми строковыми литералами | `analytics_screen.dart:1471-1514` ↔ `repeater_health_screen.dart:115-168` |
| Порог цвета 0.7/0.3 — 8 мест | `analytics_screen.dart:453-459, 507-513, 698-704, 1533-1540`; `repeater_health_screen.dart:306-310, 520-524, 805-809, 850-856` |
| displayId `substring(0,8).toUpperCase()` ×3 | `analytics_screen.dart:1529-1531`, `repeater_health_screen.dart:302-304, 456-458` |
| Периоды суток (0-6-12-18) ×2 | `analytics_screen.dart:357-362, 541-550` ↔ `repeater_health_screen.dart:824-837` |
| Confirm-диалог «Cancel + красная» — 8+ копий | `settings_page.dart:851-872, 888-909`, `session_history_screen.dart:82-101`, `statistics_section.dart:67-83`, `map_screen.dart:1673, 1687, 2537`, …; правильный приём уже есть в `map_workflow_dialogs.dart:20-48` |
| Константа 1609.34 (метры→мили) — 11 мест | `analytics_screen.dart:878, 892, 1204, 1207`; `session_history_screen.dart:75`; `settings_dialogs.dart:20`; `statistics_section.dart:47, 201`; `location_service.dart:243, 974`; приватная `_metersPerMile` уже есть в `achievement_service.dart:60` |

Решения: общий чистый модуль repeater-статистики (например
`lib/utils/repeater_stats.dart`) — −150…−200 строк и тестируемость без
виджетов (риск средний: сверить пороги тренда); общий
`lib/widgets/confirm_dialog.dart` (title, message, confirmLabel,
destructive) — −120…−150 строк, единый UX (риск низкий); одна публичная
константа метров в миле.

Длинные build-методы (кроме map_screen, см. §5.1):
`_buildSettingsCategories` (~489), `_TimeOfDayTab.build` (~205),
`ducting_forecast_screen.dart` build 190-374 (~185),
`_CoverageScoreTab.build` (~188), `debug_diagnostics_screen.dart` build
166-334 (~169), `session_history_screen.dart` `_buildSessionCard` (~162),
`repeater_health` State.build (~162). Дополнительно: analytics и
ducting_forecast считают агрегаты прямо в build (freshness-цикл 132-144,
группировка 326-348, goal-grid 794-807) — работа на каждом кадре таба;
вынос в чистые классы снимает и это.

Мелкий мусор UI-слоя: устаревшее дерево проекта в `README.md:90-115`
(нет `screens/map/`, `screens/settings/`, `widgets/`, `l10n/`; см. §5.5);
чужой l10n-ключ `l10n.analyticsPingsCount` в health-экране
(`repeater_health_screen.dart:756, 847`); `this.context` в
extension-методах (`settings_page.dart:603, 619` — всплывёт при съёме
part-связки); строковые литералы сортировки вместо enum
(`analytics_screen.dart:1424`, `repeater_health_screen.dart:21`);
`dynamic` в `_compRow`/`fmt` (`device_comparison_screen.dart:366-386`);
хардкод precision 6 (`repeater_health_screen.dart:262`); inline-диалог
выбора радиуса цели ~88 строк (`analytics_screen.dart:883-970`).

### 5.4. Тестовый набор

Объём: 66 dart-файлов = 65 тестов + 1 хелпер (`test/helpers/l10n_harness.dart`).
22 теста лежат в корне `test/`, 43 разложены по 17 подкаталогам.

**Приоритет 1 — переносы по конвенции** (package-импорты не меняются;
реальные правки — 5 файлов):

| Файл в корне `test/` | Целевой каталог | Правки |
| --- | --- | --- |
| `geohash_utils_test.dart` | `test/geohash/` (новый) | — |
| `internet_connectivity_service_test.dart` | `test/internet_connectivity/` (новый) | — |
| `screen_wake_service_test.dart` | `test/screen_wake/` (новый) | — |
| `heading_utils_test.dart` | `test/heading/` (новый) | — |
| `wifi_location_service_test.dart` | `test/wifi_location/` (новый) | — |
| `location_quality_filter_test.dart` | `test/location_quality/` (новый) | — |
| `discovery_timeout_options_test.dart` | `test/discovery/` (новый) | — |
| `initial_map_camera_test.dart` | `test/map/` (существующий) | — |
| `impossible_zone_test.dart` | `test/impossible_zone/` (новый) | — |
| `app_locale_test.dart` | `test/l10n/` (новый) | — |
| `bad_fix_monitor_test.dart` | `test/location_quality/` (рядом с фильтром) | — |
| `lora_reconnect_test.dart` | `test/lora/` (новый) | — |
| `sample_export_test.dart` | `test/export/` (новый) | — |
| `snr_quarter_db_test.dart` | `test/snr/` (новый); **не** в защищённый `test/meshcore/` | — |
| `repeater_contacts_test.dart` | `test/repeater/` (новый) | — |
| `android_tracking_settings_service_test.dart` | `test/tracking/` (новый) | — |
| `aggregation_service_test.dart` | `test/aggregation/` (новый) | — |
| `version_tool_test.dart` | `test/tool/` (новый) | путь `../tool/` → `../../tool/` |
| `tracking_play_button_test.dart` | `test/tracking/` | путь helpers → `../helpers/` |
| `appearance_dialogs_test.dart` | `test/map/` | путь helpers → `../helpers/` |
| `connection_dialogs_test.dart` | `test/map/` | путь helpers → `../helpers/` |
| `marker_dialogs_test.dart` | `test/map/` | путь helpers → `../helpers/` |

После переносов в корне `test/` останется только `helpers/`.

**Приоритет 2 — покрытие.** Сервисы без собственных тестов
(сопоставление по grep импортов):

| Модуль | Статус | Покрывать в первую очередь |
| --- | --- | --- |
| `location_service.dart` (1517) | 0 тестов | start/stopTracking (:664, :1432); пауза пингов по bad-fix (:343); режимы пинга time/distance (:883, :922); battery saver (:1258-1269); Wi-Fi fallback (:372, :1203); dead-zone алерты (:1279). Границы geolocator/foreground-task не изолированы фейками — требование AGENTS.md не выполняется |
| `lora_companion_service.dart` (1779) | частично | `lora_reconnect_test.dart` покрывает только чистые хелперы (:26-118). Не покрыто: state machine `ping()` (:1034), маршрутизация кадров `_handleFrame` (:1193), `_failPendingPings` (:1566), auto-reconnect (:1805), слияние контактов (:924). Ответы радио скармливаются байтами — протокол уже отделён |
| `database_service.dart` (873) | 0 тестов | миграция `_onUpgrade` (:172) — самый рискованный метод; `insertSamples` (:323); отметки выгрузки по эндпоинтам (:404, :423); round-trip export/import (:493, :513); приватные зоны (:895, :909). Фейабельно через `sqflite_common_ffi` |
| `carpeater_service.dart` (446) | 0 unit-тестов | цикл обнаружения (:313), состояние при сбоях, логин (:206) |
| `ducting_service.dart` (240) | 0 тестов | `fetchAndCache` (:61), risk-геттеры — http-граница фейабельна |
| `tile_download_service.dart`, `widget_service.dart`, `debug_log_service.dart`, `persistent_debug_logger.dart` | 0 тестов | download/cancel; сериализация данных виджета; кольцевой буфер; запись в файл |

Тонкое покрытие: `upload_service_test.dart` — 44 строки на сервис в 546
строк. Экраны без тестов: `map_screen.dart` (включая part-файл настроек),
`analytics_screen.dart`, `repeater_health_screen.dart` и ещё 6. Стратегия —
не «покрыть экраны целиком», а сначала вынести их бизнес-логику в
сервисы/контроллеры (см. §5.1, §5.3) и покрыть логику. Топ-3 по ценности:
`location_service`, `database_service`, маршрутизация ответов
`lora_companion_service`.

**Приоритет 3 — качество крупных тестов.**

- `settings_service_test.dart` (434): 16 групп, в каждой дублируется
  `setUp(() { SharedPreferences.setMockInitialValues({}); })` — 16 копий
  (например :10-12, :49-51, …, :534-536) → достаточно одного общего setUp.
  Паттерн «default → persist → входит в exportSettings» повторён для ~8 фич —
  кандидат на параметризованный хелпер в `test/helpers/`. Разбиение на файлы
  сейчас не обязательно; швы, если делить: location quality (:392-494),
  map-настройки (:91-247).
- `marker_dialogs_test.dart` (278): каркас
  Scaffold→Builder→TextButton('Open')→showDialog повторён 8 раз (:13-28 …
  :277-295) → хелпер `pumpDialog(tester, …)` в `test/helpers/`, он же
  сократит appearance/connection dialogs тесты.
- `settings_sections_test.dart` (385): локальные хелперы уже хорошие; мелкий
  риск — мутабельная глобальная `currentSettings` (:372).
- `map_screen_controller_test.dart` (367): эталон — не трогать; если
  `FakeMapDataStore`/фабрика `_sample` понадобятся другим map-тестам,
  поднять в `test/helpers/`.

**Мелкий мусор:** `wifi_location_service_test.dart` не мёртвый (сервис
существует и используется `location_service.dart:28, :45`);
`version_tool_test.dart` живой и единственный с импортом вне `test/` — не
удалять; `test/helpers/` содержит единственный файл — после переносов
корень `test/` станет чистым.

**Защищённая зона `test/meshcore/`** (наблюдения; правки не предлагались):
contract-файл — образцовый спецификационный набор (документированные
векторы :7-13, полные реестры команд/ответов :17-280, golden-фреймы
:286-382, тест ресинхронизации на каждом разрезе потока :400-432).
Между двумя файлами есть перекрытие сценариев и продублированный
`_writeUint32LE` (contract:626-631 ↔ protocol_test:465-470) — по комментарию
contract:7-8 пересечение намеренное («specification tests»), но любая смена
раскладки байт потребует синхронной правки обоих файлов. SNR-квартование
покрыто трижды (contract:550-575, protocol_test:194-205 и внешний
`snr_quarter_db_test.dart`).

### 5.5. Гигиена репозитория

**Стоит поправить:**

- `docs/guides/lora-companion.md:115-153` — разделы «Customization»
  описывают удалённую MQTT-функциональность (`defaultMqttBroker`,
  `ping $pingId`, «`location_service.dart:71`: `distanceFilter: 5`») —
  ничего из этого в коде нет; в `lora_companion_service.dart:870` —
  `// MQTT CONNECTION - REMOVED`, `:1907-1908` — no-op `disconnectMqtt()`.
  Переписать под реальный код или пометить как описание апстрима.
- Неиспользуемые зависимости (проверено grep-ом импортов по всему репо):
  `flutter_secure_storage` (`pubspec.yaml:67`), `pointycastle` (`:69`),
  `cupertino_icons` (`:32`) — ноль dart-импортов. Детали — §3.8.
- `AndroidManifest.xml`: легаси `WRITE/READ_EXTERNAL_STORAGE` без
  `maxSdkVersion` (:25-26), старые `BLUETOOTH(_ADMIN)` без
  `maxSdkVersion="30"` (:29-30), `usb.host` без `required="false"` (:35) —
  устройства без USB-хоста (но с BLE) отфильтровываются при установке.
  Детали — §3.9.
- `docs/README.md:28` — «screenshot source files … `assets/screenshots/`»,
  реально они в `docs/assets/screenshots/`.
- `android/.gitignore` игнорирует `gradle-wrapper.jar`, `/gradlew`,
  `/gradlew.bat`, поэтому совет AGENTS.md:70 (`gradlew.bat --stop`) не
  сработает на свежем клоне до первой сборки — уточнить формулировку
  (исправлено в этой ветке: примечание добавлено в AGENTS.md).

**Мелкий мусор:**

- `analysis_options.yaml:10-14` — excludes для ios/web/windows/macos/linux,
  которых в репо нет и не будет (игнорируются `.gitignore:41-45`).
- `AGENTS.md:100-101` — «existing secure-storage abstraction» не существует
  в коде (креды в `shared_preferences` через `SettingsService`);
  формулировка исправлена в этой ветке: AGENTS.md теперь требует платформенный
  secure storage и запрещает plaintext-prefs и экспорт для креденшелов —
  фикс §3.7 (пароль Carpeater) стал обязательным по конвенции.
- `docs/getting-started.md:29` — «grant Storage permissions» устарело:
  приложение не запрашивает storage в рантайме.
- Остатки MQTT: no-op `disconnectMqtt()` (`lora_companion_service.dart:1907-1908`),
  упоминание MQTT в докстринге `debug_log_service.dart:6`.
- Остальное чисто: TODO/FIXME/HACK/XXX в `lib/` и `test/` — ноль; граф docs
  без битых ссылок (все 16 md линкуются из `docs/README.md`); CHANGELOG
  `v1.0.44-x` ↔ pubspec `1.0.44-x+47` ↔ `app_version.dart` согласованы;
  все остальные зависимости используются; `tool/version.dart` и
  `tool/build_release.ps1` актуальны и документированы; `.gitignore` полный
  (единственная дыра `tmp/` закрыта в этом аудите); `analysis_options.yaml`
  без per-file игноров.

**Позитив:** манифест-разрешения в целом обоснованы (location, wifi-state,
vibrate, battery-optimizations, wakelock/foreground — каждое имеет живого
потребителя в коде); widget-receiver соответствует `WardriveWidgetProvider.kt`;
`pubspec.lock` и `.metadata` затреканы правильно для приложения.

## 6. Оставить как есть

- Сгенерированные `lib/l10n/generated/app_localizations*.dart` отслеживаются в
  git намеренно (см. AGENTS.md) — не «огромные файлы» в смысле рефакторинга.
- `.toolchain/` — репозиторный тулчейн, корректно игнорируется git'ом.
- Пины зависимостей с комментариями-причинами в `pubspec.yaml`.
- Байтовая логика `meshcore_protocol.dart` (resync, фрейминг, канальные
  методы) — менять только при реальной необходимости, побайтово и под
  защищёнными тестами + железом (детали в §5.2).
- Плоская раскладка одиночных экранов в `lib/screens/` и баррел
  `lib/models/models.dart` — см. вердикты §5.3.
- Мелкие чистые сервисы (`map_lod_service`, `radio_position_estimator`,
  `location_quality_filter`, `bad_fix_monitor`, `wifi_location_service`,
  `database_backup_service`, `ducting_service`, `sound_service`,
  `screen_wake_service`, `screenshot_service`, `android_tracking_settings_service`,
  `internet_connectivity_service`, `widget_service`) — не трогать.
- `ReconnectBackoff` + `_serializeConnect`, генерации стрима позиций,
  `aggregation_service.buildIndexes` — тонкая, но корректная механика
  (детали в §5.2).
- `companionNodeName` в prefs и per-line flush персистентного логгера —
  задокументированные осознанные компромиссы.

## 7. Вопросы к владельцу репозитория

1. `tmp/`: удалить содержимое (разовый анализ экспорта от 2026-08-25) или
   оставить локально / перенести скрипты в `tool/`? Правка `.gitignore`
   (`/tmp/`) уже сделана в этом аудите и безопасна в любом случае.
2. Защищённый набор `test/meshcore/`: правки не предлагались и не выполнялись
   (только наблюдения); любые изменения файлов в нём потребуют отдельного
   явного одобрения.
3. Чистка манифеста (§3.9) и переезд пароля в secure storage (§3.7) затрагивают
   устройство/данные пользователей — делать ли их отдельной задачей с ручной
   проверкой на железе (USB + BLE + Wi-Fi-скан на Android 13+)?
4. Удалять ли три неиспользуемые зависимости (§3.8) с попутной правкой
   формулировки AGENTS.md про secure-storage?
5. Разбиение `map_screen.dart` и сервисов — больших механических переносов
   без запроса не производилось; отчёт содержит готовые поэтапные планы
   (§5.1, §5.2) — какие этапы запускать.

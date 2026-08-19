// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный язык';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languagePickerTitle => 'Выбор языка';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsScrollToTop => 'Прокрутить вверх';

  @override
  String get settingsScrollToBottom => 'Прокрутить вниз';

  @override
  String get settingsCancel => 'Отмена';

  @override
  String get settingsSave => 'Сохранить';

  @override
  String get settingsClear => 'Очистить';

  @override
  String get settingsUpload => 'Загрузить';

  @override
  String get settingsReset => 'Сбросить';

  @override
  String get settingsNotSet => 'Не задано';

  @override
  String get settingsNone => 'Нет';

  @override
  String get settingsUnknown => 'Неизвестно';

  @override
  String get settingsEnterNumberGreaterThanZero => 'Введите число больше нуля';

  @override
  String get settingsSectionMapDisplay => 'Отображение карты';

  @override
  String get settingsSectionLocation => 'Геолокация и позиционирование';

  @override
  String get settingsSectionFeedback => 'Обратная связь и оповещения';

  @override
  String get settingsSectionCarpeater => 'Режим Carpeater (бета)';

  @override
  String get settingsSectionAppDevice => 'Приложение и устройство';

  @override
  String get settingsSectionDiscovery => 'Обнаружение и замеры';

  @override
  String get settingsSectionStatistics => 'Статистика';

  @override
  String get settingsSectionDataManagement => 'Управление данными';

  @override
  String get settingsSectionBackup => 'Резервная копия настроек';

  @override
  String get settingsSectionDiagnostics => 'Диагностика';

  @override
  String get settingsSectionOnlineMap => 'Онлайн-карта';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsSectionThresholds => 'Пороги';

  @override
  String get settingsSectionImpossibleZones => 'Невозможные зоны';

  @override
  String get settingsShowCoverageBoxes => 'Показывать квадраты покрытия';

  @override
  String get settingsSimplifyMapAtLowZoom =>
      'Упрощать карту при малом масштабе';

  @override
  String get settingsSimplifyMapAtLowZoomSubtitle =>
      'Группировать покрытие и замеры по geohash при отдалении';

  @override
  String get settingsShowSamples => 'Показывать замеры';

  @override
  String get settingsShowEdges => 'Показывать рёбра';

  @override
  String get settingsShowRepeaters => 'Показывать репитеры';

  @override
  String get settingsShowGpsSamples => 'Показывать GPS-замеры';

  @override
  String get settingsShowGpsSamplesSubtitle =>
      'Показывать синие маркеры только GPS';

  @override
  String get settingsShowSuccessfulPingsOnly => 'Только успешные пинги';

  @override
  String get settingsShowSuccessfulPingsOnlySubtitle =>
      'Скрывать неудачные пинги и GPS-замеры';

  @override
  String get settingsShowRouteTrail => 'Показывать трек маршрута';

  @override
  String get settingsShowRouteTrailSubtitle =>
      'Рисовать пройденный путь на карте';

  @override
  String get settingsCommunityCoverage => 'Общественное покрытие';

  @override
  String get settingsCommunityCoverageDownloaded =>
      'Показывать скачанное покрытие с веб-карты';

  @override
  String get settingsCommunityCoverageNeedDownload =>
      'Сначала скачайте в разделе «Управление данными»';

  @override
  String get settingsClearDownloadedCoverageTooltip =>
      'Очистить скачанное покрытие';

  @override
  String get settingsCommunityCoverageCleared =>
      'Общественное покрытие очищено';

  @override
  String get settingsShowHeatmap => 'Показывать тепловую карту';

  @override
  String get settingsShowHeatmapSubtitle => 'Градиент активности пингов';

  @override
  String get settingsShowPredictionRings => 'Показывать кольца прогноза';

  @override
  String get settingsShowPredictionRingsSubtitle =>
      'Оценка радиуса покрытия репитера';

  @override
  String get settingsBeaconDbWifi => 'Wi-Fi-позиционирование beaconDB';

  @override
  String get settingsBeaconDbWifiSubtitle =>
      'Предпочитать Wi-Fi-геолокацию; ближайшие BSSID и уровни сигнала отправляются в beaconDB. Голубой маркер означает, что Wi-Fi активен.';

  @override
  String get settingsBeaconDbEnabledSnack =>
      'beaconDB включён: ближайшие BSSID будут передаваться';

  @override
  String get settingsLocationQualityFilters => 'Фильтры качества геолокации';

  @override
  String get settingsLocationQualityFiltersSubtitle =>
      'Точность, неправдоподобное движение и невозможные места';

  @override
  String get settingsShowApproximatePosition =>
      'Показывать приблизительную позицию';

  @override
  String get settingsShowApproximatePositionSubtitle =>
      'Серая оценка позиции по радио';

  @override
  String get settingsDuctingForecast => 'Прогноз волновода';

  @override
  String get settingsDuctingForecastSubtitle =>
      'Карты тропосферного волновода на 6 дней';

  @override
  String get settingsAtmosphericDucting => 'Атмосферный волновод';

  @override
  String get settingsAtmosphericDuctingSubtitle =>
      'Следить за условиями волновода (нужен интернет)';

  @override
  String get settingsSoundFeedback => 'Звуковая обратная связь';

  @override
  String get settingsSoundFeedbackSubtitle => 'Сигналы по результатам пинга';

  @override
  String get settingsVibrationFeedback => 'Вибрация';

  @override
  String get settingsVibrationFeedbackSubtitle =>
      'Тактильный отклик по результатам пинга';

  @override
  String get settingsDeadZoneAlerts => 'Оповещения о мёртвых зонах';

  @override
  String get settingsDeadZoneAlertsSubtitle =>
      'Уведомлять при входе в известную мёртвую зону';

  @override
  String get settingsNewRepeaterAlerts => 'Оповещения о новых репитерах';

  @override
  String get settingsNewRepeaterAlertsSubtitle =>
      'Уведомлять, когда обнаружен ранее не встречавшийся репитер';

  @override
  String get settingsEnableCarpeaterMode => 'Включить режим Carpeater';

  @override
  String get settingsCarpeaterEnabledSubtitle => 'Обнаружение через репитер';

  @override
  String get settingsCarpeaterDisabledSubtitle =>
      'Использовать репитер для поиска соседей\nНужна прошивка v1.14+ на всех репитерах';

  @override
  String get settingsTargetRepeater => 'Целевой репитер';

  @override
  String get settingsRepeaterIdPrefix => 'Префикс ID репитера';

  @override
  String get settingsRepeaterIdHint => 'напр., BAD5DC49';

  @override
  String get settingsAdminPassword => 'Пароль администратора';

  @override
  String get settingsPassword => 'Пароль';

  @override
  String get settingsRepeaterAdminPasswordHint =>
      'Пароль администратора репитера';

  @override
  String get settingsCycleInterval => 'Интервал цикла';

  @override
  String get settingsCycleIntervalSubtitle => 'Пауза между циклами обнаружения';

  @override
  String get settingsDeviceName => 'Имя устройства';

  @override
  String get settingsDeviceNameNotSet =>
      'Не задано — используется для вардрайва с несколькими устройствами';

  @override
  String get settingsDeviceNameLabel => 'Имя';

  @override
  String get settingsDeviceNameHint => 'напр., Chuck-Pixel';

  @override
  String get settingsKeepScreenOn => 'Не гасить экран';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Экран не переходит в сон, пока приложение открыто';

  @override
  String get settingsBatterySaver => 'Экономия батареи';

  @override
  String get settingsBatterySaverSubtitle =>
      'Удваивать интервал пинга при заряде ≤20%';

  @override
  String get settingsLockMapRotation => 'Фиксировать поворот карты';

  @override
  String get settingsLockMapRotationSubtitle => 'Запретить вращение карты';

  @override
  String get settingsCurrentLocationMarker => 'Маркер текущей позиции';

  @override
  String get settingsCurrentLocationMarkerSubtitle =>
      'Стрелка направления следует за компасом телефона';

  @override
  String get settingsMarkerCircle => 'Круг';

  @override
  String get settingsMarkerDirectionArrow => 'Стрелка направления';

  @override
  String get settingsCalibrateCompass => 'Калибровка компаса';

  @override
  String get settingsCalibrateCompassSubtitle =>
      'Нарисуйте в воздухе восьмёрку, если курс выглядит неверно';

  @override
  String get settingsInterfaceTheme => 'Тема интерфейса';

  @override
  String get settingsMapTheme => 'Тема карты';

  @override
  String get settingsScanForRepeaters => 'Поиск репитеров';

  @override
  String get settingsScanFindNearby => 'Найти ближайшие узлы LoRa';

  @override
  String settingsRepeatersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count репитера',
      many: 'Найдено $count репитеров',
      few: 'Найдено $count репитера',
      one: 'Найден $count репитер',
    );
    return '$_temp0';
  }

  @override
  String get settingsRefreshContactList => 'Обновить список контактов';

  @override
  String get settingsRefreshContactListSubtitle =>
      'Обновить имена репитеров с устройства';

  @override
  String get settingsColorMode => 'Режим цвета';

  @override
  String get settingsColorModeQuality => 'Качество';

  @override
  String get settingsColorModeAge => 'Возраст';

  @override
  String get settingsColorModeRedundancy => 'Избыточность';

  @override
  String get settingsDistanceUnit => 'Единицы расстояния';

  @override
  String get settingsMiles => 'Мили';

  @override
  String get settingsKilometers => 'Километры';

  @override
  String get settingsFuelUnit => 'Единицы топлива';

  @override
  String get settingsFuelUnitImperial => 'MPG / галлоны';

  @override
  String get settingsFuelUnitMetric => 'л/100 км / литры';

  @override
  String get settingsColorBlindMode => 'Режим цветовой слепоты';

  @override
  String get settingsColorBlindNormal => 'Обычный';

  @override
  String get settingsColorBlindDeuteranopia => 'Deuteranopia';

  @override
  String get settingsColorBlindProtanopia => 'Protanopia';

  @override
  String get settingsColorBlindTritanopia => 'Tritanopia';

  @override
  String get settingsDiscoveryTimeout => 'Таймаут обнаружения';

  @override
  String get settingsDiscoveryTimeoutSubtitle =>
      'Сколько ждать ответов репитеров';

  @override
  String get settingsThoroughResponseCollection => 'Полный сбор ответов';

  @override
  String get settingsThoroughOn =>
      'Полный: собирать ответы до таймаута обнаружения';

  @override
  String get settingsThoroughOff =>
      'Быстрый: завершать через 3 секунды после первого ответа';

  @override
  String get settingsIgnoreRepeaters => 'Игнорировать репитеры';

  @override
  String settingsIgnoringPrefix(String prefix) {
    return 'Игнорируются: $prefix';
  }

  @override
  String get settingsNotFiltering => 'Фильтр не задан';

  @override
  String get settingsIncludeOnlyRepeaters => 'Только эти репитеры';

  @override
  String settingsWhitelistPrefix(String prefixes) {
    return 'Белый список: $prefixes';
  }

  @override
  String get settingsShowAllRepeaters => 'Показывать все репитеры';

  @override
  String get settingsApplyWhitelistToEdges => 'Применять белый список к рёбрам';

  @override
  String get settingsApplyWhitelistToEdgesSubtitle =>
      'Показывать рёбра только для репитеров из белого списка';

  @override
  String get settingsPingMode => 'Режим пинга';

  @override
  String get settingsPingModeDistance => 'Расстояние';

  @override
  String get settingsPingModeTime => 'Время';

  @override
  String get settingsPingModeBoth => 'Оба';

  @override
  String get settingsPingDistance => 'Дистанция пинга';

  @override
  String get settingsPingTimeInterval => 'Интервал пинга по времени';

  @override
  String get settingsCoverageResolution => 'Разрешение покрытия';

  @override
  String get settingsPingInterval => 'Интервал пинга';

  @override
  String get settingsPingIntervalPrompt => 'Как часто отправлять пинги?';

  @override
  String get settingsPingFrequent => 'Частый';

  @override
  String get settingsPingFrequentSubtitle => 'Каждые 50 метров';

  @override
  String get settingsPingNormal => 'Обычный';

  @override
  String get settingsPingNormalSubtitle => 'Каждые 200 метров (~0,12 мили)';

  @override
  String get settingsPingSparse => 'Редкий';

  @override
  String get settingsPingSparseSubtitle => 'Каждые 0,5 мили (805 метров)';

  @override
  String get settingsPingVerySparse => 'Очень редкий';

  @override
  String get settingsPingVerySparseSubtitle => 'Каждую 1 милю (1609 метров)';

  @override
  String settingsPingIntervalSet(String description) {
    return 'Интервал пинга: $description';
  }

  @override
  String settingsPingIntervalMetersFrequent(int meters) {
    return '$meters метров (частый)';
  }

  @override
  String settingsPingIntervalMeters(int meters) {
    return '$meters метров';
  }

  @override
  String settingsPingIntervalMiles(String miles, int meters) {
    return '$miles миль (${meters}m)';
  }

  @override
  String get settingsCoverageResolutionPrompt =>
      'Выберите размер квадратов покрытия:';

  @override
  String get settingsCoverageRegional => 'Региональный';

  @override
  String get settingsCoverageRegionalSubtitle => 'квадраты ~20 km (точность 4)';

  @override
  String get settingsCoverageCity => 'Городской';

  @override
  String get settingsCoverageCitySubtitle => 'квадраты ~5 km (точность 5)';

  @override
  String get settingsCoverageNeighborhood => 'Районный';

  @override
  String get settingsCoverageNeighborhoodSubtitle =>
      'квадраты ~1,2 km (точность 6, по умолчанию)';

  @override
  String get settingsCoverageStreet => 'Уличный';

  @override
  String get settingsCoverageStreetSubtitle => 'квадраты ~153 m (точность 7)';

  @override
  String get settingsCoverageBuilding => 'Зданий';

  @override
  String get settingsCoverageBuildingSubtitle =>
      'квадраты ~38 m (точность 8, подробно)';

  @override
  String get settingsCoverageRegionalDesc => 'Региональный (квадраты ~20 km)';

  @override
  String get settingsCoverageCityDesc => 'Городской (квадраты ~5 km)';

  @override
  String get settingsCoverageNeighborhoodDesc => 'Районный (квадраты ~1,2 km)';

  @override
  String get settingsCoverageStreetDesc => 'Уличный (квадраты ~153 m)';

  @override
  String get settingsCoverageBuildingDesc => 'Зданий (квадраты ~38 m)';

  @override
  String settingsCoverageResolutionSet(String description) {
    return 'Разрешение покрытия: $description';
  }

  @override
  String get settingsRepeaterPrefixes => 'Префиксы репитеров';

  @override
  String get settingsIgnoreRepeaterHint => 'напр., 7E, A4F, BAD5';

  @override
  String get settingsIgnoreRepeaterDescription =>
      'Отфильтровывать ответы своих мобильных репитеров, чтобы не получать ложное покрытие. Введите префиксы репитеров через запятую:';

  @override
  String get settingsRepeaterPrefixUpdated => 'Префикс репитера обновлён';

  @override
  String get settingsIncludeOnlyHint => 'напр., 7E3A, A4F2, 8B';

  @override
  String get settingsIncludeOnlyDescription =>
      'Показывать только замеры с указанных репитеров (белый список). Введите префиксы репитеров через запятую:';

  @override
  String get settingsRepeaterWhitelistUpdated =>
      'Белый список репитеров обновлён';

  @override
  String get settingsLocationQualityResetSnack =>
      'Фильтры качества геолокации сброшены';

  @override
  String get settingsMaxHorizontalError => 'Максимальная горизонтальная ошибка';

  @override
  String get settingsMaxHorizontalErrorSubtitle =>
      'Отклонять позиции с худшей заявленной точностью';

  @override
  String get settingsMaxHorizontalErrorDescription =>
      'Позиции, у которых заявленная горизонтальная ошибка больше этого значения, игнорируются.';

  @override
  String get settingsAirborneAltitude => 'Высота полёта';

  @override
  String get settingsAirborneAltitudeSubtitle =>
      'Высота, используемая вместе со скоростью полёта';

  @override
  String get settingsAirborneAltitudeDescription =>
      'На этой высоте и выше позиция игнорируется только если также превышена скорость полёта.';

  @override
  String get settingsAirborneSpeed => 'Скорость полёта';

  @override
  String get settingsAirborneSpeedSubtitle =>
      'Скорость, используемая вместе с высотой полёта';

  @override
  String get settingsAirborneSpeedDescription =>
      'На этой скорости и выше высокая позиция считается вероятным полётом.';

  @override
  String get settingsMaxWardriveSpeed => 'Максимальная скорость вардрайва';

  @override
  String get settingsMaxWardriveSpeedSubtitle =>
      'Отклонять позиции, движущиеся быстрее';

  @override
  String get settingsMaxWardriveSpeedDescription =>
      'Позиции на этой скорости и выше игнорируются как неправдоподобные данные вардрайва.';

  @override
  String get settingsRestoreDefaults => 'Восстановить значения по умолчанию';

  @override
  String get settingsImpossibleZonesBlurb =>
      'Места, где вы физически не можете быть. GPS внутри зоны отбрасывается, сохраняется последняя достоверная позиция. Зоны на карте не показываются.';

  @override
  String get settingsAddImpossibleZone => 'Добавить невозможную зону';

  @override
  String get settingsImpossibleZoneEmptySubtitle =>
      'Используется текущая позиция или центр карты';

  @override
  String settingsImpossibleZoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зоны',
      many: '$count зон',
      few: '$count зоны',
      one: '$count зона',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnnamedZone => 'Зона без имени';

  @override
  String get settingsDeleteZoneTooltip => 'Удалить зону';

  @override
  String get settingsClearImpossibleZones => 'Очистить невозможные зоны';

  @override
  String settingsRemoveAllZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить все $count зоны',
      many: 'Удалить все $count зон',
      few: 'Удалить все $count зоны',
      one: 'Удалить все $count зону',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearImpossibleZonesConfirm =>
      'Удалить все невозможные зоны? GPS в этих областях больше не будет отбрасываться.';

  @override
  String settingsAddImpossibleZoneCenter(String lat, String lon) {
    return 'Центр: $lat, $lon';
  }

  @override
  String get settingsAddImpossibleZoneBlurb =>
      'GPS внутри этой области считается недостоверным и отбрасывается.';

  @override
  String get settingsLabelOptional => 'Подпись (необязательно)';

  @override
  String get settingsLabelHintAirport => 'напр., Аэропорт';

  @override
  String get settingsRadius => 'Радиус:';

  @override
  String get settingsRadius500m => '500m (~0,3 mi)';

  @override
  String get settingsRadius1km => '1 km (~0,6 mi)';

  @override
  String get settingsRadius2km => '2 km (~1,2 mi)';

  @override
  String get settingsRadius5km => '5 km (~3 mi)';

  @override
  String get settingsAddZone => 'Добавить зону';

  @override
  String get settingsImpossibleZoneAdded => 'Невозможная зона добавлена';

  @override
  String get settingsTotalDistanceDriven => 'Всего пройдено';

  @override
  String get settingsResetTooltip => 'Сбросить';

  @override
  String get settingsResetDistance => 'Сбросить расстояние';

  @override
  String get settingsResetDistanceConfirm => 'Сбросить общий пробег до нуля?';

  @override
  String get settingsEstimatedFuelUsed => 'Оценка расхода топлива';

  @override
  String get settingsVehicleFuelEconomy => 'Расход топлива автомобиля';

  @override
  String get settingsLitresPer100km => 'Литры на 100 км (л/100 км)';

  @override
  String get settingsMilesPerGallon => 'Миль на галлон (MPG)';

  @override
  String get settingsHintMetricEconomy => 'напр., 9.4';

  @override
  String get settingsHintImperialEconomy => 'напр., 25.0';

  @override
  String settingsFuelEconomyMetric(String value) {
    return '$value л/100 км';
  }

  @override
  String settingsFuelEconomyImperial(String value) {
    return '$value MPG';
  }

  @override
  String settingsFuelUsedLitres(String amount, String cost, String price) {
    return '$amount L (~\$$cost @ \$$price/L)';
  }

  @override
  String settingsFuelUsedGallons(String amount, String cost, String price) {
    return '$amount gal (~\$$cost @ \$$price/gal)';
  }

  @override
  String get settingsFuelPrice => 'Цена топлива';

  @override
  String get settingsGasPrice => 'Цена бензина';

  @override
  String get settingsPricePerLitre => 'Цена за литр';

  @override
  String get settingsPricePerGallon => 'Цена за галлон';

  @override
  String get settingsHintFuelPrice => 'напр., 1.85';

  @override
  String get settingsHintGasPrice => 'напр., 3.50';

  @override
  String settingsFuelPriceDisplay(String price) {
    return '\$$price/L';
  }

  @override
  String settingsGasPriceDisplay(String price) {
    return '\$$price/gal';
  }

  @override
  String get settingsAnalytics => 'Аналитика';

  @override
  String get settingsAnalyticsSubtitle =>
      'Время, цели, сравнение и статистика репитеров';

  @override
  String get settingsAchievements => 'Достижения';

  @override
  String get settingsAchievementsSubtitle => 'Значки этапов вардрайва';

  @override
  String get settingsDeviceComparison => 'Сравнение устройств';

  @override
  String get settingsDeviceComparisonSubtitle =>
      'Сравнить работу LoRa-компаньонов';

  @override
  String get settingsDownloadCommunityCoverage =>
      'Скачать общественное покрытие';

  @override
  String get settingsCommunityCoverageCached =>
      'В кэше — переключатель в слоях карты';

  @override
  String get settingsPullCoverageFromWeb =>
      'Загрузить данные покрытия с веб-карты';

  @override
  String get settingsSessionHistory => 'История сессий';

  @override
  String get settingsFilteringBySession => 'Фильтр по сессии';

  @override
  String get settingsViewPastSessions => 'Просмотр прошлых сессий вардрайва';

  @override
  String get settingsClearFilterTooltip => 'Сбросить фильтр';

  @override
  String get settingsSessionFilterCleared => 'Фильтр сессии сброшен';

  @override
  String get settingsExportData => 'Экспорт данных';

  @override
  String get settingsExportDataSubtitle => 'JSON, CSV, GPX или KML';

  @override
  String get settingsImportData => 'Импорт данных';

  @override
  String get settingsImportDataSubtitle => 'Загрузить замеры из файла';

  @override
  String get settingsShareCoverageMap => 'Поделиться картой покрытия';

  @override
  String get settingsShareCoverageMapSubtitle =>
      'Снимок экрана и отправка одним касанием';

  @override
  String get settingsFilterByRepeater => 'Фильтр по репитеру';

  @override
  String settingsFilteringRepeater(String prefixes) {
    return 'Фильтр: $prefixes';
  }

  @override
  String get settingsShowCoverageFromRepeater =>
      'Показать покрытие конкретного репитера';

  @override
  String get settingsRepeaterFilterCleared => 'Фильтр репитера сброшен';

  @override
  String get settingsFilterBySource => 'Фильтр по источнику';

  @override
  String settingsShowingSource(String source) {
    return 'Показано: $source';
  }

  @override
  String get settingsFilterByDeviceOperator =>
      'Фильтр по устройству или оператору';

  @override
  String get settingsSourceFilterCleared => 'Фильтр источника сброшен';

  @override
  String get settingsNoSourceTaggedData => 'Пока нет данных с меткой источника';

  @override
  String get settingsShowAll => 'Показать все';

  @override
  String settingsShowingDataFrom(String source) {
    return 'Показаны данные от: $source';
  }

  @override
  String get settingsFindCoverageGaps => 'Найти пробелы покрытия';

  @override
  String get settingsFindCoverageGapsSubtitle =>
      'Найти области со слабым сигналом';

  @override
  String get settingsDeleteMode => 'Режим удаления';

  @override
  String get settingsDeleteModeSubtitle =>
      'Касанием удалять отдельные замеры или ячейки';

  @override
  String get settingsDeleteModeOn =>
      'Режим удаления ВКЛ — коснитесь квадрата покрытия или замера';

  @override
  String get settingsPlannedRepeaters => 'Планируемые репитеры';

  @override
  String settingsPlannedMarkersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count маркера — долгое нажатие на карте, чтобы добавить',
      many: '$count маркеров — долгое нажатие на карте, чтобы добавить',
      few: '$count маркера — долгое нажатие на карте, чтобы добавить',
      one: '$count маркер — долгое нажатие на карте, чтобы добавить',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearAllMarkers => 'Очистить все маркеры';

  @override
  String get settingsClearAllMarkersConfirm =>
      'Удалить все маркеры планируемых репитеров?';

  @override
  String get settingsAllMarkersCleared => 'Все маркеры удалены';

  @override
  String get settingsPrivacyZones => 'Зоны приватности';

  @override
  String settingsPrivacyZonesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зоны — данные исключаются из загрузок',
      many: '$count зон — данные исключаются из загрузок',
      few: '$count зоны — данные исключаются из загрузок',
      one: '$count зона — данные исключаются из загрузок',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearPrivacyZones => 'Очистить зоны приватности';

  @override
  String get settingsClearPrivacyZonesConfirm =>
      'Удалить все зоны приватности? Данные больше не будут исключаться из загрузок.';

  @override
  String get settingsPrivacyZonesCleared => 'Зоны приватности очищены';

  @override
  String get settingsClearMap => 'Очистить карту';

  @override
  String get settingsClearMapSubtitle => 'Удалить все замеры и покрытие';

  @override
  String get settingsDownloadOfflineTiles => 'Скачать офлайн-тайлы';

  @override
  String get settingsDownloadOfflineTilesSubtitle =>
      'Кэшировать тайлы карты для текущего вида';

  @override
  String get settingsClearTileCache => 'Очистить кэш тайлов';

  @override
  String get settingsClearTileCacheSubtitle =>
      'Удалить кэшированные офлайн-тайлы карты';

  @override
  String get settingsTileCacheCleared => 'Кэш тайлов очищен';

  @override
  String get settingsExportSettings => 'Экспорт настроек';

  @override
  String get settingsExportSettingsSubtitle =>
      'Сохранить все настройки приложения в файл';

  @override
  String get settingsImportSettings => 'Импорт настроек';

  @override
  String get settingsImportSettingsSubtitle => 'Загрузить настройки из файла';

  @override
  String get settingsRepeaterHealth => 'Состояние репитеров';

  @override
  String get settingsRepeaterHealthSubtitle =>
      'Статистика, тренды и оповещения по репитерам';

  @override
  String get settingsSignalTrends => 'Тренды сигнала';

  @override
  String get settingsSignalTrendsSubtitle =>
      'Графики RSSI, SNR и времени ответа';

  @override
  String get settingsDebugDiagnostics => 'Отладочная диагностика';

  @override
  String get settingsDebugDiagnosticsSubtitle =>
      'Просмотр журналов для устранения неполадок';

  @override
  String get settingsUploadData => 'Загрузить данные';

  @override
  String get settingsUploadDataSubtitle => 'Отправить замеры на веб-карту';

  @override
  String get settingsManageUploadSites => 'Управление сайтами загрузки';

  @override
  String get settingsManageUploadSitesSubtitle =>
      'Добавить или изменить точки загрузки';

  @override
  String get settingsUploadNoSites => 'Сайты загрузки не настроены';

  @override
  String get settingsUploadSelectSites => 'Выберите сайты для загрузки:';

  @override
  String get settingsCheckForUpdates => 'Проверить обновления';

  @override
  String settingsAboutCurrentVersion(String version) {
    return 'Текущая версия: v$version';
  }

  @override
  String get settingsViewOnGitHub => 'Открыть на GitHub';

  @override
  String get settingsViewOnGitHubSubtitle => 'Исходный код и релизы';

  @override
  String get offlineBannerMessage =>
      'Вы офлайн — локальное отслеживание продолжается';

  @override
  String get offlineBannerSemantics =>
      'Вы офлайн. Локальное отслеживание продолжается.';

  @override
  String get compassNeedsCalibration => 'Компас нужно откалибровать';

  @override
  String get compassBannerHint =>
      'Если направление выглядит неверно, подвигайте телефон восьмёркой.';

  @override
  String get compassLater => 'Позже';

  @override
  String get compassCalibrate => 'Калибровать';

  @override
  String get compassSensorAccuracyGood => 'Точность датчика в норме';

  @override
  String get compassKeepDrawing => 'Продолжайте рисовать восьмёрку';

  @override
  String get compassCalibrationComplete => 'Калибровка завершена';

  @override
  String get compassSheetTitle => 'Калибровка компаса';

  @override
  String get compassSheetInstructions =>
      'Держите телефон и рисуйте восьмёрку в воздухе, пока шкала не заполнится.';

  @override
  String get compassMoveThroughFigureEight => 'Подвигайте телефон по восьмёрке';

  @override
  String get compassSkip => 'Пропустить';

  @override
  String get compassFigureEightSemantics => 'Движение калибровки восьмёркой';

  @override
  String get bluetoothSelectDevice => 'Выберите устройство Bluetooth';

  @override
  String get bluetoothPreviouslyUsed => 'Использовалось ранее';

  @override
  String get bluetoothNearby => 'Рядом';

  @override
  String get bluetoothCancel => 'Отмена';

  @override
  String bluetoothError(String error) {
    return 'Ошибка Bluetooth: $error';
  }

  @override
  String get bluetoothSearching => 'Поиск устройств LoRa...';

  @override
  String get bluetoothNoDevices => 'Устройства LoRa по Bluetooth не найдены';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeSystemDefault => 'Системная';

  @override
  String get settingsChooseInterfaceTheme => 'Тема интерфейса';

  @override
  String get settingsChooseMapTheme => 'Тема карты';

  @override
  String get mapClose => 'Закрыть';

  @override
  String get mapDelete => 'Удалить';

  @override
  String get mapOk => 'OK';

  @override
  String get mapNotNow => 'Не сейчас';

  @override
  String get mapContinue => 'Продолжить';

  @override
  String get mapShare => 'Поделиться';

  @override
  String get mapImport => 'Импорт';

  @override
  String get mapAdd => 'Добавить';

  @override
  String get mapDownload => 'Скачать';

  @override
  String get mapYes => 'Да';

  @override
  String get mapNo => 'Нет';

  @override
  String get mapExit => 'ВЫЙТИ';

  @override
  String get mapConnect => 'Подключить';

  @override
  String get mapConnecting => 'Подключение...';

  @override
  String get mapDontSave => 'Не сохранять';

  @override
  String mapNewRepeaterDiscovered(String repeaterId) {
    return '🆕 Обнаружен новый репитер: $repeaterId';
  }

  @override
  String mapEnteringDeadZone(String cellHash) {
    return '⚠️ Вход в известную мёртвую зону ($cellHash)';
  }

  @override
  String get mapBatterySaverOn =>
      '🔋 Энергосбережение ВКЛ — интервал пинга удвоен';

  @override
  String get mapBatterySaverOff =>
      '🔋 Энергосбережение ВЫКЛ — обычный интервал пинга восстановлен';

  @override
  String get mapCompassCalibrated => 'Компас откалиброван';

  @override
  String get mapSessionEmptyTitle => 'Сессия пуста';

  @override
  String get mapSessionEmptyBody =>
      'Точки GPS не записаны. Всё равно сохранить эту сессию?';

  @override
  String get mapSessionDiscarded => 'Сессия отменена';

  @override
  String get mapSessionDiscardedShowingLast =>
      'Сессия отменена — показана последняя сохранённая сессия';

  @override
  String get mapLocationTrackingStarted => 'Отслеживание геолокации запущено';

  @override
  String get mapCarpeaterModeStarted => 'Режим Carpeater запущен';

  @override
  String get mapCarpeaterFailedCheckSettings =>
      'Carpeater не запустился — проверьте настройки';

  @override
  String get mapLocationTrackingAndAutoPingStarted =>
      'Отслеживание геолокации и автопинг запущены';

  @override
  String get mapFailedToStartTracking =>
      'Не удалось запустить отслеживание геолокации. Проверьте настройки Android.';

  @override
  String get mapNewSessionShowingTrip =>
      'Новая сессия — показана только эта поездка';

  @override
  String mapShowingSessionFrom(String timestamp) {
    return 'Показана сессия от $timestamp';
  }

  @override
  String get mapPreciseLocationRequiredTitle => 'Нужна точная геолокация';

  @override
  String get mapPreciseLocationRequiredBody =>
      'Для вардрайва нужна точная геолокация. В разрешениях приложения Android включите «Использовать точную геолокацию» и снова нажмите «Старт».';

  @override
  String get mapOpenAppSettings => 'Открыть настройки приложения';

  @override
  String get mapAllowLocationAllTheTimeTitle => 'Разрешить геолокацию всегда';

  @override
  String get mapAllowLocationAllTheTimeBody =>
      'MeshCore Wardrive записывает при выключенном экране или когда открыто другое приложение. Android должен дать доступ к геолокации «Разрешить всегда».';

  @override
  String get mapBackgroundLocationRequiredTitle => 'Нужна фоновая геолокация';

  @override
  String get mapBackgroundLocationRequiredBody =>
      'Выберите Разрешения → Геолокация → Разрешить всегда, затем вернитесь и снова нажмите «Старт».';

  @override
  String get mapUnrestrictedBatteryTitle =>
      'Неограниченное использование батареи';

  @override
  String get mapUnrestrictedBatteryBody =>
      'Разрешите MeshCore Wardrive игнорировать оптимизацию батареи, чтобы Android не приостанавливал GPS, радиосвязь и сканирование Wi-Fi во время поездки.';

  @override
  String get mapDisableWifiThrottlingTitle =>
      'Отключить ограничение сканирования Wi-Fi';

  @override
  String get mapDisableWifiThrottlingBody =>
      'Android не даёт приложениям менять этот параметр автоматически. В параметрах разработчика отключите «Ограничение сканирования Wi-Fi», чтобы вовремя получать позицию beaconDB.';

  @override
  String get mapDeveloperOptions => 'Параметры разработчика';

  @override
  String get mapClearMapHistoryTitle => 'Очистить историю карты?';

  @override
  String mapClearMapHistoryBody(int count) {
    return 'Будут безвозвратно удалены все $count замеров и данные покрытия с карты.\n\nЭто действие нельзя отменить.';
  }

  @override
  String get mapDeleteAll => 'Удалить всё';

  @override
  String mapDeletedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалено $count замера',
      many: 'Удалено $count замеров',
      few: 'Удалено $count замера',
      one: 'Удалён $count замер',
    );
    return '$_temp0';
  }

  @override
  String get mapExportFormat => 'Формат экспорта';

  @override
  String get mapExportJsonSubtitle => 'Полные данные со всеми полями';

  @override
  String get mapExportCsvSubtitle => 'Совместимо с таблицами';

  @override
  String get mapExportGpxSubtitle => 'GPS-трек для картографических приложений';

  @override
  String get mapExportKmlSubtitle => 'Формат Google Earth';

  @override
  String mapExportAs(String format) {
    return 'Экспорт как $format';
  }

  @override
  String get mapSaveToFolder => 'Сохранить в папку';

  @override
  String get mapSaveExport => 'Сохранить экспорт';

  @override
  String mapExportedSamples(int count, String format) {
    return 'Экспортировано $count замеров как $format';
  }

  @override
  String get mapExportShareSubject => 'MeshCore Wardrive Export';

  @override
  String mapExportShareText(int count) {
    return 'Экспортировано $count замеров из MeshCore Wardrive';
  }

  @override
  String get mapExportShared => 'Экспорт отправлен';

  @override
  String mapExportFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String mapImportedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count замера',
      many: 'Импортировано $count замеров',
      few: 'Импортировано $count замера',
      one: 'Импортирован $count замер',
    );
    return '$_temp0';
  }

  @override
  String mapImportedSessionsSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count сессии',
      many: ', $count сессий',
      few: ', $count сессии',
      one: ', $count сессия',
    );
    return '$_temp0';
  }

  @override
  String mapImportedFromSources(String sources) {
    return ' из $sources';
  }

  @override
  String mapImportFailed(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get mapSaveSettings => 'Сохранить настройки';

  @override
  String get mapSettingsExported => 'Настройки экспортированы';

  @override
  String get mapSettingsShareText => 'Настройки MeshCore Wardrive';

  @override
  String get mapImportSettingsConfirm =>
      'Текущие настройки приложения будут перезаписаны (отображение, пинг, серверы загрузки, Carpeater и т. д.).\n\nДанные вардрайва НЕ будут затронуты.\n\nПродолжить?';

  @override
  String mapImportedSettingsCount(int count) {
    return 'Импортировано настроек: $count';
  }

  @override
  String mapInvalidSettingsFile(String error) {
    return 'Неверный файл настроек: $error';
  }

  @override
  String get mapAddPlannedRepeater => 'Добавить запланированный репитер';

  @override
  String get mapPlannedRepeaterHint => 'напр., холм у Tracyton';

  @override
  String get mapAddMarker => 'Добавить маркер';

  @override
  String get mapPlannedRepeaterMarkerAdded =>
      'Маркер запланированного репитера добавлен';

  @override
  String get mapPlannedRepeater => 'Запланированный репитер';

  @override
  String mapLat(String value) {
    return 'Шир.: $value';
  }

  @override
  String mapLon(String value) {
    return 'Долг.: $value';
  }

  @override
  String mapAddedOn(String date) {
    return 'Добавлен: $date';
  }

  @override
  String get mapMarkerDeleted => 'Маркер удалён';

  @override
  String get mapAddPrivacyZone => 'Добавить зону приватности';

  @override
  String get mapPrivacyZoneBlurb =>
      'Данные внутри этой зоны будут исключены из загрузок и экспорта.';

  @override
  String get mapPrivacyZoneHint => 'напр., Дом';

  @override
  String get mapPrivacyZoneAdded => 'Зона приватности добавлена';

  @override
  String get mapDeleteSample => 'Удалить замер';

  @override
  String mapDeleteSampleConfirm(String kind, String timestamp) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'success': 'Удалить этот успешный замер от $timestamp?',
      'fail': 'Удалить этот неудачный замер от $timestamp?',
      'other': 'Удалить этот GPS-замер от $timestamp?',
    });
    return '$_temp0';
  }

  @override
  String get mapSampleDeleted => 'Замер удалён';

  @override
  String get mapDeleteCoverageCell => 'Удалить ячейку покрытия';

  @override
  String mapDeleteCoverageCellBody(int count, String cellId) {
    return 'Удалить все $count замеров в этой области покрытия?\n\nЯчейка: $cellId\nЭто нельзя отменить.';
  }

  @override
  String mapDeletedSamplesFromCell(int count) {
    return 'Удалено $count замеров из ячейки';
  }

  @override
  String get mapZoomToDeleteCell =>
      'Приблизьте, чтобы удалить отдельную ячейку покрытия';

  @override
  String get mapZoomedPointsGrouped =>
      'Точки сгруппированы; удаляйте в режиме покрытия';

  @override
  String get mapDeleteModeBanner =>
      'РЕЖИМ УДАЛЕНИЯ: нажмите квадрат покрытия или замер';

  @override
  String get mapUpdateAvailable => 'Доступно обновление';

  @override
  String mapUpdateAvailableBody(String latestVersion, String currentVersion) {
    return 'Доступна новая версия $latestVersion!\n\nТекущая версия: $currentVersion\n\nСкачать?';
  }

  @override
  String get mapOnLatestVersion => 'У вас последняя версия!';

  @override
  String get mapCouldNotCheckUpdates => 'Не удалось проверить обновления';

  @override
  String get mapNoInternetTryAgain =>
      'Нет подключения к интернету. Повторите, когда будете онлайн.';

  @override
  String get mapUpdateCheckTimedOut =>
      'Проверка обновлений превысила время ожидания. Попробуйте позже.';

  @override
  String get mapCouldNotOpenGitHub => 'Не удалось открыть GitHub';

  @override
  String get mapAutoFollowEnabled => 'Автоследование включено';

  @override
  String get mapAutoFollowDisabled => 'Автоследование выключено';

  @override
  String get mapMapResetToNorth => 'Карта возвращена на север';

  @override
  String get mapHeadingUpEnabled => 'Режим «курс вверх» включён';

  @override
  String get mapHeadingUpDisabled =>
      'Режим «курс вверх» выключен — карта на север';

  @override
  String get mapFailedToCaptureScreenshot => 'Не удалось сделать снимок экрана';

  @override
  String get mapScreenshotSavedToGallery => 'Снимок сохранён в галерею!';

  @override
  String get mapScreenshotSavedTitle => 'Снимок сохранён';

  @override
  String get mapShareScreenshotPrompt => 'Поделиться снимком экрана?';

  @override
  String get mapScreenshotShareText => 'Карта покрытия MeshCore Wardrive';

  @override
  String get mapFailedToSaveScreenshot => 'Не удалось сохранить снимок';

  @override
  String mapErrorCapturingScreenshot(String error) {
    return 'Ошибка снимка экрана: $error';
  }

  @override
  String get mapDebugTerminal => 'Отладочный терминал';

  @override
  String get mapScreenshotTooltip => 'Снимок экрана';

  @override
  String get mapQuickSettings => 'Быстрые настройки';

  @override
  String get mapPingDist => 'Дист. пинга: ';

  @override
  String get mapTimeout => 'Таймаут: ';

  @override
  String get mapMode => 'Режим: ';

  @override
  String get mapStopHeadingUp => 'Выключить «курс вверх» и вернуть север';

  @override
  String get mapRotateMapWithHeading =>
      'Вращать карту по курсу. Долгое нажатие — калибровка.';

  @override
  String get mapResetToNorth => 'Вернуть на север';

  @override
  String get mapStopTracking => 'Остановить отслеживание';

  @override
  String get mapStartTracking =>
      'Начать отслеживание. Долгое нажатие — сессия с чистой картой.';

  @override
  String get mapNoLora => 'Нет LoRa';

  @override
  String mapSamplesCount(String count) {
    return 'Замеры: $count';
  }

  @override
  String get mapRetryingCarpeater => 'Повторный запуск Carpeater...';

  @override
  String get mapCarpeaterReconnected => 'Carpeater снова подключён';

  @override
  String get mapCarpeaterRetryFailed => 'Повтор Carpeater не удался';

  @override
  String mapCarpeaterStatus(String state) {
    return 'CP: $state';
  }

  @override
  String get mapCarpeaterOff => 'Выкл.';

  @override
  String get mapCarpeaterConnecting => 'Подключение';

  @override
  String get mapCarpeaterLogin => 'Вход...';

  @override
  String get mapCarpeaterReady => 'Готов';

  @override
  String get mapCarpeaterScanning => 'Сканирование';

  @override
  String get mapCarpeaterFetching => 'Загрузка';

  @override
  String get mapCarpeaterError => 'Ошибка';

  @override
  String mapDuctingStatus(String risk) {
    return 'Волновод: $risk';
  }

  @override
  String get mapDuctingPossible => 'Возможен';

  @override
  String get mapDuctingLikely => 'Вероятен';

  @override
  String get mapBatterySaverBadge => '🔋 Энергосбер.';

  @override
  String get mapDisconnect => 'Отключить';

  @override
  String get mapManualPing => 'Ручной пинг';

  @override
  String get mapConnectLoraFirst => 'Сначала подключите устройство LoRa';

  @override
  String get mapWaitingForGps => 'Ожидание GPS...';

  @override
  String get mapPingAlreadyInProgress => 'Пинг уже выполняется';

  @override
  String get mapSendingPing => 'Отправка пинга...';

  @override
  String mapPingHeardBy(String nodeId) {
    return '✅ Пинг услышан $nodeId';
  }

  @override
  String mapDiscoveryComplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '✅ Обнаружение завершено: найдено $count репитера',
      many: '✅ Обнаружение завершено: найдено $count репитеров',
      few: '✅ Обнаружение завершено: найдено $count репитера',
      one: '✅ Обнаружение завершено: найден $count репитер',
    );
    return '$_temp0';
  }

  @override
  String get mapNoResponseDeadZone => '❌ Нет ответа — мёртвая зона';

  @override
  String mapPingFailed(String error) {
    return '❌ Пинг не удался: $error';
  }

  @override
  String get mapConnectLoraDevice => 'Подключить устройство LoRa';

  @override
  String get mapChooseConnectionMethod => 'Выберите способ подключения:';

  @override
  String get mapScanUsbDevices => 'Сканировать USB-устройства';

  @override
  String get mapScanBluetooth => 'Сканировать Bluetooth';

  @override
  String get mapNoUsbDevices => 'USB-устройства не найдены';

  @override
  String get mapSelectUsbDevice => 'Выберите USB-устройство';

  @override
  String get mapUsbDeviceFallback => 'USB-устройство';

  @override
  String mapVidPid(String vid, String pid) {
    return 'VID: $vid, PID: $pid';
  }

  @override
  String get mapConnectedViaUsb => 'Подключено по USB';

  @override
  String get mapFailedConnectUsb => 'Не удалось подключить USB-устройство';

  @override
  String mapUsbError(String error) {
    return 'Ошибка USB: $error';
  }

  @override
  String mapConnectingTo(String name) {
    return 'Подключение к $name...';
  }

  @override
  String get mapConnectedViaBluetooth => 'Подключено по Bluetooth!';

  @override
  String get mapFailedConnectBluetooth =>
      'Не удалось подключить устройство Bluetooth';

  @override
  String get mapDisconnectLoraDevice => 'Отключить устройство LoRa';

  @override
  String get mapDisconnectConfirm => 'Отключить LoRa-компаньон?';

  @override
  String get mapLoraDisconnected => 'Устройство LoRa отключено';

  @override
  String get mapRefreshingContactList => 'Обновление списка контактов...';

  @override
  String get mapContactListUpdated => 'Список контактов обновлён';

  @override
  String get mapScanningForRepeaters => 'Сканирование репитеров...';

  @override
  String get mapNoRepeatersFound => 'Репитеры не найдены';

  @override
  String mapRepeatersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count репитера',
      many: 'Найдено $count репитеров',
      few: 'Найдено $count репитера',
      one: 'Найден $count репитер',
    );
    return '$_temp0';
  }

  @override
  String get mapSampleInfo => 'Сведения о замере';

  @override
  String get mapStatusLabel => 'Статус: ';

  @override
  String get mapStatusSuccess => '✅ Успех';

  @override
  String get mapStatusFailed => '❌ Неудача';

  @override
  String get mapStatusGpsOnly => '📍 Только GPS';

  @override
  String mapTimeLabel(String timestamp) {
    return 'Время: $timestamp';
  }

  @override
  String get mapRepeaterLabel => 'Репитер: ';

  @override
  String get mapRssiLabel => 'RSSI: ';

  @override
  String get mapSnrLabel => 'SNR: ';

  @override
  String get mapResponseLabel => 'Ответ: ';

  @override
  String get mapDuctingLabel => 'Волновод: ';

  @override
  String mapRssiValue(String value) {
    return 'RSSI: $value dBm';
  }

  @override
  String mapSnrValue(String value) {
    return 'SNR: $value dB';
  }

  @override
  String mapGroupedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сгруппированных замера',
      many: '$count сгруппированных замеров',
      few: '$count сгруппированных замера',
      one: '$count сгруппированный замер',
    );
    return '$_temp0';
  }

  @override
  String mapSuccessfulCount(int count) {
    return 'Успешных: $count';
  }

  @override
  String mapFailedCount(int count) {
    return 'Неудачных: $count';
  }

  @override
  String mapGpsOnlyCount(int count) {
    return 'Только GPS: $count';
  }

  @override
  String mapNewest(String timestamp) {
    return 'Новейший: $timestamp';
  }

  @override
  String get mapZoomForBreakdown => 'Приблизьте для подробной разбивки.';

  @override
  String mapRepeaterFallback(String id) {
    return 'Репитер $id';
  }

  @override
  String mapIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String mapFilteringBy(String id) {
    return 'Фильтр по $id';
  }

  @override
  String get mapFilterByThis => 'Фильтровать по этому';

  @override
  String get mapShowOnMap => 'Показать на карте';

  @override
  String get mapCoverageSquareInfo => 'Сведения о квадрате покрытия';

  @override
  String get mapSamplesLabel => 'Замеры: ';

  @override
  String get mapSuccessRateLabel => 'Успешность: ';

  @override
  String get mapReceivedLabel => 'Принято: ';

  @override
  String get mapLostLabel => 'Потеряно: ';

  @override
  String get mapRepeatersHeard => 'Слышны репитеры: ';

  @override
  String get mapRepeaterIds => 'ID репитеров: ';

  @override
  String get mapNoPingData => 'Нет данных пинга';

  @override
  String get mapNotAvailable => 'н/д';

  @override
  String mapNearbyRepeaters(int count) {
    return 'Ближайшие репитеры ($count)';
  }

  @override
  String mapUploadingTo(String site) {
    return 'Загрузка на $site...';
  }

  @override
  String get mapUploadingSamples => 'Загрузка замеров...';

  @override
  String mapUploadBatch(int current, int total) {
    return 'Пакет $current из $total';
  }

  @override
  String get mapUploadComplete => 'Загрузка завершена';

  @override
  String get mapUploadResults => 'Результаты загрузки';

  @override
  String mapUploadedToSites(int successCount, int total) {
    return 'Загружено на $successCount из $total сайтов';
  }

  @override
  String get mapUploadFallbackName => 'Загрузка';

  @override
  String mapUploadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get mapSelectWhichSitesToUpload =>
      'Выберите, на какие сайты загружать:';

  @override
  String get mapDeleteSite => 'Удалить сайт';

  @override
  String mapDeleteSiteConfirm(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get mapAddSite => 'Добавить сайт';

  @override
  String get mapUploadSitesUpdated => 'Сайты загрузки обновлены';

  @override
  String get mapEditUploadSite => 'Изменить сайт загрузки';

  @override
  String get mapSiteName => 'Имя сайта';

  @override
  String get mapApiUrl => 'URL API';

  @override
  String get mapAddUploadSite => 'Добавить сайт загрузки';

  @override
  String get mapSiteNameHint => 'напр., Моя карта';

  @override
  String get mapTileCacheNotInitialized => 'Кэш тайлов не инициализирован';

  @override
  String get mapDownloadTilesBlurb =>
      'Скачать тайлы карты для текущей области просмотра.';

  @override
  String mapMinZoom(String zoom) {
    return 'Мин. масштаб: $zoom';
  }

  @override
  String mapMaxZoom(String zoom) {
    return 'Макс. масштаб: $zoom';
  }

  @override
  String mapTilesEstimate(int count, String megabytes) {
    return '$count тайлов (~$megabytes МБ)';
  }

  @override
  String get mapLargeDownloadWarning =>
      'Большая загрузка — уменьшите область или диапазон масштаба';

  @override
  String get mapDownloadingTiles => 'Скачивание тайлов';

  @override
  String mapTilesProgress(int completed, int total) {
    return '$completed / $total тайлов';
  }

  @override
  String mapDownloadedTiles(int succeeded, int total) {
    return 'Скачано $succeeded/$total тайлов';
  }

  @override
  String mapDownloadCancelled(int count) {
    return 'Загрузка отменена (в кэше $count тайлов)';
  }

  @override
  String mapShareFailed(String error) {
    return 'Не удалось поделиться: $error';
  }

  @override
  String get mapCoverageShareSubject => 'Покрытие MeshCore Wardrive';

  @override
  String mapCoverageShareText(
    String sampleCount,
    String coverageCount,
    String successCount,
    String failCount,
    String successRate,
    String repeaterCount,
  ) {
    return 'Карта покрытия MeshCore Wardrive\n📍 $sampleCount замеров • $coverageCount областей покрытия\n✅ $successCount успешно • ❌ $failCount неудачно • $successRate%\n🔁 обнаружено репитеров: $repeaterCount';
  }

  @override
  String get mapNoRepeatersYet =>
      'Репитеры ещё не найдены — сначала проведите вардрайв!';

  @override
  String get mapFilterByRepeater => 'Фильтр по репитеру';

  @override
  String mapShowingCoverageFrom(String id) {
    return 'Показано покрытие от $id';
  }

  @override
  String get mapRepeaterFilterCleared => 'Фильтр репитера сброшен';

  @override
  String get mapClearFilter => 'Сбросить фильтр';

  @override
  String get mapNoCoverageYet =>
      'Данных покрытия ещё нет — сначала проведите вардрайв!';

  @override
  String get mapNoCoverageGaps =>
      'Провалов покрытия нет! Во всех областях успешность >30%.';

  @override
  String mapCoverageGaps(int count) {
    return 'Провалы покрытия ($count)';
  }

  @override
  String mapGapSuccessRate(String rate) {
    return 'Успешность $rate%';
  }

  @override
  String mapGapSubtitle(String coords, String received, String lost) {
    return '$coords\nпринято $received / потеряно $lost';
  }

  @override
  String get mapDownloadFrom => 'Скачать с';

  @override
  String get mapDownloadingCoverage => 'Скачивание данных покрытия...';

  @override
  String mapDownloadedCoverageCells(int count) {
    return 'Скачано ячеек покрытия: $count';
  }

  @override
  String get mapLoadedCachedCoverage =>
      'Загружено кэшированное покрытие (офлайн)';

  @override
  String mapDownloadFailed(String error) {
    return 'Ошибка скачивания: $error';
  }

  @override
  String get mapUnknownError => 'неизвестная ошибка';

  @override
  String mapCommunitySuccessRate(String rate) {
    return 'Успешность: $rate%';
  }

  @override
  String get mapRepeatersHeader => 'Репитеры:';

  @override
  String mapLastUpdate(String timestamp) {
    return 'Последнее обновление: $timestamp';
  }

  @override
  String mapAppVersionLabel(String version) {
    return 'Версия приложения: $version';
  }

  @override
  String mapApproxRadioPositionUncertainty(String uncertainty) {
    return 'Приблизительная радиопозиция, погрешность $uncertainty';
  }

  @override
  String mapApproxRadioPositionSnack(int count, String uncertainty) {
    return 'Приблизительная радиопозиция · $count репитеров · ±$uncertainty';
  }

  @override
  String get mapCurrentWifiLocation => 'Текущая Wi-Fi-позиция от beaconDB';

  @override
  String get mapCurrentFusedLocation =>
      'Текущая объединённая геолокация Android';

  @override
  String mapPositionHeadingSemantics(String positionLabel, String degrees) {
    return '$positionLabel, курс $degrees градусов';
  }
}

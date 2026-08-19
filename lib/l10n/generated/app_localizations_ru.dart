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
}

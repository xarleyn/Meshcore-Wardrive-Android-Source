import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';

/// Tropospheric ducting forecast viewer using dxinfocentre.com forecast maps.
class DuctingForecastScreen extends StatefulWidget {
  const DuctingForecastScreen({super.key});

  @override
  State<DuctingForecastScreen> createState() => _DuctingForecastScreenState();
}

class _DuctingForecastScreenState extends State<DuctingForecastScreen> {
  static const _regionKey = 'ducting_forecast_region';

  static const List<String> _regionCodes = [
    'wam',
    'eam',
    'enp',
    'esp',
    'car',
    'nsa',
    'sam',
    'sat',
    'nat',
    'ent',
    'nwe',
    'eur',
    'eeu',
    'afi',
    'mid',
    'nca',
    'ino',
    'sea',
    'eas',
    'nea',
    'aus',
    'oce',
    'wnp',
  ];

  // 3h intervals for first 36h, then 6h intervals to 138h
  static const List<int> _forecastHours = [
    6,
    9,
    12,
    15,
    18,
    21,
    24,
    27,
    30,
    33,
    36,
    42,
    48,
    54,
    60,
    66,
    72,
    78,
    84,
    90,
    96,
    102,
    108,
    114,
    120,
    126,
    132,
    138,
  ];

  String _region = 'wam';
  int _currentIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  Future<void> _loadRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_regionKey);
    if (saved != null && _regionCodes.contains(saved)) {
      setState(() => _region = saved);
    }
  }

  Future<void> _setRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region);
    setState(() {
      _region = region;
      _currentIndex = 0;
    });
  }

  String get _currentImageUrl {
    final hours = _forecastHours[_currentIndex].toString().padLeft(3, '0');
    return 'https://www.dxinfocentre.com/tr_map/fcst/$_region$hours.png';
  }

  String _timeLabel(AppLocalizations l10n) {
    final hours = _forecastHours[_currentIndex];
    if (hours < 24) return l10n.ductingTimeHours(hours);
    final days = hours ~/ 24;
    final rem = hours % 24;
    return rem == 0
        ? l10n.ductingTimeDays(days)
        : l10n.ductingTimeDaysHours(days, rem);
  }

  String _regionName(AppLocalizations l10n, String code) {
    switch (code) {
      case 'wam':
        return l10n.ductingRegionWam;
      case 'eam':
        return l10n.ductingRegionEam;
      case 'enp':
        return l10n.ductingRegionEnp;
      case 'esp':
        return l10n.ductingRegionEsp;
      case 'car':
        return l10n.ductingRegionCar;
      case 'nsa':
        return l10n.ductingRegionNsa;
      case 'sam':
        return l10n.ductingRegionSam;
      case 'sat':
        return l10n.ductingRegionSat;
      case 'nat':
        return l10n.ductingRegionNat;
      case 'ent':
        return l10n.ductingRegionEnt;
      case 'nwe':
        return l10n.ductingRegionNwe;
      case 'eur':
        return l10n.ductingRegionEur;
      case 'eeu':
        return l10n.ductingRegionEeu;
      case 'afi':
        return l10n.ductingRegionAfi;
      case 'mid':
        return l10n.ductingRegionMid;
      case 'nca':
        return l10n.ductingRegionNca;
      case 'ino':
        return l10n.ductingRegionIno;
      case 'sea':
        return l10n.ductingRegionSea;
      case 'eas':
        return l10n.ductingRegionEas;
      case 'nea':
        return l10n.ductingRegionNea;
      case 'aus':
        return l10n.ductingRegionAus;
      case 'oce':
        return l10n.ductingRegionOce;
      case 'wnp':
        return l10n.ductingRegionWnp;
      default:
        return code;
    }
  }

  void _play() {
    setState(() => _isPlaying = true);
    _animate();
  }

  void _animate() async {
    while (_isPlaying && _currentIndex < _forecastHours.length - 1) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isPlaying || !mounted) return;
      setState(() => _currentIndex++);
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  void _stop() {
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ductingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: l10n.ductingOpenInBrowser,
            onPressed: () {
              final page = _region == 'eam' ? 'tropo' : 'tropo_$_region';
              final url = Uri.parse('https://dxinfocentre.com/$page.html');
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Region selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: InputDecoration(
                labelText: l10n.ductingRegion,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              isExpanded: true,
              items: _regionCodes
                  .map(
                    (code) => DropdownMenuItem(
                      value: code,
                      child: Text(
                        _regionName(l10n, code),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? _setRegion(v) : null,
            ),
          ),

          // Forecast image (pinch to zoom)
          Expanded(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                _currentImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, error, stack) => Center(
                  child: Text(
                    l10n.ductingFailedToLoad,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // Time slider + playback controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _timeLabel(l10n),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.ductingFrameIndex(
                        _currentIndex + 1,
                        _forecastHours.length,
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Slider(
                  value: _currentIndex.toDouble(),
                  min: 0,
                  max: (_forecastHours.length - 1).toDouble(),
                  divisions: _forecastHours.length - 1,
                  onChanged: (v) {
                    _stop();
                    setState(() => _currentIndex = v.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: _currentIndex > 0
                          ? () {
                              _stop();
                              setState(() => _currentIndex = 0);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentIndex > 0
                          ? () {
                              _stop();
                              setState(() => _currentIndex--);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 36,
                      onPressed: _isPlaying ? _stop : _play,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentIndex < _forecastHours.length - 1
                          ? () {
                              _stop();
                              setState(() => _currentIndex++);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: _currentIndex < _forecastHours.length - 1
                          ? () {
                              _stop();
                              setState(
                                () => _currentIndex = _forecastHours.length - 1,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(const Color(0xFF00AA00), l10n.ductingLegendNone),
                _legendDot(Colors.yellow, l10n.ductingLegendMarginal),
                _legendDot(Colors.orange, l10n.ductingLegendModerate),
                _legendDot(Colors.red, l10n.ductingLegendHigh),
                _legendDot(Colors.purple, l10n.ductingLegendExtreme),
              ],
            ),
          ),

          // Attribution
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.ductingAttribution,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

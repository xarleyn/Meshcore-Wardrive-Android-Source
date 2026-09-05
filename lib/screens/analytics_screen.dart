import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geohash_plus/geohash_plus.dart' as geohash;
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/aggregation_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/distance_units.dart';
import '../utils/geohash_utils.dart';
import '../l10n/generated/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Sample> samples;
  final int coveragePrecision;
  final LatLng? currentPosition;

  const AnalyticsScreen({
    super.key,
    required this.samples,
    required this.coveragePrecision,
    this.currentPosition,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAnalytics)),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _CoverageScoreTab(
            samples: widget.samples,
            coveragePrecision: widget.coveragePrecision,
          ),
          _TimeOfDayTab(samples: widget.samples),
          _CoverageGoalTab(
            samples: widget.samples,
            coveragePrecision: widget.coveragePrecision,
            currentPosition: widget.currentPosition,
          ),
          _CoverageComparisonTab(coveragePrecision: widget.coveragePrecision),
          _RepeaterReliabilityTab(samples: widget.samples),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.star),
            label: l10n.analyticsTabScore,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.schedule),
            label: l10n.analyticsTabTime,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.flag),
            label: l10n.analyticsTabGoals,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.compare_arrows),
            label: l10n.analyticsTabCompare,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.cell_tower),
            label: l10n.analyticsTabRepeaters,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 0: Coverage Score
// =============================================================================

class _CoverageScoreTab extends StatelessWidget {
  final List<Sample> samples;
  final int coveragePrecision;
  const _CoverageScoreTab({
    required this.samples,
    required this.coveragePrecision,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pingSamples = samples.where((s) => s.pingSuccess != null).toList();
    if (pingSamples.isEmpty) {
      return Center(
        child: Text(l10n.analyticsNoPingData, textAlign: TextAlign.center),
      );
    }

    // Group by coverage cell
    final Map<String, List<Sample>> cells = {};
    for (final s in pingSamples) {
      final key = GeohashUtils.coverageKey(
        s.position.latitude,
        s.position.longitude,
        precision: coveragePrecision,
      );
      cells.putIfAbsent(key, () => []).add(s);
    }

    final uniqueCells = cells.length;
    final totalPings = pingSamples.length;
    final successes = pingSamples.where((s) => s.pingSuccess == true).length;
    final avgSuccessRate = totalPings > 0 ? successes / totalPings : 0.0;

    // Freshness factor: weighted average age of samples
    // Recent data is worth more
    double freshness = 0.0;
    for (final s in pingSamples) {
      final age = GeohashUtils.ageInDays(s.timestamp);
      if (age <= 1) {
        freshness += 1.0;
      } else if (age <= 7) {
        freshness += 0.8;
      } else if (age <= 30) {
        freshness += 0.5;
      } else {
        freshness += 0.2;
      }
    }
    freshness = totalPings > 0 ? freshness / totalPings : 0.0;

    // Score = uniqueCells × avgSuccessRate × freshness
    final score = (uniqueCells * avgSuccessRate * freshness).round();

    // Unique repeaters
    final repeaterIds = <String>{};
    for (final s in pingSamples) {
      if (s.path != null && s.path!.isNotEmpty) repeaterIds.add(s.path!);
    }

    // Grade
    String grade;
    Color gradeColor;
    if (score >= 500) {
      grade = 'S';
      gradeColor = Colors.purple;
    } else if (score >= 200) {
      grade = 'A';
      gradeColor = Colors.green;
    } else if (score >= 100) {
      grade = 'B';
      gradeColor = Colors.lightGreen;
    } else if (score >= 50) {
      grade = 'C';
      gradeColor = Colors.orange;
    } else {
      grade = 'D';
      gradeColor = Colors.red;
    }

    final shareText = l10n.analyticsShareText(
      '$score',
      grade,
      '$uniqueCells',
      (avgSuccessRate * 100).toStringAsFixed(0),
      (freshness * 100).toStringAsFixed(0),
      '${repeaterIds.length}',
      '$totalPings',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Big score display
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.analyticsCoverageScore,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _scoreStat(l10n.analyticsStatCells, '$uniqueCells'),
                      _scoreStat(
                        l10n.analyticsStatSuccess,
                        '${(avgSuccessRate * 100).toStringAsFixed(0)}%',
                      ),
                      _scoreStat(
                        l10n.analyticsStatFresh,
                        '${(freshness * 100).toStringAsFixed(0)}%',
                      ),
                      _scoreStat(
                        l10n.analyticsStatRepeaters,
                        '${repeaterIds.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Formula explanation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analyticsHowCalculated,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.analyticsScoreFormula,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.analyticsScoreBreakdown(
                      '$uniqueCells',
                      avgSuccessRate.toStringAsFixed(2),
                      freshness.toStringAsFixed(2),
                      '$score',
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.analyticsFreshnessLegend,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                SharePlus.instance.share(ShareParams(text: shareText)),
            icon: const Icon(Icons.share, size: 18),
            label: Text(l10n.analyticsShareScore),
          ),
        ],
      ),
    );
  }

  Widget _scoreStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// =============================================================================
// TAB 1: Time-of-Day Breakdown
// =============================================================================

class _TimeOfDayTab extends StatelessWidget {
  final List<Sample> samples;
  const _TimeOfDayTab({required this.samples});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pingSamples = samples.where((s) => s.pingSuccess != null).toList();

    if (pingSamples.isEmpty) {
      return Center(
        child: Text(l10n.analyticsNoPingData, textAlign: TextAlign.center),
      );
    }

    // Group by hour
    final Map<int, List<Sample>> byHour = {};
    for (int h = 0; h < 24; h++) {
      byHour[h] = [];
    }
    for (final s in pingSamples) {
      byHour[s.timestamp.hour]!.add(s);
    }

    // Calculate success rate per hour
    final rates = <int, double>{};
    final counts = <int, int>{};
    for (int h = 0; h < 24; h++) {
      final hourSamples = byHour[h]!;
      counts[h] = hourSamples.length;
      if (hourSamples.isEmpty) {
        rates[h] = -1; // No data
      } else {
        final successes = hourSamples
            .where((s) => s.pingSuccess == true)
            .length;
        rates[h] = successes / hourSamples.length;
      }
    }

    // Find best/worst hours (with data)
    final validHours = rates.entries.where((e) => e.value >= 0).toList();
    validHours.sort((a, b) => b.value.compareTo(a.value));
    final bestHour = validHours.isNotEmpty ? validHours.first.key : null;
    final worstHour = validHours.isNotEmpty ? validHours.last.key : null;

    // Period breakdown
    final periods = {
      l10n.analyticsPeriodNight: _periodRate(pingSamples, 0, 6),
      l10n.analyticsPeriodMorning: _periodRate(pingSamples, 6, 12),
      l10n.analyticsPeriodAfternoon: _periodRate(pingSamples, 12, 18),
      l10n.analyticsPeriodEvening: _periodRate(pingSamples, 18, 24),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.analyticsSuccessRateByHour,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.analyticsPingsAnalyzed(pingSamples.length),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = group.x;
                      final rate = rates[h]!;
                      final count = counts[h]!;
                      if (rate < 0) return null;
                      return BarTooltipItem(
                        l10n.analyticsHourTooltip(
                          '${h.toString().padLeft(2, '0')}:00',
                          (rate * 100).toStringAsFixed(0),
                          l10n.analyticsPingsCount(count),
                        ),
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                      interval: 0.25,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 3 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                ),
                barGroups: List.generate(24, (h) {
                  final rate = rates[h]!;
                  final hasData = rate >= 0;
                  return BarChartGroupData(
                    x: h,
                    barRods: [
                      BarChartRodData(
                        toY: hasData ? rate : 0,
                        color: !hasData
                            ? Colors.grey.withValues(alpha: 0.2)
                            : rate > 0.7
                            ? Colors.green
                            : rate > 0.3
                            ? Colors.orange
                            : Colors.red,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Summary
          if (bestHour != null) ...[
            Text(
              l10n.analyticsSummary,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _summaryRow(
              l10n.analyticsBestHour,
              l10n.analyticsHourValue(
                bestHour.toString().padLeft(2, '0'),
                (rates[bestHour]! * 100).toStringAsFixed(0),
              ),
              Colors.green,
            ),
            _summaryRow(
              l10n.analyticsWorstHour,
              l10n.analyticsHourValue(
                worstHour.toString().padLeft(2, '0'),
                (rates[worstHour]! * 100).toStringAsFixed(0),
              ),
              Colors.red,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.analyticsByPeriod,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...periods.entries.map((e) {
            final rate = e.value;
            final label = rate != null
                ? '${(rate * 100).toStringAsFixed(0)}%'
                : l10n.analyticsNoData;
            final color = rate == null
                ? Colors.grey
                : rate > 0.7
                ? Colors.green
                : rate > 0.3
                ? Colors.orange
                : Colors.red;
            return _summaryRow(e.key, label, color);
          }),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double? _periodRate(List<Sample> samples, int startHour, int endHour) {
    final period = samples
        .where(
          (s) => s.timestamp.hour >= startHour && s.timestamp.hour < endHour,
        )
        .toList();
    if (period.isEmpty) return null;
    final successes = period.where((s) => s.pingSuccess == true).length;
    return successes / period.length;
  }
}

// =============================================================================
// TAB 2: Coverage Goal Tracker
// =============================================================================

class _CoverageGoalTab extends StatefulWidget {
  final List<Sample> samples;
  final int coveragePrecision;
  final LatLng? currentPosition;

  const _CoverageGoalTab({
    required this.samples,
    required this.coveragePrecision,
    this.currentPosition,
  });

  @override
  State<_CoverageGoalTab> createState() => _CoverageGoalTabState();
}

class _CoverageGoalTabState extends State<_CoverageGoalTab> {
  final SettingsService _settings = SettingsService();
  double? _goalLat;
  double? _goalLon;
  double _goalRadiusMeters = 8047.0; // 5 miles
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final lat = await _settings.getGoalCenterLat();
    final lon = await _settings.getGoalCenterLon();
    final radius = await _settings.getGoalRadiusMeters();
    setState(() {
      _goalLat = lat;
      _goalLon = lon;
      _goalRadiusMeters = radius;
      _loading = false;
    });
  }

  bool get _hasGoal => _goalLat != null && _goalLon != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (!_hasGoal) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.analyticsNoCoverageGoal,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analyticsSetGoalHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _setGoal,
                icon: const Icon(Icons.add_location),
                label: Text(l10n.analyticsSetGoalArea),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate goal progress
    final goalResult = _calculateGoalProgress();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.analyticsCoverageGoal,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: _setGoal, child: Text(l10n.analyticsEdit)),
              TextButton(
                onPressed: () async {
                  await _settings.clearGoal();
                  setState(() {
                    _goalLat = null;
                    _goalLon = null;
                  });
                },
                child: Text(
                  l10n.settingsClear,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          Text(
            l10n.analyticsGoalCenterRadius(
              _goalLat!.toStringAsFixed(4),
              _goalLon!.toStringAsFixed(4),
              _formatRadius(l10n, _goalRadiusMeters),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Progress ring
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: goalResult.totalCells > 0
                          ? goalResult.coveredCells / goalResult.totalCells
                          : 0,
                      strokeWidth: 14,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goalResult.coveragePercent > 70
                            ? Colors.green
                            : goalResult.coveragePercent > 30
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${goalResult.coveragePercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.analyticsCovered,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          _goalStatRow(
            l10n.analyticsTotalCellsInArea,
            '${goalResult.totalCells}',
          ),
          _goalStatRow(
            l10n.analyticsCoveredAboveZero,
            '${goalResult.coveredCells}',
            Colors.green,
          ),
          _goalStatRow(
            l10n.analyticsPartialBelow30,
            '${goalResult.partialCells}',
            Colors.orange,
          ),
          _goalStatRow(
            l10n.analyticsUncovered,
            '${goalResult.uncoveredCells}',
            Colors.red,
          ),
          _goalStatRow(l10n.analyticsPingsInArea, '${goalResult.pingsInArea}'),
        ],
      ),
    );
  }

  Widget _goalStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  _GoalProgress _calculateGoalProgress() {
    final center = LatLng(_goalLat!, _goalLon!);
    const distance = Distance();

    // Generate all geohash cells that fit within the goal radius
    // Strategy: scan a grid of points within the bounding box, collect unique geohashes
    final Set<String> cellsInArea = {};

    // Calculate bounding box
    final north = distance.offset(center, _goalRadiusMeters, 0);
    final south = distance.offset(center, _goalRadiusMeters, 180);
    final east = distance.offset(center, _goalRadiusMeters, 90);
    final west = distance.offset(center, _goalRadiusMeters, 270);

    // Step size based on precision (approximate cell size in degrees)
    final stepDeg = GeohashUtils.latitudeStepDegrees(widget.coveragePrecision);

    for (double lat = south.latitude; lat <= north.latitude; lat += stepDeg) {
      for (double lon = west.longitude; lon <= east.longitude; lon += stepDeg) {
        final point = LatLng(lat, lon);
        final dist = distance.as(LengthUnit.Meter, center, point);
        if (dist <= _goalRadiusMeters) {
          final hash = geohash.GeoHash.encode(
            lat,
            lon,
            precision: widget.coveragePrecision,
          ).hash;
          cellsInArea.add(hash);
        }
      }
    }

    if (cellsInArea.isEmpty) {
      return _GoalProgress(
        totalCells: 0,
        coveredCells: 0,
        partialCells: 0,
        uncoveredCells: 0,
        pingsInArea: 0,
      );
    }

    // Build coverage for current samples
    final result = AggregationService.buildIndexes(
      widget.samples,
      [],
      coveragePrecision: widget.coveragePrecision,
    );
    final coverageMap = {for (final c in result.coverages) c.id: c};

    int covered = 0;
    int partial = 0;
    int pingsInArea = 0;

    for (final cellHash in cellsInArea) {
      final cov = coverageMap[cellHash];
      if (cov != null) {
        final total = cov.received + cov.lost;
        if (total > 0) {
          pingsInArea += total.round();
          final rate = cov.received / total;
          if (rate >= 0.3) {
            covered++;
          } else {
            partial++;
          }
        }
      }
    }

    final uncovered = cellsInArea.length - covered - partial;

    return _GoalProgress(
      totalCells: cellsInArea.length,
      coveredCells: covered,
      partialCells: partial,
      uncoveredCells: uncovered,
      pingsInArea: pingsInArea,
    );
  }

  String _formatRadius(AppLocalizations l10n, double meters) {
    if (meters >= DistanceUnits.metersPerMile) {
      return l10n.analyticsRadiusMiles(
        (meters / DistanceUnits.metersPerMile).toStringAsFixed(1),
      );
    }
    return l10n.analyticsRadiusMeters(meters.toStringAsFixed(0));
  }

  Future<void> _setGoal() async {
    double selectedRadius = _goalRadiusMeters;
    final useCurrentPos = widget.currentPosition != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final radiusOptions = [
          {'label': l10n.analyticsMile1, 'meters': 1609.34},
          {'label': l10n.analyticsMiles5, 'meters': 8046.72},
          {'label': l10n.analyticsMiles10, 'meters': 16093.4},
          {'label': l10n.analyticsMiles25, 'meters': 40233.6},
        ];
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.analyticsSetCoverageGoal),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useCurrentPos)
                  Text(
                    l10n.analyticsCenterCurrentGps,
                    style: const TextStyle(fontSize: 13),
                  )
                else
                  Text(
                    l10n.analyticsCenterCoords(
                      (_goalLat ?? 0).toStringAsFixed(4),
                      (_goalLon ?? 0).toStringAsFixed(4),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.analyticsRadiusLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioGroup<double>(
                  groupValue: selectedRadius,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRadius = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final opt in radiusOptions)
                        RadioListTile<double>(
                          title: Text(opt['label'] as String),
                          value: opt['meters'] as double,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.settingsCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.analyticsSetGoal),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      final lat = useCurrentPos
          ? widget.currentPosition!.latitude
          : (_goalLat ?? 0);
      final lon = useCurrentPos
          ? widget.currentPosition!.longitude
          : (_goalLon ?? 0);
      await _settings.setGoal(lat, lon, selectedRadius);
      setState(() {
        _goalLat = lat;
        _goalLon = lon;
        _goalRadiusMeters = selectedRadius;
      });
    }
  }
}

class _GoalProgress {
  final int totalCells;
  final int coveredCells;
  final int partialCells;
  final int uncoveredCells;
  final int pingsInArea;

  double get coveragePercent =>
      totalCells > 0 ? (coveredCells / totalCells) * 100 : 0;

  _GoalProgress({
    required this.totalCells,
    required this.coveredCells,
    required this.partialCells,
    required this.uncoveredCells,
    required this.pingsInArea,
  });
}

// =============================================================================
// TAB 3: Coverage Comparison
// =============================================================================

class _CoverageComparisonTab extends StatefulWidget {
  final int coveragePrecision;
  const _CoverageComparisonTab({required this.coveragePrecision});

  @override
  State<_CoverageComparisonTab> createState() => _CoverageComparisonTabState();
}

class _CoverageComparisonTabState extends State<_CoverageComparisonTab> {
  final DatabaseService _dbService = DatabaseService();
  List<WSession> _sessions = [];
  WSession? _sessionA;
  WSession? _sessionB;
  _ComparisonResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _dbService.getAllSessions();
    setState(() {
      _sessions = sessions
          .where((s) => s.endTime != null && s.pingCount > 0)
          .toList();
      _loading = false;
    });
  }

  Future<void> _compare() async {
    if (_sessionA == null || _sessionB == null) return;

    setState(() => _loading = true);

    // Load samples for each session
    final samplesA = await _dbService.getSamplesByTimeRange(
      _sessionA!.startTime,
      _sessionA!.endTime!,
    );
    final samplesB = await _dbService.getSamplesByTimeRange(
      _sessionB!.startTime,
      _sessionB!.endTime!,
    );

    // Aggregate each
    final resultA = AggregationService.buildIndexes(
      samplesA,
      [],
      coveragePrecision: widget.coveragePrecision,
    );
    final resultB = AggregationService.buildIndexes(
      samplesB,
      [],
      coveragePrecision: widget.coveragePrecision,
    );

    final mapA = {for (final c in resultA.coverages) c.id: c};
    final mapB = {for (final c in resultB.coverages) c.id: c};

    final allKeys = {...mapA.keys, ...mapB.keys};

    int newCells = 0, lostCells = 0, improved = 0, degraded = 0, unchanged = 0;

    for (final key in allKeys) {
      final a = mapA[key];
      final b = mapB[key];

      if (a == null && b != null) {
        newCells++;
      } else if (a != null && b == null) {
        lostCells++;
      } else if (a != null && b != null) {
        final rateA = (a.received + a.lost) > 0
            ? a.received / (a.received + a.lost)
            : 0.0;
        final rateB = (b.received + b.lost) > 0
            ? b.received / (b.received + b.lost)
            : 0.0;
        if (rateB - rateA > 0.1) {
          improved++;
        } else if (rateA - rateB > 0.1) {
          degraded++;
        } else {
          unchanged++;
        }
      }
    }

    // Stats
    final pingsA = samplesA.where((s) => s.pingSuccess != null).toList();
    final pingsB = samplesB.where((s) => s.pingSuccess != null).toList();
    final successA = pingsA.where((s) => s.pingSuccess == true).length;
    final successB = pingsB.where((s) => s.pingSuccess == true).length;
    final rateA = pingsA.isNotEmpty ? successA / pingsA.length : 0.0;
    final rateB = pingsB.isNotEmpty ? successB / pingsB.length : 0.0;

    final repeatersA = <String>{};
    final repeatersB = <String>{};
    for (final s in samplesA) {
      if (s.path != null) repeatersA.add(s.path!);
    }
    for (final s in samplesB) {
      if (s.path != null) repeatersB.add(s.path!);
    }

    setState(() {
      _result = _ComparisonResult(
        samplesA: samplesA.length,
        samplesB: samplesB.length,
        rateA: rateA,
        rateB: rateB,
        repeatersA: repeatersA.length,
        repeatersB: repeatersB.length,
        distanceA: _sessionA!.distanceMeters,
        distanceB: _sessionB!.distanceMeters,
        newCells: newCells,
        lostCells: lostCells,
        improved: improved,
        degraded: degraded,
        unchanged: unchanged,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_sessions.length < 2) {
      return Center(
        child: Text(
          l10n.analyticsNeedTwoSessions,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.analyticsCompareSessions,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _sessionPicker(
            l10n.analyticsSessionABaseline,
            _sessionA,
            (s) => setState(() {
              _sessionA = s;
              _result = null;
            }),
          ),
          const SizedBox(height: 8),
          _sessionPicker(
            l10n.analyticsSessionBCompare,
            _sessionB,
            (s) => setState(() {
              _sessionB = s;
              _result = null;
            }),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed:
                  _sessionA != null &&
                      _sessionB != null &&
                      _sessionA!.id != _sessionB!.id
                  ? _compare
                  : null,
              icon: const Icon(Icons.compare_arrows),
              label: Text(l10n.analyticsTabCompare),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            // Side-by-side stats
            _compRow(
              l10n.analyticsSamples,
              '${_result!.samplesA}',
              '${_result!.samplesB}',
            ),
            _compRow(
              l10n.analyticsSuccessRate,
              '${(_result!.rateA * 100).toStringAsFixed(0)}%',
              '${(_result!.rateB * 100).toStringAsFixed(0)}%',
              delta: _result!.rateB - _result!.rateA,
            ),
            _compRow(
              l10n.analyticsStatRepeaters,
              '${_result!.repeatersA}',
              '${_result!.repeatersB}',
              delta: (_result!.repeatersB - _result!.repeatersA).toDouble(),
            ),
            _compRow(
              l10n.analyticsDistance,
              l10n.analyticsDistanceMiles(
                (_result!.distanceA / DistanceUnits.metersPerMile)
                    .toStringAsFixed(1),
              ),
              l10n.analyticsDistanceMiles(
                (_result!.distanceB / DistanceUnits.metersPerMile)
                    .toStringAsFixed(1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.analyticsCoverageChanges,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _changeRow(
              l10n.analyticsNewCoverage,
              _result!.newCells,
              Colors.green,
            ),
            _changeRow(
              l10n.analyticsLostCoverage,
              _result!.lostCells,
              Colors.red,
            ),
            _changeRow(
              l10n.analyticsImproved,
              _result!.improved,
              Colors.lightGreen,
            ),
            _changeRow(
              l10n.analyticsDegraded,
              _result!.degraded,
              Colors.orange,
            ),
            _changeRow(
              l10n.analyticsUnchanged,
              _result!.unchanged,
              Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sessionPicker(
    String label,
    WSession? selected,
    void Function(WSession) onPicked,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.MMMd(locale).add_jm();
    return InkWell(
      onTap: () async {
        final picked = await showDialog<WSession>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(label),
            children: _sessions
                .map(
                  (s) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, s),
                    child: Text(
                      l10n.analyticsSessionOption(
                        fmt.format(s.startTime),
                        l10n.analyticsPingsCount(s.pingCount),
                        (s.successRate * 100).toStringAsFixed(0),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected != null
                    ? l10n.analyticsSessionSelected(
                        fmt.format(selected.startTime),
                        l10n.analyticsPingsCount(selected.pingCount),
                      )
                    : label,
                style: TextStyle(
                  color: selected != null ? null : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _compRow(String label, String valueA, String valueB, {double? delta}) {
    Widget? deltaWidget;
    if (delta != null && delta != 0) {
      final isPositive = delta > 0;
      deltaWidget = Text(
        isPositive ? '▲' : '▼',
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontSize: 12,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              valueA,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Text('→', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valueB,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (deltaWidget != null) ...[
                  const SizedBox(width: 4),
                  deltaWidget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _changeRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ComparisonResult {
  final int samplesA, samplesB;
  final double rateA, rateB;
  final int repeatersA, repeatersB;
  final double distanceA, distanceB;
  final int newCells, lostCells, improved, degraded, unchanged;

  _ComparisonResult({
    required this.samplesA,
    required this.samplesB,
    required this.rateA,
    required this.rateB,
    required this.repeatersA,
    required this.repeatersB,
    required this.distanceA,
    required this.distanceB,
    required this.newCells,
    required this.lostCells,
    required this.improved,
    required this.degraded,
    required this.unchanged,
  });
}

// =============================================================================
// TAB 4: Repeater Reliability Scores
// =============================================================================

class _RepeaterReliabilityTab extends StatefulWidget {
  final List<Sample> samples;
  const _RepeaterReliabilityTab({required this.samples});

  @override
  State<_RepeaterReliabilityTab> createState() =>
      _RepeaterReliabilityTabState();
}

class _RepeaterReliabilityTabState extends State<_RepeaterReliabilityTab> {
  String _sortBy = 'reliability'; // 'reliability', 'responseTime', 'pings'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Group samples by repeater (path)
    final Map<String, List<Sample>> byRepeater = {};
    for (final s in widget.samples) {
      if (s.pingSuccess != null && s.path != null && s.path!.isNotEmpty) {
        byRepeater.putIfAbsent(s.path!, () => []);
        byRepeater[s.path!]!.add(s);
      }
    }

    if (byRepeater.isEmpty) {
      return Center(
        child: Text(
          l10n.analyticsNoRepeaterData,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Compute stats per repeater
    final stats = byRepeater.entries
        .map((e) => _computeRepeaterStats(e.key, e.value))
        .toList();

    // Sort
    switch (_sortBy) {
      case 'responseTime':
        stats.sort(
          (a, b) =>
              (a.avgResponseMs ?? 99999).compareTo(b.avgResponseMs ?? 99999),
        );
        break;
      case 'pings':
        stats.sort((a, b) => b.totalPings.compareTo(a.totalPings));
        break;
      default: // reliability
        stats.sort((a, b) => b.responseRate.compareTo(a.responseRate));
    }

    return Column(
      children: [
        // Sort selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                l10n.analyticsRepeaterCount(stats.length),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(l10n.analyticsSort, style: const TextStyle(fontSize: 12)),
              DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                items: [
                  DropdownMenuItem(
                    value: 'reliability',
                    child: Text(
                      l10n.analyticsSortReliability,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'responseTime',
                    child: Text(
                      l10n.analyticsSortResponseTime,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pings',
                    child: Text(
                      l10n.analyticsSortPingCount,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _sortBy = v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stats.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) => _buildRepeaterCard(stats[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeaterCard(_RepeaterStats stats) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final displayId = stats.id.length > 8
        ? stats.id.substring(0, 8).toUpperCase()
        : stats.id.toUpperCase();

    Color rateColor;
    if (stats.responseRate > 0.7) {
      rateColor = Colors.green;
    } else if (stats.responseRate > 0.3) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }

    String trendIcon;
    Color trendColor;
    switch (stats.trend) {
      case 'improving':
        trendIcon = '▲';
        trendColor = Colors.green;
        break;
      case 'degrading':
        trendIcon = '▼';
        trendColor = Colors.red;
        break;
      default:
        trendIcon = '—';
        trendColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cell_tower, size: 18, color: rateColor),
                const SizedBox(width: 8),
                Text(
                  displayId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  trendIcon,
                  style: TextStyle(color: trendColor, fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(stats.responseRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rateColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat(l10n.analyticsMiniPings, '${stats.totalPings}'),
                _miniStat(
                  l10n.analyticsMiniAvgResponse,
                  stats.avgResponseMs != null
                      ? l10n.analyticsAvgResponseMs(
                          stats.avgResponseMs!.toStringAsFixed(0),
                        )
                      : '—',
                ),
                _miniStat(
                  l10n.analyticsMiniConsistency,
                  stats.consistencyScore != null
                      ? stats.consistencyScore!.toStringAsFixed(0)
                      : '—',
                ),
                _miniStat(
                  l10n.analyticsMiniTrend,
                  l10n.analyticsTrend(stats.trend),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.analyticsFirstLastSeen(
                DateFormat.MMMd(locale).format(stats.firstSeen),
                DateFormat.MMMd(locale).format(stats.lastSeen),
              ),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  _RepeaterStats _computeRepeaterStats(String id, List<Sample> samples) {
    final successes = samples.where((s) => s.pingSuccess == true).length;
    final totalPings = samples.length;
    final responseRate = totalPings > 0 ? successes / totalPings : 0.0;

    // Response times
    final responseTimes = samples
        .where((s) => s.responseTimeMs != null)
        .map((s) => s.responseTimeMs!.toDouble())
        .toList();

    double? avgResponse;
    double? stddev;
    if (responseTimes.isNotEmpty) {
      avgResponse =
          responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final variance =
          responseTimes
              .map((t) => (t - avgResponse!) * (t - avgResponse))
              .reduce((a, b) => a + b) /
          responseTimes.length;
      stddev = sqrt(variance);
    }

    // Trend: compare last 7 days vs prior 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final recent = samples
        .where((s) => s.timestamp.isAfter(sevenDaysAgo))
        .toList();
    final prior = samples
        .where(
          (s) =>
              s.timestamp.isAfter(fourteenDaysAgo) &&
              s.timestamp.isBefore(sevenDaysAgo),
        )
        .toList();

    String trend = 'stable';
    if (recent.length >= 3 && prior.length >= 3) {
      final recentRate =
          recent.where((s) => s.pingSuccess == true).length / recent.length;
      final priorRate =
          prior.where((s) => s.pingSuccess == true).length / prior.length;
      if (recentRate - priorRate > 0.1) {
        trend = 'improving';
      } else if (priorRate - recentRate > 0.1) {
        trend = 'degrading';
      }
    }

    // First/last seen
    samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstSeen = samples.first.timestamp;
    final lastSeen = samples.last.timestamp;

    return _RepeaterStats(
      id: id,
      totalPings: totalPings,
      responseRate: responseRate,
      avgResponseMs: avgResponse,
      consistencyScore: stddev,
      trend: trend,
      firstSeen: firstSeen,
      lastSeen: lastSeen,
    );
  }
}

class _RepeaterStats {
  final String id;
  final int totalPings;
  final double responseRate;
  final double? avgResponseMs;
  final double? consistencyScore; // stddev of response times
  final String trend; // 'improving', 'stable', 'degrading'
  final DateTime firstSeen;
  final DateTime lastSeen;

  _RepeaterStats({
    required this.id,
    required this.totalPings,
    required this.responseRate,
    this.avgResponseMs,
    this.consistencyScore,
    required this.trend,
    required this.firstSeen,
    required this.lastSeen,
  });
}

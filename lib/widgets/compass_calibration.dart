import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../utils/compass_calibration.dart';

class CompassCalibrationBanner extends StatelessWidget {
  const CompassCalibrationBanner({
    super.key,
    required this.onCalibrate,
    required this.onLater,
  });

  final VoidCallback onCalibrate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compass needs calibration',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Move the phone in a figure-8 if heading looks wrong.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onLater, child: const Text('Later')),
                FilledButton(
                  onPressed: onCalibrate,
                  child: const Text('Calibrate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showCompassCalibrationSheet(
  BuildContext context, {
  Stream<CompassEvent>? events,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CompassCalibrationSheet(events: events),
  );
}

class CompassCalibrationSheet extends StatefulWidget {
  const CompassCalibrationSheet({super.key, this.events});

  final Stream<CompassEvent>? events;

  @override
  State<CompassCalibrationSheet> createState() =>
      _CompassCalibrationSheetState();
}

class _CompassCalibrationSheetState extends State<CompassCalibrationSheet> {
  final CompassCalibrationSampler _sampler = CompassCalibrationSampler();
  StreamSubscription<CompassEvent>? _subscription;
  DateTime? _openedAt;
  bool _completing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    final events = widget.events ?? FlutterCompass.events;
    if (events != null) {
      _subscription = events.listen(_onEvent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onEvent(CompassEvent event) {
    if (!mounted || _completing) return;
    final heading = event.heading;
    if (heading != null && heading.isFinite) {
      _sampler.addHeading(heading);
    }

    final elapsed = DateTime.now().difference(_openedAt ?? DateTime.now());
    final reliable = CompassCalibrationPolicy.isReliable(event.accuracy);
    final movedEnough = _sampler.progress >= 0.15;
    final shouldComplete =
        _sampler.isComplete ||
        (reliable && (movedEnough || elapsed >= const Duration(seconds: 2)));

    setState(() {
      if (reliable && !_sampler.isComplete) {
        _statusMessage = 'Sensor accuracy looks good';
      } else if (_sampler.progress > 0) {
        _statusMessage = 'Keep drawing a figure-8';
      }
    });

    if (shouldComplete) {
      _complete();
    }
  }

  Future<void> _complete() async {
    if (_completing || !mounted) return;
    setState(() {
      _completing = true;
      _statusMessage = 'Calibration complete';
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completing ? 1.0 : _sampler.progress;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Calibrate compass',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Hold the phone and draw a figure-8 in the air until the bar fills.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 160, child: CompassFigureEight()),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Text(
              _statusMessage ?? 'Move the phone through a figure-8',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _completing
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassFigureEight extends StatefulWidget {
  const CompassFigureEight({super.key});

  @override
  State<CompassFigureEight> createState() => _CompassFigureEightState();
}

class _CompassFigureEightState extends State<CompassFigureEight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Figure-8 calibration motion',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _FigureEightPainter(
              t: _controller.value * math.pi * 2,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  _FigureEightPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static Offset _point(double angle, Size size) {
    final a = size.shortestSide * 0.38;
    final s = math.sin(angle);
    final denom = 1 + s * s;
    return Offset(
      size.width / 2 + a * math.cos(angle) / denom,
      size.height / 2 + a * s * math.cos(angle) / denom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final point = _point(i / 120 * math.pi * 2, size);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final tip = _point(t, size);
    canvas.drawCircle(tip, 10, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FigureEightPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

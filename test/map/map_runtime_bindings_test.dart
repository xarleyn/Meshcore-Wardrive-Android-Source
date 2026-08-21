import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/map_runtime_bindings.dart';

void main() {
  test('replacing a subscription detaches the previous stream', () async {
    final first = StreamController<int>();
    final second = StreamController<int>();
    final bindings = MapRuntimeBindings();
    final values = <int>[];

    bindings.bind(MapRuntimeSubscription.battery, first.stream, values.add);
    first.add(1);
    await Future<void>.delayed(Duration.zero);
    bindings.bind(MapRuntimeSubscription.battery, second.stream, values.add);
    first.add(2);
    second.add(3);
    await Future<void>.delayed(Duration.zero);

    expect(values, [1, 3]);
    bindings.dispose();
    await first.close();
    await second.close();
  });

  test('a keyed timer can reject duplicates and be replaced', () async {
    final bindings = MapRuntimeBindings();
    final values = <int>[];

    expect(
      bindings.scheduleTimer(
        MapRuntimeTimer.headingUpdate,
        Duration.zero,
        () => values.add(1),
        replace: false,
      ),
      isTrue,
    );
    expect(
      bindings.scheduleTimer(
        MapRuntimeTimer.headingUpdate,
        Duration.zero,
        () => values.add(2),
        replace: false,
      ),
      isFalse,
    );
    await Future<void>.delayed(Duration.zero);

    expect(values, [1]);
    bindings.dispose();
  });

  test('dispose prevents stream and timer callbacks', () async {
    final stream = StreamController<int>();
    final bindings = MapRuntimeBindings();
    final values = <int>[];
    bindings.bind(MapRuntimeSubscription.speed, stream.stream, values.add);
    bindings.scheduleTimer(
      MapRuntimeTimer.pingPulse,
      Duration.zero,
      () => values.add(2),
    );

    bindings.dispose();
    stream.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(values, isEmpty);
    await stream.close();
  });
}

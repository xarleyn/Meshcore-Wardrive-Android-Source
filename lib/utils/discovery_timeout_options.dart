class DiscoveryTimeoutOptions {
  const DiscoveryTimeoutOptions._();

  static const List<int> presets = [5, 10, 15, 20, 25, 30];

  static List<int> valuesFor(int current) {
    final values = <int>{...presets, current}.toList()..sort();
    return values;
  }

  static String labelFor(int seconds) => '${seconds}s';
}

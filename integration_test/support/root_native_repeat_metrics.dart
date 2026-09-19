/// Only the two explicitly supported device probe platforms.
enum RootRepeatPlatform { android, windows }

/// Returns a fresh, bounded projection only after all native/root facts validate.
Map<String, Object>? projectRootNativeRepeatMetrics({
  required String sourceCommit,
  required RootRepeatPlatform platform,
  required Object? metrics,
}) {
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit)) {
    throw ArgumentError('Invalid root native probe identity');
  }
  const orders = <String, List<Object>>{
    'nativeEntries': ['q0', 'q1', 'q0'],
    'nativeIndices': [0, 1, 2],
    'nativeCycles': [0, 0, 1],
    'rootEntries': ['q0', 'q1', 'q0'],
    'persistedEntries': ['q0', 'q1', 'q0'],
  };
  const facts = [
    'sameNativeBatch',
    'metadataAligned',
    'historyReplaced',
    'restoredWithoutPlayback',
    'disposed',
  ];
  bool exactList(Object? value, List<Object> expected) =>
      value is List<Object?> &&
      value.length == expected.length &&
      List.generate(expected.length, (i) => i).every(
        (i) =>
            value[i].runtimeType == expected[i].runtimeType &&
            value[i] == expected[i],
      );
  bool clockList(Object? value) =>
      value is List<Object?> &&
      value.length == 3 &&
      value.every((v) => v is int && v >= 100 && v <= 10000);
  bool boundedInt(Object? value, int min, int max) =>
      value is int && value >= min && value <= max;
  final valid =
      metrics is Map<String, Object?> &&
      metrics['sourceCommit'] == sourceCommit &&
      metrics['platform'] == platform.name &&
      orders.entries.every((e) => exactList(metrics[e.key], e.value)) &&
      facts.every((key) => metrics[key] == true) &&
      clockList(metrics['nativeProgressMs']) &&
      clockList(metrics['rootProgressMs']) &&
      boundedInt(metrics['historyCount'], 2, 2) &&
      metrics['completedEntry'] == 'q0' &&
      boundedInt(metrics['completedIndex'], 2, 2) &&
      boundedInt(metrics['completedCycle'], 1, 1) &&
      boundedInt(metrics['noRestartObservedMs'], 1000, 10000) &&
      boundedInt(metrics['restoreObservedMs'], 1000, 10000) &&
      metrics['restoredEntry'] == 'q0' &&
      metrics['acousticGapMeasured'] == false;
  if (!valid) return null;
  return {
    'sourceCommit': sourceCommit,
    'platform': platform.name,
    for (final e in orders.entries) e.key: List<Object>.of(e.value),
    for (final key in facts) key: true,
    for (final key in ['nativeProgressMs', 'rootProgressMs'])
      key: List<int>.from(metrics[key]! as List<Object?>),
    'historyCount': 2,
    'completedEntry': 'q0',
    'completedIndex': 2,
    'completedCycle': 1,
    'noRestartObservedMs': metrics['noRestartObservedMs']!,
    'restoreObservedMs': metrics['restoreObservedMs']!,
    'restoredEntry': 'q0',
    'acousticGapMeasured': false,
  };
}

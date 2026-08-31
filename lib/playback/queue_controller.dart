import 'package:flutter/foundation.dart';

/// Root-owned placeholder; queue entries/operations arrive with Phase 3 models.
final class QueueController extends ChangeNotifier {
  bool get isAvailable => false;
}

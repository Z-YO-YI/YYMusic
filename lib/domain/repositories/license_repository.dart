import '../models/software_license.dart';

/// Supplies complete bundled legal texts without exposing framework APIs to UI.
abstract interface class LicenseRepository {
  Future<List<SoftwareLicense>> load();
}

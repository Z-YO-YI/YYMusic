import '../app/app_data_services.dart';
import '../app/database_app_data_services.dart';
import '../app/layout_class.dart';
import '../data/database/database_connection.dart';
import 'dev_fixture.dart';

/// Explicit development-only data factory used by `main_dev.dart`.
/// It never opens the production database or platform credential storage.
Future<AppDataServices> createDevFixtureAppDataServices(
  YYPlatform platform,
) async {
  final database = openInMemoryDatabase();
  final services = await DatabaseAppDataServices.open(database);
  try {
    await DevFixtureSeeder(YYDevFixture()).seedEmpty(services);
    return services;
  } catch (_) {
    await services.dispose();
    rethrow;
  }
}

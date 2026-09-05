import 'package:flutter/widgets.dart';

import 'app/app_bootstrap.dart';
import 'app/production_audio.dart';
import 'dev_fixture/dev_fixture_app_data_services.dart';

void main() => runApp(
  const AppBootstrap(
    dataServicesFactory: createDevFixtureAppDataServices,
    audioEngineFactory: createUnavailableAudioEngine,
  ),
);

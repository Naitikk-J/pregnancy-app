import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Default (production) entrypoint.
///
/// Flavored entrypoints (`main_development.dart`, `main_staging.dart`) can call
/// `bootstrap()` with a different [AppConfig] once native flavors are set up.
Future<void> main() => bootstrap(config: AppConfig.production);

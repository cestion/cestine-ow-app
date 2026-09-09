// Re-exports only the providers required by WsController, avoiding a direct
// dependency on the full app provider barrel.
export '../../provider/auth_providers.dart' show authControllerProvider;
export '../../provider/realtime_providers.dart' show wsServiceProvider;

abstract class StoryTelemetry {
  void event(String name, {Map<String, Object?>? properties});
  void error(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  });
  void timing(
    String name,
    Duration duration, {
    Map<String, Object?>? properties,
  });
}

class _NoopTelemetry implements StoryTelemetry {
  const _NoopTelemetry();

  @override
  void event(String name, {Map<String, Object?>? properties}) {}

  @override
  void error(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) {}

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, Object?>? properties,
  }) {}
}

class StoryTelemetryRegistry {
  StoryTelemetryRegistry._();
  static StoryTelemetry _instance = const _NoopTelemetry();

  static StoryTelemetry get instance => _instance;

  static void set(StoryTelemetry telemetry) {
    _instance = telemetry;
  }

  static void reset() {
    _instance = const _NoopTelemetry();
  }
}

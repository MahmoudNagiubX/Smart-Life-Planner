import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/monitoring/crash_monitoring_service.dart';

void main() {
  testWidgets('crash monitoring initializes and records debug errors', (
    tester,
  ) async {
    await CrashMonitoringService.initialize();

    expect(CrashMonitoringService.isInitialized, isTrue);

    CrashMonitoringService.recordError(
      StateError('simulated test error'),
      StackTrace.current,
      reason: 'test simulation',
    );
  });
}

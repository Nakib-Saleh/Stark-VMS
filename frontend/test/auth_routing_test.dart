import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:stark_vms/auth/auth_controller.dart';
import 'package:stark_vms/main.dart';
import 'package:stark_vms/models/page_response.dart';
import 'package:stark_vms/models/vehicle.dart';
import 'package:stark_vms/providers/vehicle_providers.dart';
import 'package:stark_vms/repositories/vehicle_repository.dart';
import 'package:stark_vms/router.dart';
import 'package:stark_vms/screens/login_screen.dart';

/// The sign-in boundary in the app. The server is the real lock (backend AuthIntegrationTest);
/// these check the app sends people to the right place and never off-site.
class _EmptyRepository implements VehicleRepository {
  @override
  Future<PageResponse<Vehicle>> getVehicles({int page = 0, int size = 10}) async =>
      const PageResponse<Vehicle>(content: [], hasNext: false, totalElements: 0);
  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) => throw UnimplementedError();
  @override
  Future<void> deleteVehicle(int id) => throw UnimplementedError();
  @override
  Future<Vehicle> getVehicleById(int id) => throw UnimplementedError();
  @override
  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) => throw UnimplementedError();
}

void main() {
  late Box<dynamic> box;

  late Directory dir;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('stark_vms_test');
    Hive.init(dir.path);
  });
  // A fresh box per test. Not deleted per test: a write the app starts inside the widget test's
  // fake clock can't finish after the test ends, and Hive queues a delete behind it forever.
  setUp(() async => box = await Hive.openBox<dynamic>('session_${DateTime.now().microsecondsSinceEpoch}'));
  tearDownAll(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may still hold the box files open; the OS temp folder is cleaned up eventually.
    }
  });

  Future<GoRouter> start(WidgetTester tester) async {
    // No ambient animation in tests (the landing page's plate timer respects this).
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1; // desktop width, as the frame's side menu expects
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      sessionBoxProvider.overrideWithValue(box),
      vehicleRepositoryProvider.overrideWithValue(_EmptyRepository()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const StarkVmsApp()));
    await tester.pumpAndSettle();
    return container.read(routerProvider);
  }

  String location(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('signed out: opening /vehicles goes to sign-in and remembers where you were going', (tester) async {
    final router = await start(tester);
    router.go('/vehicles');
    await tester.pumpAndSettle();

    expect(location(router), '/login?next=%2Fvehicles');
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('signed in: /vehicles opens inside the app frame, and /login goes back to the app', (tester) async {
    // Real disk I/O must run outside the widget test's fake clock.
    await tester.runAsync(() => box.putAll({
      'token': 'test-token',
      'username': 'admin',
      'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    }));
    final router = await start(tester);

    router.go('/vehicles');
    await tester.pumpAndSettle();
    expect(location(router), '/vehicles');
    expect(find.text('Sign out'), findsOneWidget);

    router.go('/login');
    await tester.pumpAndSettle();
    expect(location(router), '/vehicles');
  });

  testWidgets('an expired saved session counts as signed out and says why', (tester) async {
    // Real disk I/O must run outside the widget test's fake clock.
    await tester.runAsync(() => box.putAll({
      'token': 'old-token',
      'username': 'admin',
      'expiresAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
    }));
    final router = await start(tester);
    router.go('/vehicles');
    await tester.pumpAndSettle();

    expect(location(router), startsWith('/login'));
    expect(find.text(AuthController.sessionEndedNotice), findsOneWidget);
    expect(box.get('token'), isNull);
  });

  test('after sign-in the app only returns to its own pages, never another site', () {
    expect(safeNext('/vehicles'), '/vehicles');
    expect(safeNext('/vehicles?page=2'), '/vehicles?page=2');
    expect(safeNext(null), '/vehicles');
    expect(safeNext('https://evil.example'), '/vehicles');
    expect(safeNext('//evil.example/path'), '/vehicles');
    expect(safeNext('/login?next=/x'), '/vehicles');
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'widgets/app_frame.dart';

/// Pages and who may open them (ADR-0006). The guard here is for the user's convenience only;
/// the server refuses every API call without a valid token regardless (ADR-0005).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (prev, next) {
    if (prev?.status != next.status) refresh.value++;
  });

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider).isSignedIn;
      final path = state.matchedLocation;
      final isAppPage = path.startsWith('/vehicles');
      if (!signedIn && isAppPage) {
        return Uri(path: '/login', queryParameters: {'next': state.uri.toString()}).toString();
      }
      if (signedIn && path == '/login') {
        return safeNext(state.uri.queryParameters['next']);
      }
      return null;
    },
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(next: state.uri.queryParameters['next']),
      ),
      ShellRoute(
        builder: (context, state, child) => AppFrame(location: state.matchedLocation, child: child),
        routes: [
          // shortcut: the starter list (with its own add/edit pages pushed on top) lives here until
          // Phase 7 gives each vehicle page its own URL.
          GoRoute(path: '/vehicles', builder: (context, state) => const VehicleListScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

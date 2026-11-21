import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/vehicle_form_page.dart';
import 'screens/vehicle_panel.dart';
import 'screens/vehicle_urls.dart';
import 'screens/vehicles_screen.dart';
import 'theme/stark_tokens.dart';
import 'widgets/stark_page.dart';
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
          // The panel and the forms are child routes, so the register stays mounted underneath
          // and keeps its page, search and filter (all read from the shared query string).
          GoRoute(
            path: '/vehicles',
            pageBuilder: (context, state) =>
                _enterPage(context, state, VehiclesScreen(query: vehicleQueryFromUri(state.uri))),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _enterPage(context, state, VehicleFormPage(query: vehicleQueryFromUri(state.uri))),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _panelPage(
                  context,
                  state,
                  VehiclePanel(id: _id(state), query: vehicleQueryFromUri(state.uri)),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _enterPage(
                      context,
                      state,
                      VehicleFormPage(id: _id(state), editing: true, query: vehicleQueryFromUri(state.uri)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

int? _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '');

/// DESIGN.md "Page enter": fade + 6px rise, `base`; instant when the OS asks for reduced motion.
Page<void> _enterPage(BuildContext context, GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: motion(context, StarkMotion.base),
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, _, child) {
        final t = CurvedAnimation(parent: animation, curve: StarkMotion.ease);
        return FadeTransition(
          opacity: t,
          child: AnimatedBuilder(
            animation: t,
            builder: (context, child) => Transform.translate(offset: Offset(0, 6 * (1 - t.value)), child: child),
            child: child,
          ),
        );
      },
    );

/// The detail panel: a see-through page over the register. The panel animates itself (slide + scrim).
Page<void> _panelPage(BuildContext context, GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      opaque: false,
      transitionDuration: motion(context, StarkMotion.base),
      reverseTransitionDuration: motion(context, StarkMotion.base),
      transitionsBuilder: (context, animation, _, child) => child,
    );

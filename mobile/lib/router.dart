import 'package:go_router/go_router.dart';

import 'core/utils/go_router_refresh.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/nodes/domain/entities/node_entity.dart';
import 'features/nodes/presentation/pages/map_page.dart';
import 'features/nodes/presentation/pages/node_detail_page.dart';
import 'features/nodes/presentation/pages/register_node_page.dart';

/// Auth-aware router. `refreshListenable` re-runs `redirect` on every
/// AuthBloc state change, so navigation follows auth state automatically:
/// authenticated users never see /login, guests never see /home.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;
      final onAuthPages = location == '/login' || location == '/register';
      final onSplash = location == '/splash';

      return switch (authState) {
        Authenticated() => (onSplash || onAuthPages) ? '/home' : null,
        Unauthenticated() || AuthError() => onAuthPages ? null : '/login',
        // Initial / loading: stay put (splash shows the brand while checking;
        // form pages show their own spinners during submits).
        AuthInitial() || AuthLoading() => null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      // Authenticated home: the map of nearby Nodes (MASTER_PLAN Phase 2).
      GoRoute(path: '/home', builder: (context, state) => const MapPage()),
      // Static segment must precede '/nodes/:id' so "register" isn't an id.
      GoRoute(
        path: '/nodes/register',
        builder: (context, state) => const RegisterNodePage(),
      ),
      GoRoute(
        path: '/nodes/:id',
        builder: (context, state) => NodeDetailPage(
          nodeId: int.parse(state.pathParameters['id']!),
          initial: state.extra is NodeEntity ? state.extra as NodeEntity : null,
        ),
      ),
    ],
  );
}

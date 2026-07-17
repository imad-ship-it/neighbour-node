import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';
import 'router.dart';

/// Brand seed — a warm teal-green: trust + community + eco, the
/// neighbourhood-sharing identity of Neighbor-Node.
const Color kSeedColor = Color(0xFF0E7C66);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc = sl<AuthBloc>();
  late final GoRouter _router = createRouter(_authBloc);

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: kSeedColor);
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Neighbor Node',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          colorScheme: scheme,
          scaffoldBackgroundColor: scheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            elevation: 0,
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.primary, width: 1.6),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: scheme.surfaceContainerLow,
          ),
        ),
      ),
    );
  }
}

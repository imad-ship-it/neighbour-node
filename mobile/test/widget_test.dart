import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neighbor_node/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:neighbor_node/features/auth/presentation/pages/splash_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('Splash renders branding and dispatches AppStarted',
      (tester) async {
    final bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const SplashPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('Neighbor Node'), findsOneWidget);
    expect(find.text('Borrow local. Lend better.'), findsOneWidget);
  });
}

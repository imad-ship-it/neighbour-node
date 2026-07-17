import 'package:flutter_test/flutter_test.dart';

import 'package:neighbor_node/app.dart';

void main() {
  testWidgets('App boots to splash, then moves to login', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Neighbor Node'), findsOneWidget);
    expect(find.text('Borrow local. Lend better.'), findsOneWidget);

    // Let the splash timer fire and the router navigate.
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Welcome back'), findsOneWidget);
  });
}

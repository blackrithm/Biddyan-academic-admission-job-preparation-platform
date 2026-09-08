import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biddyan/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BiddyanApp()),
    );

    // The home gate shows the auth screen by default (not logged in).
    expect(find.text('বিদ্যান'), findsOneWidget);
  });
}

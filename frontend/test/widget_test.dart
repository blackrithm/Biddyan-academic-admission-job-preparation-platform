import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biddyan/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BiddyanApp()),
    );

    // The auth notifier starts in guest mode, so the home gate shows the
    // dashboard immediately.
    expect(find.text('পরীক্ষা সেকশন'), findsOneWidget);
  });
}

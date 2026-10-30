import 'package:flutter_test/flutter_test.dart';

import 'package:dorehami/main.dart';

void main() {
  testWidgets('شروع برنامه صفحه ورود را نشان می‌دهد', (tester) async {
    await tester.pumpWidget(const DorehamiApp());
    await tester.pump();
    expect(find.text('دورهمی'), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
  });
}

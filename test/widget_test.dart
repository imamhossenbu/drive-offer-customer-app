import 'package:flutter_test/flutter_test.dart';
import 'package:drive_offer_customer_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Customer app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CustomerApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CustomerApp), findsOneWidget);
  });
}

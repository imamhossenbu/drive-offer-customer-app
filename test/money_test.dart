import 'package:flutter_test/flutter_test.dart';
import 'package:drive_offer_customer_app/core/money.dart';

void main() {
  group('poishaToBdt', () {
    test('converts offers under 100 BDT correctly (regression)', () {
      expect(poishaToBdt(5000), 50);
      expect(poishaToBdt(9900), 99);
      expect(poishaToBdt(1000), 10);
    });
    test('converts larger amounts', () {
      expect(poishaToBdt(74900), 749);
      expect(poishaToBdt(1000000), 10000);
    });
    test('handles strings, null and fractions', () {
      expect(poishaToBdt('2500'), 25);
      expect(poishaToBdt(null), 0);
      expect(poishaToBdt(4950), 49.5);
    });
  });

  group('formatBdt', () {
    test('drops .00 for whole amounts', () {
      expect(formatBdt(50), '50');
      expect(formatBdt(749.0), '749');
    });
    test('keeps two decimals otherwise', () {
      expect(formatBdt(49.5), '49.50');
      expect(formatBdt(0.5), '0.50');
    });
  });
}

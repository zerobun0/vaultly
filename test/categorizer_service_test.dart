import 'package:flutter_test/flutter_test.dart';
import 'package:vaultly/data/services/categorizer_service.dart';

void main() {
  const svc = CategorizerService();

  test('categorize known merchants', () {
    expect(svc.categorizeMerchant('Tesco Superstore'), 'groceries');
    expect(svc.categorizeMerchant('Netflix UK'), 'subscriptions');
    expect(svc.categorizeMerchant('Uber BV'), 'transport');
    expect(svc.categorizeMerchant('Amazon Marketplace'), 'shopping');
  });

  test('uncategorized fallback', () {
    expect(svc.categorizeMerchant('Some Unknown Vendor'), 'uncategorized');
  });
}

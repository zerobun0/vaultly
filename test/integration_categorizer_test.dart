import 'package:flutter_test/flutter_test.dart';
import 'package:vaultly/data/parsers/parser_factory.dart';
import 'package:vaultly/data/services/categorizer_service.dart';

void main() {
  test('monzo parsing integrates with categorizer', () {
    const csv = '''Transaction ID,Date,Money In,Money Out,Type,Name,Description,Currency,Category
tx1,27/04/2026,,12.34,,Tesco Superstore,Groceries,GBP,
''';

    const factory = ParserFactory();
    final parser = factory.create('monzo');
    final parsed = parser.parse(csv);
    final txs = const CategorizerService().categorizeTransactions(parsed);

    expect(txs, isNotEmpty);
    final t = txs.first;
    expect(t.externalId, 'tx1');
    expect(t.merchantName.toLowerCase(), contains('tesco'));
    expect(t.category, 'groceries');
  });
}

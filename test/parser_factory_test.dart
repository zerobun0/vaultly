import 'package:flutter_test/flutter_test.dart';

import 'package:vaultly/data/parsers/monzo_parser.dart';
import 'package:vaultly/data/parsers/parser_factory.dart';

void main() {
  const factory = ParserFactory();

  test('creates the Monzo parser for monzo input', () {
    final parser = factory.create('Monzo');

    expect(parser, isA<MonzoParser>());
  });

  test('rejects unknown bank names', () {
    expect(() => factory.create('unknown'), throwsUnsupportedError);
  });
}
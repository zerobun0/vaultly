import 'bank_parser_interface.dart';
import 'monzo_parser.dart';

class ParserFactory {
  const ParserFactory();

  BankParserInterface create(String sourceBank) {
    switch (sourceBank.trim().toLowerCase()) {
      case 'monzo':
        return const MonzoParser();
      default:
        throw UnsupportedError('Unsupported bank parser: $sourceBank');
    }
  }
}

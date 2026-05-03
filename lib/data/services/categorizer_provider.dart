import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'categorizer_service.dart';

final categorizerProvider = Provider<CategorizerService>((ref) => const CategorizerService());

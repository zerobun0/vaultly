import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_exceptions.dart';

// ---------------------------------------------------------------------------
// Cache helpers
// ---------------------------------------------------------------------------

class _CacheEntry {
  _CacheEntry(this.data, this.timestamp);

  final dynamic data;
  final DateTime timestamp;

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(timestamp) > ttl;
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class T212Position {
  const T212Position({
    required this.ticker,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.ppl,
    required this.fxPpl,
  });

  final String ticker;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double ppl;
  final double fxPpl;

  factory T212Position.fromJson(Map<String, dynamic> json) {
    return T212Position(
      ticker: json['ticker'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      ppl: (json['ppl'] as num?)?.toDouble() ?? 0.0,
      fxPpl: (json['fxPpl'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class T212Portfolio {
  const T212Portfolio({required this.positions});

  final List<T212Position> positions;

  factory T212Portfolio.fromJson(List<dynamic> json) {
    return T212Portfolio(
      positions: json
          .map((e) => T212Position.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class T212Cash {
  const T212Cash({
    required this.free,
    required this.total,
    required this.invested,
    required this.ppl,
    required this.result,
  });

  final double free;
  final double total;
  final double invested;
  final double ppl;
  final double result;

  factory T212Cash.fromJson(Map<String, dynamic> json) {
    return T212Cash(
      free: (json['free'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      invested: (json['invested'] as num?)?.toDouble() ?? 0.0,
      ppl: (json['ppl'] as num?)?.toDouble() ?? 0.0,
      result: (json['result'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class T212Order {
  const T212Order({
    required this.id,
    required this.ticker,
    required this.dateExecuted,
    required this.filledQuantity,
    required this.filledValue,
    required this.type,
    required this.status,
  });

  final String id;
  final String ticker;
  final DateTime? dateExecuted;
  final double filledQuantity;
  final double filledValue;
  final String type;
  final String status;

  factory T212Order.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['dateExecuted'] as String?;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return T212Order(
      id: json['id']?.toString() ?? '',
      ticker: json['ticker'] as String? ?? '',
      dateExecuted: parsedDate,
      filledQuantity: (json['filledQuantity'] as num?)?.toDouble() ?? 0.0,
      filledValue: (json['filledValue'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class T212Dividend {
  const T212Dividend({
    required this.reference,
    required this.ticker,
    required this.amount,
    required this.paidOn,
  });

  final String reference;
  final String ticker;
  final double amount;
  final DateTime? paidOn;

  factory T212Dividend.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['paidOn'] as String?;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return T212Dividend(
      reference: json['reference'] as String? ?? '',
      ticker: json['ticker'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidOn: parsedDate,
    );
  }
}

class T212AccountInfo {
  const T212AccountInfo({
    required this.id,
    required this.currencyCode,
  });

  final int id;
  final String currencyCode;

  factory T212AccountInfo.fromJson(Map<String, dynamic> json) {
    return T212AccountInfo(
      id: json['id'] as int? ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'GBP',
    );
  }
}

// ---------------------------------------------------------------------------
// Hostname validator interceptor
//
// TODO: Implement real certificate pinning once the T212 certificate hashes
// are known at compile time. This would require embedding the SHA-256 SPKI
// fingerprint(s) of live.trading212.com's certificate chain and comparing
// against the peer certificate during the TLS handshake (e.g., using
// native_dio_adapter or a custom HttpClient with SecurityContext).
// For now, we validate only that every request targets the expected host.
// ---------------------------------------------------------------------------

class _HostnameValidatorInterceptor extends Interceptor {
  const _HostnameValidatorInterceptor(this.expectedHost);

  final String expectedHost;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final host = options.uri.host;
    if (host != expectedHost) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'Blocked request to unexpected host: $host '
              '(expected $expectedHost)',
          type: DioExceptionType.cancel,
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }
}

// ---------------------------------------------------------------------------
// Trading212Service
// ---------------------------------------------------------------------------

class Trading212Service {
  Trading212Service(String apiKey, {bool demo = false})
      : _dio = _buildDio(apiKey, demo: demo);

  final Dio _dio;

  static const _liveHost = 'live.trading212.com';
  static const _demoHost = 'demo.trading212.com';
  static const _portfolioTtl = Duration(minutes: 5);
  static const _cashTtl = Duration(minutes: 5);
  static const _historyTtl = Duration(hours: 1);

  final Map<String, _CacheEntry> _cache = {};

  static Dio _buildDio(String apiKey, {required bool demo}) {
    final host = demo ? _demoHost : _liveHost;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://$host/api/v0/',
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.interceptors.add(_HostnameValidatorInterceptor(host));
    return dio;
  }

  // -------------------------------------------------------------------------
  // Internal: cached get
  // -------------------------------------------------------------------------

  Future<dynamic> _cachedGet(
    String path,
    Duration ttl, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final cacheKey = '$path?${queryParameters?.toString() ?? ''}';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(ttl)) {
      return cached.data;
    }

    final data = await _getWithRetry(path, queryParameters: queryParameters);
    _cache[cacheKey] = _CacheEntry(data, DateTime.now());
    return data;
  }

  // -------------------------------------------------------------------------
  // Internal: GET with exponential-backoff retry on 429
  // -------------------------------------------------------------------------

  Future<dynamic> _getWithRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    const delays = [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)];
    int attempt = 0;

    while (true) {
      try {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
        );
        return response.data;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 429 && attempt < delays.length) {
          await Future<void>.delayed(delays[attempt]);
          attempt++;
          continue;
        }

        if (statusCode == 401) {
          throw const AuthException('Invalid T212 API key');
        }

        if (statusCode != null && statusCode >= 400) {
          final message = e.response?.data?.toString() ?? e.message ?? 'HTTP error';
          throw NetworkException(message, statusCode);
        }

        throw NetworkException(e.message ?? 'Network error', null);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Public API methods
  // -------------------------------------------------------------------------

  /// GET /equity/portfolio — returns the current portfolio positions.
  Future<T212Portfolio> getPortfolio() async {
    final data = await _cachedGet('equity/portfolio', _portfolioTtl);
    final list = data as List<dynamic>;
    return T212Portfolio.fromJson(list);
  }

  /// GET /account/cash — returns cash balances.
  Future<T212Cash> getCash() async {
    final data = await _cachedGet('account/cash', _cashTtl);
    return T212Cash.fromJson(data as Map<String, dynamic>);
  }

  /// GET /history/orders — returns the last 50 orders.
  Future<List<T212Order>> getOrderHistory() async {
    final data = await _cachedGet(
      'history/orders',
      _historyTtl,
      queryParameters: {'limit': 50},
    );
    final map = data as Map<String, dynamic>;
    final items = map['items'] as List<dynamic>? ?? (data is List ? data as List<dynamic> : <dynamic>[]);
    return items
        .map((e) => T212Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /history/dividends — returns dividend history.
  Future<List<T212Dividend>> getDividendHistory() async {
    final data = await _cachedGet('history/dividends', _historyTtl);
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['items'] as List<dynamic>? ?? [];
    } else {
      items = [];
    }
    return items
        .map((e) => T212Dividend.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /account/info — returns account metadata.
  Future<T212AccountInfo> getAccountInfo() async {
    final data = await _cachedGet('account/info', _cashTtl);
    return T212AccountInfo.fromJson(data as Map<String, dynamic>);
  }

  /// Clears all in-memory cache entries.
  void clearCache() => _cache.clear();
}

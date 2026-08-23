import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String locale;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.name,
  });

  static const Map<String, CurrencyInfo> supported = {
    'CO': CurrencyInfo(code: 'COP', symbol: '\$', locale: 'es_CO', name: 'Colombiano'),
    'US': CurrencyInfo(code: 'USD', symbol: '\$', locale: 'en_US', name: 'Dólar'),
    'ES': CurrencyInfo(code: 'EUR', symbol: '\u20ac', locale: 'es_ES', name: 'Euro'),
    'MX': CurrencyInfo(code: 'MXN', symbol: '\$', locale: 'es_MX', name: 'Peso mexicano'),
    'BR': CurrencyInfo(code: 'BRL', symbol: 'R\$', locale: 'pt_BR', name: 'Real'),
    'AR': CurrencyInfo(code: 'ARS', symbol: '\$', locale: 'es_AR', name: 'Peso argentino'),
    'CL': CurrencyInfo(code: 'CLP', symbol: '\$', locale: 'es_CL', name: 'Peso chileno'),
    'PE': CurrencyInfo(code: 'PEN', symbol: 'S/', locale: 'es_PE', name: 'Sol'),
    'VE': CurrencyInfo(code: 'USD', symbol: '\$', locale: 'es_VE', name: 'Dólar'),
  };

  factory CurrencyInfo.fromCountryCode(String countryCode) {
    return supported[countryCode] ?? const CurrencyInfo(
      code: 'USD',
      symbol: '\$',
      locale: 'en_US',
      name: 'Dólar',
    );
  }

  static String format(double amount, CurrencyInfo currency) {
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatWithCode(double amount, CurrencyInfo currency) {
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 0,
    );
    return '${formatter.format(amount)} ${currency.code}';
  }
}

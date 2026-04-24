import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount, String currency) {
    final format = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : (currency == 'EUR' ? '€' : (currency == 'GBP' ? '£' : '\$')),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String generateInvoiceNumber(int count) {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}';
  }
}

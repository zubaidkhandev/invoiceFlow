import 'package:intl/intl.dart';

class AppFormatters {
  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'PKR':
        return 'Rs.';
      default:
        return '\$';
    }
  }

  static String formatCurrency(double amount, String currency) {
    final format = NumberFormat('#,###');
    return '${getCurrencySymbol(currency)}${format.format(amount)}';
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

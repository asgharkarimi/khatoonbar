import 'package:intl/intl.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

class AppFormatters {
  static String formatCurrency(num amount) {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(amount).toPersianDigit();
  }

  static String amountToWords(num amount, {String unit = "تومان"}) {
    return "${amount.toInt().toString().toWord()} $unit";
  }
}

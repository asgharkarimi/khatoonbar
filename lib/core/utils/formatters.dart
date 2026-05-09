import 'package:intl/intl.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class AppFormatters {
  static String formatCurrency(num amount) {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(amount).toPersianDigit();
  }

  static String amountToWords(num amount, {String unit = "تومان"}) {
    return "${amount.toInt().toString().toWord()} $unit";
  }

  static String formatPersianDate(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return "${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}".toPersianDigit();
  }

  static String formatPersianDateTime(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return "${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}".toPersianDigit();
  }
}

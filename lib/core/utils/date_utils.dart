import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime get startOfWeek {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }
  
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String formatDayName(DateTime date) {
    return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
  }
  
  static String formatShortDayName(DateTime date) {
    return DateFormat('E').format(date); // Mon, Tue, etc.
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }
}

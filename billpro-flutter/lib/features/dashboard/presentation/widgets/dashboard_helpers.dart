import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

/// Formats a number as Indian currency (₹) — compact.
String formatCurrency(double value) {
  if (value.abs() >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
  } else if (value.abs() >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(2)} L';
  } else if (value.abs() >= 1000) {
    return '₹${(value / 1000).toStringAsFixed(1)}K';
  }
  return '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
}

/// Formats a number as full Indian currency (₹48,486.20) with comma separators.
String formatCurrencyFull(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

/// Formats a number as compact (no currency).
String formatNumber(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

/// Formats a date.
String formatDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd MMM yyyy').format(date);
}

/// Returns status color.
Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return AppColors.paid;
    case 'partially_paid':
      return AppColors.partiallyPaid;
    case 'overdue':
      return AppColors.overdue;
    case 'draft':
      return AppColors.draft;
    case 'saved':
      return AppColors.saved;
    case 'cancelled':
    case 'void':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

/// Capitalizes the first letter and replaces underscores.
String formatStatus(String status) {
  return status.replaceAll('_', ' ').split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

/// Month name from month number.
String monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  if (month < 1 || month > 12) return '';
  return months[month];
}

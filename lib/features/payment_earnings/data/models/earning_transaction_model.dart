import 'package:flutter/material.dart';

class EarningTransactionModel {
  final String id;
  final String title;
  final String initials;
  final int initialsBgColorValue;
  final int initialsTextColorValue;
  final String date;
  final String amount;
  final String status;
  final bool isPaid;

  const EarningTransactionModel({
    required this.id,
    required this.title,
    required this.initials,
    required this.initialsBgColorValue,
    required this.initialsTextColorValue,
    required this.date,
    required this.amount,
    required this.status,
    required this.isPaid,
  });

  Color get initialsBg => Color(initialsBgColorValue);
  Color get initialsColor => Color(initialsTextColorValue);

  factory EarningTransactionModel.fromJson(Map<String, dynamic> json) {
    final String rawAmount = json['amount']?.toString() ?? '0';
    final String formattedAmount = rawAmount.startsWith('+') || rawAmount.startsWith('-') || rawAmount.startsWith('₹')
        ? rawAmount
        : '+₹$rawAmount';

    final String title = json['title']?.toString() ??
        json['description']?.toString() ??
        json['type']?.toString() ??
        'Visit Payout';

    final String initials = json['initials']?.toString() ??
        (title.isNotEmpty ? title.substring(0, title.length >= 2 ? 2 : 1).toUpperCase() : 'PT');

    final String statusStr = json['status']?.toString() ?? 'Paid';
    final bool isPaid = json['isPaid'] ?? (statusStr.toUpperCase() == 'PAID' || statusStr.toUpperCase() == 'SETTLED');

    return EarningTransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['transactionId']?.toString() ?? '',
      title: title,
      initials: initials,
      initialsBgColorValue: json['initialsBgColorValue'] ?? (isPaid ? 0xFFDCFCE7 : 0xFFFFEDD5),
      initialsTextColorValue: json['initialsTextColorValue'] ?? (isPaid ? 0xFF15803D : 0xFFC2410C),
      date: json['date']?.toString() ?? json['createdAt']?.toString() ?? 'Recent',
      amount: formattedAmount,
      status: statusStr,
      isPaid: isPaid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'initials': initials,
      'initialsBgColorValue': initialsBgColorValue,
      'initialsTextColorValue': initialsTextColorValue,
      'date': date,
      'amount': amount,
      'status': status,
      'isPaid': isPaid,
    };
  }
}


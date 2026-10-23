import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    required this.color,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  factory StatusBadge.orderStatus(String status, String label) {
    return StatusBadge(
      status: status,
      label: label,
      color: AppTheme.orderStatusColor(status),
    );
  }

  factory StatusBadge.itemStatus(String status, String label) {
    return StatusBadge(
      status: status,
      label: label,
      color: AppTheme.itemStatusColor(status),
    );
  }

  factory StatusBadge.tableStatus(String status, String label) {
    return StatusBadge(
      status: status,
      label: label,
      color: AppTheme.tableStatusColor(status),
    );
  }
}

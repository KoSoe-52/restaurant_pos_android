import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor ?? AppColors.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class VoidReasonDialog extends StatefulWidget {
  final String title;
  final String hint;

  const VoidReasonDialog({
    super.key,
    this.title = 'Void Reason',
    this.hint = 'Enter reason for voiding...',
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Void Reason',
    String hint = 'Enter reason for voiding...',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => VoidReasonDialog(title: title, hint: hint),
    );
  }

  @override
  State<VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<VoidReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error),
          const SizedBox(width: 10),
          Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) {
            if (v == null || v.trim().length < 3) {
              return 'Reason must be at least 3 characters';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Void'),
        ),
      ],
    );
  }
}

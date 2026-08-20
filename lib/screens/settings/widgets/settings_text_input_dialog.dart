import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

Future<String?> showSettingsTextInputDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String labelText,
  String? description,
  String? hintText,
  String? suffixText,
  String? prefixText,
  bool obscureText = false,
  bool allowClear = false,
  int maxLines = 1,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  String? Function(String?)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SettingsTextInputDialog(
      title: title,
      initialValue: initialValue,
      labelText: labelText,
      description: description,
      hintText: hintText,
      suffixText: suffixText,
      prefixText: prefixText,
      obscureText: obscureText,
      allowClear: allowClear,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
    ),
  );
}

class _SettingsTextInputDialog extends StatefulWidget {
  const _SettingsTextInputDialog({
    required this.title,
    required this.initialValue,
    required this.labelText,
    required this.obscureText,
    required this.allowClear,
    required this.maxLines,
    required this.textCapitalization,
    this.description,
    this.hintText,
    this.suffixText,
    this.prefixText,
    this.keyboardType,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String labelText;
  final String? description;
  final String? hintText;
  final String? suffixText;
  final String? prefixText;
  final bool obscureText;
  final bool allowClear;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  State<_SettingsTextInputDialog> createState() =>
      _SettingsTextInputDialogState();
}

class _SettingsTextInputDialogState extends State<_SettingsTextInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final errorText = widget.validator?.call(_controller.text);
    if (errorText != null) {
      setState(() => _errorText = errorText);
      return;
    }
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.description case final description?) ...[
            Text(description),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              suffixText: widget.suffixText,
              prefixText: widget.prefixText,
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        if (widget.allowClear)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l10n.settingsClear),
          ),
        TextButton(onPressed: _save, child: Text(l10n.settingsSave)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.requiredMessage,
    required this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final String requiredMessage;
  final List<String> autofillHints;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onFieldSubmitted: onFieldSubmitted,
            validator: (value) =>
                value == null || value.isEmpty ? requiredMessage : null,
            decoration: InputDecoration(
              hintText: placeholder,
              suffixIcon: suffixIcon,
              errorMaxLines: 3,
            ),
          ),
        ),
      ],
    );
  }
}

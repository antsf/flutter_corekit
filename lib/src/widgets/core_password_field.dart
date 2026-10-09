import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core_icon_button.dart';
import 'core_text_field.dart';

/// Password UI. Controllers and controlled visibility remain caller-owned.
class CorePasswordField extends StatefulWidget {
  const CorePasswordField(
      {super.key,
      this.controller,
      this.initialValue,
      this.prefixIcon,
      this.keyboardType,
      this.inputFormatters,
      this.readOnly = false,
      this.focusNode,
      this.labelText,
      this.semanticsLabel,
      this.hintText,
      this.helperText,
      this.errorText,
      this.validator,
      this.onChanged,
      this.onSaved,
      this.onFieldSubmitted,
      this.textInputAction,
      this.autofillHints = const [AutofillHints.password],
      this.enabled = true,
      this.obscureText,
      this.onToggleObscure,
      this.showLabel = 'Show password',
      this.hideLabel = 'Hide password',
      this.toggleIconBuilder,
      this.style,
      this.helperStyle,
      this.minHeight = 50,
      this.horizontalPadding = 16,
      this.verticalPadding = 12,
      this.autovalidateMode = AutovalidateMode.disabled})
      : assert(obscureText == null || onToggleObscure != null),
        assert(controller == null || initialValue == null);
  final TextEditingController? controller;
  final String? initialValue;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? labelText, hintText, helperText, errorText;
  final String? semanticsLabel;
  final String showLabel, hideLabel;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final bool? obscureText;
  final VoidCallback? onToggleObscure;
  final Widget Function(BuildContext, bool)? toggleIconBuilder;
  final TextStyle? style, helperStyle;
  final double minHeight, horizontalPadding, verticalPadding;
  final AutovalidateMode autovalidateMode;
  @override
  State<CorePasswordField> createState() => _CorePasswordFieldState();
}

class _CorePasswordFieldState extends State<CorePasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    final hidden = widget.obscureText ?? _hidden;
    return CoreTextField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      prefixIcon: widget.prefixIcon,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      semanticsLabel: widget.semanticsLabel,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      validator: widget.validator,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      obscureText: hidden,
      enableSuggestions: false,
      autocorrect: false,
      style: widget.style,
      helperStyle: widget.helperStyle,
      minHeight: widget.minHeight,
      horizontalPadding: widget.horizontalPadding,
      verticalPadding: widget.verticalPadding,
      autovalidateMode: widget.autovalidateMode,
      suffixIcon: CoreIconButton(
          tooltip: hidden ? widget.showLabel : widget.hideLabel,
          enabled: widget.enabled,
          icon: widget.toggleIconBuilder?.call(context, hidden) ??
              Icon(hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
          onPressed: widget.onToggleObscure ??
              () => setState(() => _hidden = !hidden)),
    );
  }
}

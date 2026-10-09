import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form-compatible input. Controllers/focus nodes remain caller-owned.
class CoreTextField extends StatefulWidget {
  const CoreTextField({
    super.key,
    this.controller,
    this.minHeight = 50,
    this.horizontalPadding = 16,
    this.verticalPadding = 12,
    this.style,
    this.helperStyle,
    this.semanticsLabel,
    this.initialValue,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSaved,
    this.onFieldSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints = const <String>[],
    this.enableSuggestions,
    this.autocorrect,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.autovalidateMode = AutovalidateMode.disabled,
  })  : assert(controller == null || initialValue == null),
        assert(!obscureText || maxLines == 1);

  final double minHeight, horizontalPadding, verticalPadding;
  final TextStyle? style, helperStyle;
  final String? semanticsLabel;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? labelText, hintText, helperText, errorText;
  final Widget? prefixIcon, suffixIcon;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool? enableSuggestions, autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled, readOnly, obscureText;
  final int? maxLines;
  final AutovalidateMode autovalidateMode;

  @override
  State<CoreTextField> createState() => _CoreTextFieldState();
}

class _CoreTextFieldState extends State<CoreTextField> {
  final _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // InputDecorator retains the old helper during error transitions. Capture
    // this build's text so its state listener cannot read a later null value.
    final helperText = widget.helperText;
    final style = widget.style ?? Theme.of(context).textTheme.bodyLarge;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 16) *
            (style?.height ?? 1);
    final bodyHeight = (lineHeight + widget.verticalPadding * 2).clamp(
      widget.minHeight < 48 ? 48.0 : widget.minHeight,
      double.infinity,
    );
    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      statesController: _states,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      // Native string errors ellipsize soft-wrapped text even with maxLines=null.
      // Keep native validation/state/announcements and inherit its error style.
      errorBuilder: (context, message) =>
          Text(message, overflow: TextOverflow.visible),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      enableSuggestions: widget.enableSuggestions ?? !widget.obscureText,
      autocorrect: widget.autocorrect ?? !widget.obscureText,
      maxLines: widget.maxLines,
      autovalidateMode: widget.autovalidateMode,
      style: style,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        // Older SDKs inherit the field's single-line limit when this is null.
        // A line cannot consume fewer than one code unit (plus a final empty
        // line), so this content-derived bound never truncates the hint.
        hintMaxLines:
            widget.hintText == null ? null : widget.hintText!.length + 1,
        helper: helperText == null
            ? null
            : ValueListenableBuilder<Set<WidgetState>>(
                valueListenable: _states,
                builder: (context, states, _) => Text(
                  helperText,
                  style: (widget.helperStyle ??
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))
                      ?.merge(
                    WidgetStateProperty.resolveAs(
                      Theme.of(context).inputDecorationTheme.helperStyle,
                      states,
                    ),
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
        error: widget.errorText == null
            ? null
            : Text(widget.errorText!, overflow: TextOverflow.visible),
        // Reserve the body without constraining helper/validation text below it.
        // InputDecorator replaces leading padding with prefix width + its gap
        // (4 in Material 3, 0 in Material 2), even for this empty height spacer.
        prefixIcon: widget.prefixIcon ?? const SizedBox.shrink(),
        prefixIconConstraints: BoxConstraints(
          minWidth: widget.prefixIcon == null
              ? widget.horizontalPadding -
                  (Theme.of(context).useMaterial3 ? 4 : 0)
              : 48.0,
          minHeight: bodyHeight,
        ),
        suffixIcon: widget.suffixIcon,
        suffixIconConstraints: BoxConstraints(
          minWidth: 48.0,
          minHeight: bodyHeight,
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        isDense: true,
      ),
    );
    return widget.semanticsLabel == null
        ? field
        : Semantics(label: widget.semanticsLabel, child: field);
  }
}

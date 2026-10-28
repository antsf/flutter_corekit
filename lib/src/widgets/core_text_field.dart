import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Multiline input and hints require an explicit textarea variant.
enum CoreTextFieldVariant { text, textarea }

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
    this.variant = CoreTextFieldVariant.text,
    int? maxLines,
    this.autovalidateMode = AutovalidateMode.disabled,
  })  : maxLines = variant == CoreTextFieldVariant.textarea ? maxLines : 1,
        assert(controller == null || initialValue == null),
        assert(maxLines == null || maxLines > 0),
        assert(variant == CoreTextFieldVariant.textarea ||
            maxLines == null ||
            maxLines == 1),
        assert(!obscureText || variant == CoreTextFieldVariant.text);

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
  final CoreTextFieldVariant variant;

  /// One for ordinary fields; null (unbounded) by default for textarea.
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
    final textarea = widget.variant == CoreTextFieldVariant.textarea;
    final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle;
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
      keyboardType:
          widget.keyboardType ?? (textarea ? TextInputType.multiline : null),
      textInputAction:
          widget.textInputAction ?? (textarea ? TextInputAction.newline : null),
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
        hintStyle: WidgetStateTextStyle.resolveWith((states) =>
            (WidgetStateProperty.resolveAs(hintStyle, states) ??
                    const TextStyle())
                .copyWith(
                    overflow: textarea && widget.maxLines == null
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis)),
        // Explicitly keep native hints single-line except for textarea.
        // A content-derived bound also preserves old SDK textarea wrapping.
        hintMaxLines: textarea
            ? widget.maxLines ??
                (widget.hintText == null ? null : widget.hintText!.length + 1)
            : 1,
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

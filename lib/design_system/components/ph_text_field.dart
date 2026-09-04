import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHTextField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String? label;
  final String? hintText;
  final String? suffixText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;

  const PHTextField({
    super.key,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.label,
    this.hintText,
    this.suffixText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTapOutside: onTapOutside,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      style: PHTypography.body.copyWith(color: colors.textPrimary),
      cursorColor: colors.borderFocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? colors.bgSurface : colors.bgDisabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PHSpacing.md,
          vertical: PHSpacing.sm,
        ),
        labelStyle: PHTypography.subheadline.copyWith(
          color: colors.textSecondary,
        ),
        hintStyle: PHTypography.body.copyWith(color: colors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.iconDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.iconDanger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PHRadius.md),
          borderSide: BorderSide(color: colors.bgDisabled),
        ),
        helperStyle:
            inputTheme.helperStyle ??
            PHTypography.caption1.copyWith(color: colors.textSecondary),
        errorStyle:
            inputTheme.errorStyle ??
            PHTypography.caption1.copyWith(color: colors.textDanger),
        prefixIconColor: scheme.primary,
        suffixIconColor: colors.iconSecondary,
      ),
    );
  }
}

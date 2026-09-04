import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHSelectField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? label;
  final String? hintText;
  final String? errorText;

  const PHSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.label,
    this.hintText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(PHRadius.md),
      borderSide: BorderSide(color: colors.borderDefault),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      style: PHTypography.body.copyWith(color: colors.textPrimary),
      iconEnabledColor: colors.iconSecondary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: enabled ? colors.bgSurface : colors.bgDisabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PHSpacing.md,
          vertical: PHSpacing.sm,
        ),
        labelStyle: PHTypography.subheadline.copyWith(
          color: colors.textSecondary,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.borderFocus, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.iconDanger),
        ),
        disabledBorder: border.copyWith(
          borderSide: BorderSide(color: colors.bgDisabled),
        ),
      ),
    );
  }
}

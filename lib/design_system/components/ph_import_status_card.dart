import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_radius.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

enum PHImportStatus { waiting, recognizing, success, failed }

class PHImportStatusCard extends StatelessWidget {
  final PHImportStatus status;
  final String title;
  final String? message;
  final double? progress;
  final Widget? preview;
  final Widget? trailing;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  const PHImportStatusCard({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.progress,
    this.preview,
    this.trailing,
    this.onRetry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final statusColor = switch (status) {
      PHImportStatus.waiting => colors.iconSecondary,
      PHImportStatus.recognizing => colors.iconAccent,
      PHImportStatus.success => colors.iconSuccess,
      PHImportStatus.failed => colors.iconDanger,
    };
    final action =
        trailing ??
        (status == PHImportStatus.failed && onRetry != null
            ? TextButton(onPressed: onRetry, child: const Text('重试'))
            : null);
    return Semantics(
      container: true,
      label: message == null ? title : '$title，$message',
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(PHSpacing.md),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(PHRadius.md),
        ),
        child: Row(
          children: [
            if (preview != null) ...[
              preview!,
              const SizedBox(width: PHSpacing.md),
            ] else
              Icon(_iconForStatus(), color: statusColor),
            const SizedBox(width: PHSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PHTypography.bodyEmphasis.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (message != null)
                    Text(
                      message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PHTypography.subheadline.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (progress != null) ...[
                    const SizedBox(height: PHSpacing.xs),
                    LinearProgressIndicator(
                      value: progress,
                      color: statusColor,
                      backgroundColor: colors.bgDisabled,
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: PHSpacing.sm),
              action,
            ],
            if (onRemove != null)
              IconButton(
                tooltip: '移除',
                onPressed: onRemove,
                icon: Icon(Icons.close, color: colors.iconSecondary),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStatus() {
    return switch (status) {
      PHImportStatus.waiting => Icons.schedule_outlined,
      PHImportStatus.recognizing => Icons.hourglass_top,
      PHImportStatus.success => Icons.check_circle_outline,
      PHImportStatus.failed => Icons.error_outline,
    };
  }
}

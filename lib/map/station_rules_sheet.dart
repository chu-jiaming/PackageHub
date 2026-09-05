import 'package:flutter/material.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/components/ph_button.dart';
import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/station_pickup_rules.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

Future<void> showStationRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StationRulesSheet(),
  );
}

class _StationRulesSheet extends StatelessWidget {
  const _StationRulesSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, controller) => PHBottomSheet(
        title: '站点规则',
        trailing: PHButton(
          key: const Key('station-rules-done'),
          variant: PHButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
          label: '完成',
        ),
        padding: const EdgeInsets.fromLTRB(
          PHSpacing.md,
          PHSpacing.sm,
          PHSpacing.md,
          PHSpacing.md,
        ),
        child: Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              0,
              PHSpacing.xs,
              0,
              PHSpacing.lg,
            ),
            children: const [
              _PrefixRulesSection(),
              _CourierRulesSection(),
              _PrioritySection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: PHSpacing.md),
      child: PHGroupedSection(title: title, children: [child]),
    );
  }
}

class _PrefixRulesSection extends StatelessWidget {
  const _PrefixRulesSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: '前缀推断',
    child: Column(
      children: [
        const _RuleHeader(),
        for (final rule in StationPickupRules.prefixRules)
          _PrefixRuleRow(rule: rule),
      ],
    ),
  );
}

class _RuleHeader extends StatelessWidget {
  const _RuleHeader();

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final style = PHTypography.caption1.copyWith(color: colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PHSpacing.md,
        PHSpacing.sm,
        PHSpacing.md,
        PHSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('前缀', style: style)),
          Expanded(flex: 3, child: Text('快递', style: style)),
          Expanded(flex: 2, child: Text('区域', style: style)),
        ],
      ),
    );
  }
}

class _PrefixRuleRow extends StatelessWidget {
  final StationPickupRule rule;
  const _PrefixRuleRow({required this.rule});

  @override
  Widget build(BuildContext context) => _InsetRow(
    left: rule.prefixLabel,
    middle: rule.courier?.stationDisplayName ?? '不推断快递',
    right: rule.zone.displayName,
  );
}

class _CourierRulesSection extends StatelessWidget {
  const _CourierRulesSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: '快递区域',
    child: Column(
      children: [
        for (final route in StationPickupRules.courierRouteRules)
          _InsetRow(
            left: route.courier.stationDisplayName,
            middle: '',
            right: route.zoneLabel,
          ),
      ],
    ),
  );
}

class _InsetRow extends StatelessWidget {
  final String left;
  final String middle;
  final String right;
  const _InsetRow({
    required this.left,
    required this.middle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    final style = PHTypography.footnote.copyWith(color: colors.textPrimary);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.separatorDefault)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PHSpacing.md,
        vertical: PHSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(left, style: style)),
          Expanded(flex: 3, child: Text(middle, style: style)),
          Expanded(
            flex: 2,
            child: Text(right, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection();

  @override
  Widget build(BuildContext context) => _Section(
    title: '匹配优先级',
    child: const Padding(
      padding: EdgeInsets.all(PHSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriorityRow('1', '已识别快递优先'),
          _PriorityRow('2', '单一区域快递直接定位'),
          _PriorityRow('3', '多区域快递按前缀细分'),
          _PriorityRow('4', '快递未知时才使用前缀推断'),
          _PriorityRow('5', '仍无法确定则进入未映射'),
          SizedBox(height: PHSpacing.sm),
          Text('A 仅表示大件区，不推断快递公司。'),
        ],
      ),
    ),
  );
}

class _PriorityRow extends StatelessWidget {
  final String number;
  final String text;
  const _PriorityRow(this.number, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 24, child: Text(number)),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

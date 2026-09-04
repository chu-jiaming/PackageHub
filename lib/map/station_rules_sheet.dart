import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/station_pickup_rules.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

Future<void> showStationRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StationRulesSheet(),
  );
}

class _StationRulesSheet extends StatelessWidget {
  const _StationRulesSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, controller) => Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Text('站点规则', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('station-rules-done'),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: const [
                  _PrefixRulesSection(),
                  _CourierRulesSection(),
                  _PrioritySection(),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
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
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text('前缀')),
        Expanded(flex: 3, child: Text('快递')),
        Expanded(flex: 2, child: Text('区域')),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(left)),
        Expanded(flex: 3, child: Text(middle)),
        Expanded(flex: 2, child: Text(right, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection();

  @override
  Widget build(BuildContext context) => _Section(
    title: '匹配优先级',
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriorityRow('1', '已识别快递优先'),
          _PriorityRow('2', '单一区域快递直接定位'),
          _PriorityRow('3', '多区域快递按前缀细分'),
          _PriorityRow('4', '快递未知时才使用前缀推断'),
          _PriorityRow('5', '仍无法确定则进入未映射'),
          SizedBox(height: 12),
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

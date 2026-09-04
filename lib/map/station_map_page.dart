import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/features/credential/pickup_credential_detail_page.dart';
import 'package:packagehub/map/pickup_zone.dart';
import 'package:packagehub/map/pickup_zone_resolver.dart';
import 'package:packagehub/map/station_map_definition.dart';
import 'package:packagehub/map/station_rules_sheet.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/ui/adaptive.dart';

class StationMapPage extends StatefulWidget {
  final PickupCredentialRepositoryApi repository;
  const StationMapPage({super.key, required this.repository});
  @override
  State<StationMapPage> createState() => StationMapPageState();
}

class StationMapPageState extends State<StationMapPage> {
  final _resolver = const PickupZoneResolver();
  final _mapTransformationController = TransformationController();
  bool _mapTransformInitialized = false;
  double? _scaleGestureStartScale;
  Offset? _scaleGestureStartSceneFocalPoint;
  Offset? _scaleGestureStartLocalFocalPoint;
  final _activeMapPointers = <int, Offset>{};
  bool _scaleGestureFocalPointLocked = false;
  bool _correctingScaleTransform = false;
  Map<PickupZoneId, List<PickupCredential>> _groups = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mapTransformationController.addListener(_maintainScaleGestureAnchor);
    load();
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await widget.repository.getAll();
      final groups = <PickupZoneId, List<PickupCredential>>{};
      for (final c in all.where((c) => c.status != PickupStatus.pickedUp)) {
        groups.putIfAbsent(_resolver.resolve(c), () => []).add(c);
      }
      if (mounted) {
        setState(() {
          _groups = groups;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '无法加载取件信息';
        });
      }
    }
  }

  @override
  void dispose() {
    _mapTransformationController.removeListener(_maintainScaleGestureAnchor);
    _mapTransformationController.dispose();
    super.dispose();
  }

  Future<void> _open(StationMapZoneDefinition zone) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .52,
        child: _ZoneSheet(
          key: const Key('station-map-zone-sheet'),
          zone: zone,
          credentials: _groups[zone.id] ?? [],
          repository: widget.repository,
          onChanged: load,
          onOpenDetail: (c) async {
            Navigator.pop(context);
            final changed = await Navigator.of(context).push(
              adaptiveRoute(
                context,
                (_) => PickupCredentialDetailPage(
                  credential: c,
                  repository: widget.repository,
                ),
              ),
            );
            if (changed == true) load();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('站点地图'),
        actions: [
          IconButton(
            key: const Key('station-rules-button'),
            onPressed: () => showStationRulesSheet(context),
            icon: const Icon(CupertinoIcons.list_bullet),
            tooltip: '站点规则',
          ),
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: '重新加载',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(_error!),
                  TextButton(onPressed: load, child: const Text('重新加载')),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 16
                    ? constraints.maxWidth - 16
                    : 0.0;
                final height = width * 1086 / 1448;
                final boundaryMargin = EdgeInsets.symmetric(
                  horizontal: (constraints.maxWidth - width) / 2,
                  vertical: (constraints.maxHeight - height) / 2,
                );
                _initializeMapTransformIfNeeded(
                  viewport: Size(constraints.maxWidth, constraints.maxHeight),
                  content: Size(width, height),
                );
                return SizedBox.expand(
                  key: const Key('station-map-viewport'),
                  child: Listener(
                    onPointerDown: _onMapPointerDown,
                    onPointerUp: _onMapPointerUp,
                    onPointerCancel: _onMapPointerCancel,
                    child: InteractiveViewer(
                      transformationController: _mapTransformationController,
                      minScale: 1,
                      maxScale: 4,
                      panEnabled: true,
                      scaleEnabled: true,
                      onInteractionStart: _onMapInteractionStart,
                      onInteractionUpdate: _onMapInteractionUpdate,
                      onInteractionEnd: _onMapInteractionEnd,
                      interactionEndFrictionCoefficient: 1e9,
                      constrained: false,
                      alignment: Alignment.center,
                      boundaryMargin: boundaryMargin,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        key: const Key('station-map-content'),
                        width: width,
                        height: height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'lib/map/map.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            ...stationMapZones.map(
                              (z) => _hotspot(z, width, height),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_groups[PickupZoneId.unmapped]?.isNotEmpty == true)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: ListTile(
                title: Text('未定位 ${_groups[PickupZoneId.unmapped]!.length}'),
                leading: const Icon(CupertinoIcons.question_circle),
                onTap: () => _open(
                  const StationMapZoneDefinition(
                    id: PickupZoneId.unmapped,
                    label: '未定位',
                    subtitle: '需要确认区域',
                    normalizedRect: Rect.fromLTRB(0, 0, 1, 1),
                  ),
                ),
              ),
            )
          else if (!_loading && _groups.isEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: 64),
              child: Center(child: Text('暂无待取件快递')),
            ),
        ],
      ),
    );
  }

  void _initializeMapTransformIfNeeded({
    required Size viewport,
    required Size content,
  }) {
    if (_mapTransformInitialized) return;
    _mapTransformInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapTransformationController.value = Matrix4.translationValues(
        (viewport.width - content.width) / 2,
        (viewport.height - content.height) / 2,
        0,
      );
    });
  }

  void _onMapInteractionStart(ScaleStartDetails details) {
    _scaleGestureStartScale = _mapTransformationController.value
        .getMaxScaleOnAxis();
    if (_activeMapPointers.length < 2) {
      _scaleGestureStartLocalFocalPoint = null;
      _scaleGestureStartSceneFocalPoint = null;
      _scaleGestureFocalPointLocked = false;
    }
  }

  void _onMapInteractionUpdate(ScaleUpdateDetails details) {
    final startScale = _scaleGestureStartScale;
    final startSceneFocalPoint = _scaleGestureStartSceneFocalPoint;
    final startLocalFocalPoint = _scaleGestureStartLocalFocalPoint;
    if (startScale == null || (details.scale - 1).abs() < .0001) {
      if (startScale != null && !_scaleGestureFocalPointLocked) {
        _scaleGestureStartLocalFocalPoint = details.localFocalPoint;
        _scaleGestureStartSceneFocalPoint = _mapTransformationController
            .toScene(details.localFocalPoint);
      }
      return;
    }

    final lockedLocalFocalPoint =
        startLocalFocalPoint ?? details.localFocalPoint;
    final lockedSceneFocalPoint =
        startSceneFocalPoint ??
        _mapTransformationController.toScene(details.localFocalPoint);
    _scaleGestureStartLocalFocalPoint = lockedLocalFocalPoint;
    _scaleGestureStartSceneFocalPoint = lockedSceneFocalPoint;
    _scaleGestureFocalPointLocked = true;

    final targetScale = (startScale * details.scale).clamp(1.0, 4.0);
    _setScaleMatrixAtLockedAnchor(targetScale);
  }

  void _maintainScaleGestureAnchor() {
    if (!_scaleGestureFocalPointLocked || _correctingScaleTransform) return;
    _setScaleMatrixAtLockedAnchor(
      _mapTransformationController.value.getMaxScaleOnAxis(),
    );
  }

  void _setScaleMatrixAtLockedAnchor(double scale) {
    final lockedLocalFocalPoint = _scaleGestureStartLocalFocalPoint;
    final lockedSceneFocalPoint = _scaleGestureStartSceneFocalPoint;
    if (lockedLocalFocalPoint == null || lockedSceneFocalPoint == null) return;

    final targetMatrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(
        0,
        3,
        lockedLocalFocalPoint.dx - scale * lockedSceneFocalPoint.dx,
      )
      ..setEntry(
        1,
        3,
        lockedLocalFocalPoint.dy - scale * lockedSceneFocalPoint.dy,
      );
    _correctingScaleTransform = true;
    _mapTransformationController.value = targetMatrix;
    _correctingScaleTransform = false;
  }

  void _onMapInteractionEnd(ScaleEndDetails details) {
    _scaleGestureStartScale = null;
    if (_scaleGestureFocalPointLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maintainScaleGestureAnchor();
      });
    }
  }

  void _onMapPointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _activeMapPointers[event.pointer] = event.localPosition;
    if (_activeMapPointers.length != 2) return;

    final points = _activeMapPointers.values.toList();
    final focalPoint = Offset(
      (points[0].dx + points[1].dx) / 2,
      (points[0].dy + points[1].dy) / 2,
    );
    _scaleGestureStartScale = _mapTransformationController.value
        .getMaxScaleOnAxis();
    _scaleGestureStartLocalFocalPoint = focalPoint;
    _scaleGestureStartSceneFocalPoint = _mapTransformationController.toScene(
      focalPoint,
    );
    _scaleGestureFocalPointLocked = true;
  }

  void _onMapPointerUp(PointerUpEvent event) {
    _activeMapPointers.remove(event.pointer);
  }

  void _onMapPointerCancel(PointerCancelEvent event) {
    _activeMapPointers.remove(event.pointer);
  }

  Widget _hotspot(StationMapZoneDefinition z, double w, double h) {
    final items = _groups[z.id] ?? [];
    return Positioned(
      left: z.normalizedRect.left * w,
      top: z.normalizedRect.top * h,
      width: z.normalizedRect.width * w,
      height: z.normalizedRect.height * h,
      child: _StationMapHotspot(
        zone: z,
        count: items.length,
        onTap: () => _open(z),
      ),
    );
  }
}

class StationMapHotspotStyle {
  static BoxDecoration decoration({
    required bool active,
    required bool pressed,
    required Color accent,
  }) {
    return BoxDecoration(
      color: active ? accent.withValues(alpha: pressed ? .16 : .10) : null,
      borderRadius: BorderRadius.zero,
    );
  }

  static BoxDecoration badgeDecoration({
    required Color accent,
    required Color edge,
  }) {
    return BoxDecoration(
      color: accent,
      border: Border.all(color: edge.withValues(alpha: .9), width: 1.2),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    );
  }
}

class _StationMapHotspot extends StatefulWidget {
  final StationMapZoneDefinition zone;
  final int count;
  final VoidCallback onTap;
  const _StationMapHotspot({
    required this.zone,
    required this.count,
    required this.onTap,
  });

  @override
  State<_StationMapHotspot> createState() => _StationMapHotspotState();
}

class _StationMapHotspotState extends State<_StationMapHotspot> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.count > 0;
    final scheme = Theme.of(context).colorScheme;
    final edge = Theme.of(context).brightness == Brightness.dark
        ? scheme.surface
        : Colors.white;
    return Semantics(
      button: true,
      label: '${widget.zone.label}，${widget.zone.subtitle}，${widget.count} 件待取',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: active ? (_) => setState(() => pressed = true) : null,
        onTapUp: active ? (_) => setState(() => pressed = false) : null,
        onTapCancel: active ? () => setState(() => pressed = false) : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: StationMapHotspotStyle.decoration(
                  active: active,
                  pressed: pressed,
                  accent: scheme.primary,
                ),
              ),
            ),
            if (active)
              Align(
                alignment: widget.zone.badgeAnchor,
                child: Container(
                  key: Key('mapBadge_${widget.zone.id.name}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: StationMapHotspotStyle.badgeDecoration(
                    accent: scheme.primary,
                    edge: edge,
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: edge,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoneSheet extends StatefulWidget {
  final StationMapZoneDefinition zone;
  final List<PickupCredential> credentials;
  final PickupCredentialRepositoryApi repository;
  final Future<void> Function() onChanged;
  final Future<void> Function(PickupCredential) onOpenDetail;
  const _ZoneSheet({
    super.key,
    required this.zone,
    required this.credentials,
    required this.repository,
    required this.onChanged,
    required this.onOpenDetail,
  });
  @override
  State<_ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends State<_ZoneSheet> {
  late List<PickupCredential> items;
  final busy = <int>{};
  @override
  void initState() {
    super.initState();
    items = [...widget.credentials];
  }

  Future<void> pick(PickupCredential c) async {
    if (c.id == null || busy.contains(c.id)) return;
    setState(() => busy.add(c.id!));
    try {
      await widget.repository.markPickedUp(c.id!);
      if (mounted) setState(() => items.removeWhere((x) => x.id == c.id));
      await widget.onChanged();
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法更新取件状态')));
      }
    } finally {
      if (mounted) setState(() => busy.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.zone.label} · ${widget.zone.subtitle}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${items.length} 件',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: items.isEmpty
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('这里暂时没有待取件快递'),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: items
                        .map(
                          (c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => widget.onOpenDetail(c),
                            title: Text(
                              c.pickupCode?.trim().isNotEmpty == true
                                  ? c.pickupCode!
                                  : '无取件码',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${c.courierCompany.displayName}${c.trackingNumber == null ? '' : '\n${c.trackingNumber}'}',
                            ),
                            trailing: IconButton(
                              tooltip: '标记为已取件',
                              onPressed: busy.contains(c.id)
                                  ? null
                                  : () => pick(c),
                              icon: const Icon(
                                CupertinoIcons.check_mark_circled,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    ),
  );
}

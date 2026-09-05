import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/design_system/components/ph_badge.dart';
import 'package:packagehub/design_system/components/ph_banner.dart';
import 'package:packagehub/design_system/components/ph_bottom_sheet.dart';
import 'package:packagehub/design_system/components/ph_empty_state.dart';
import 'package:packagehub/design_system/components/ph_grouped_section.dart';
import 'package:packagehub/design_system/components/ph_icon_button.dart';
import 'package:packagehub/design_system/components/ph_list_row.dart';
import 'package:packagehub/design_system/components/ph_navigation_header.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_spacing.dart';
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
  bool _mapCenterUpdateScheduled = false;
  Size? _mapViewportSize;
  Rect? _mapBoundaryRect;
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
      showDragHandle: false,
      isScrollControlled: true,
      builder: (_) => _ZoneSheet(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PHNavigationHeader(
        title: '站点地图',
        actions: [
          PHIconButton(
            key: const Key('station-rules-button'),
            tooltip: '站点规则',
            semanticsLabel: '站点规则',
            onPressed: () => showStationRulesSheet(context),
            icon: const Icon(CupertinoIcons.list_bullet),
          ),
          PHIconButton(
            tooltip: '重新加载',
            semanticsLabel: '重新加载',
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            PHBanner(
              variant: PHBannerVariant.error,
              title: _error!,
              action: TextButton(onPressed: load, child: const Text('重新加载')),
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
                final viewportSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final contentSize = Size(width, height);
                _updateMapGeometry(
                  viewport: viewportSize,
                  content: contentSize,
                  boundaryMargin: boundaryMargin,
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
                      // The controller matrix is calculated in viewport
                      // coordinates. Keeping the render origin at the top-left
                      // prevents Transform from adding a second, scale-dependent
                      // offset around the map's center.
                      alignment: Alignment.topLeft,
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
            PHGroupedSection(
              children: [
                PHListRow(
                  title: '未定位 ${_groups[PickupZoneId.unmapped]!.length}',
                  leading: const Icon(CupertinoIcons.question_circle),
                  onTap: () => _open(
                    const StationMapZoneDefinition(
                      id: PickupZoneId.unmapped,
                      label: '未定位',
                      subtitle: '需要确认区域',
                      normalizedRect: Rect.fromLTRB(0, 0, 1, 1),
                    ),
                  ),
                  showSeparator: false,
                ),
              ],
            )
          else if (!_loading && _groups.isEmpty)
            const PHEmptyState(title: '暂无待取件快递'),
        ],
      ),
    );
  }

  void _updateMapGeometry({
    required Size viewport,
    required Size content,
    required EdgeInsets boundaryMargin,
  }) {
    final boundary = boundaryMargin.inflateRect(Offset.zero & content);
    final geometryChanged =
        viewport != _mapViewportSize || boundary != _mapBoundaryRect;
    _mapViewportSize = viewport;
    _mapBoundaryRect = boundary;

    if (!_mapTransformInitialized) {
      _mapTransformInitialized = true;
      _scheduleMapCenterAtMinimumScale();
    } else if (geometryChanged) {
      _scheduleMapCenterAtMinimumScale();
    }
  }

  void _scheduleMapCenterAtMinimumScale() {
    if (_mapCenterUpdateScheduled) return;
    _mapCenterUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapCenterUpdateScheduled = false;
      if (!mounted || _scaleGestureFocalPointLocked) return;
      final boundary = _mapBoundaryRect;
      if (boundary == null ||
          (_mapTransformationController.value.getMaxScaleOnAxis() - 1).abs() >
              .0001) {
        return;
      }
      _mapTransformationController.value = Matrix4.translationValues(
        -boundary.left,
        -boundary.top,
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

    final unclampedTranslation = Offset(
      lockedLocalFocalPoint.dx - scale * lockedSceneFocalPoint.dx,
      lockedLocalFocalPoint.dy - scale * lockedSceneFocalPoint.dy,
    );
    final translation = _clampMapTranslation(unclampedTranslation, scale);
    final targetMatrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, translation.dx)
      ..setEntry(1, 3, translation.dy);
    _correctingScaleTransform = true;
    _mapTransformationController.value = targetMatrix;
    _correctingScaleTransform = false;
  }

  Offset _clampMapTranslation(Offset translation, double scale) {
    final viewport = _mapViewportSize;
    final boundary = _mapBoundaryRect;
    if (viewport == null || boundary == null) return translation;

    double clampAxis({
      required double value,
      required double viewportExtent,
      required double boundaryStart,
      required double boundaryEnd,
    }) {
      final minimum = viewportExtent - scale * boundaryEnd;
      final maximum = -scale * boundaryStart;
      if (minimum > maximum) return (minimum + maximum) / 2;
      return value.clamp(minimum, maximum).toDouble();
    }

    return Offset(
      clampAxis(
        value: translation.dx,
        viewportExtent: viewport.width,
        boundaryStart: boundary.left,
        boundaryEnd: boundary.right,
      ),
      clampAxis(
        value: translation.dy,
        viewportExtent: viewport.height,
        boundaryStart: boundary.top,
        boundaryEnd: boundary.bottom,
      ),
    );
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
    final colors = PHColorScheme.of(context);
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
                  accent: colors.iconAccent,
                ),
              ),
            ),
            if (active)
              Align(
                alignment: widget.zone.badgeAnchor,
                child: PHBadge(
                  key: Key('mapBadge_${widget.zone.id.name}'),
                  label: '${widget.count}',
                  variant: PHBadgeVariant.accent,
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
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * .7;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: PHBottomSheet(
        sizing: PHBottomSheetSizing.scrollable,
        title: '${widget.zone.label} · ${widget.zone.subtitle}',
        subtitle: '${items.length} 件',
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(0, PHSpacing.xs, 0, PHSpacing.lg),
          children: [
            if (items.isEmpty)
              const PHEmptyState(title: '这里暂时没有待取件快递')
            else
              PHGroupedSection(
                children: [
                  for (var index = 0; index < items.length; index++)
                    PHListRow(
                      title: items[index].pickupCode?.trim().isNotEmpty == true
                          ? items[index].pickupCode!
                          : '无取件码',
                      subtitle:
                          '${items[index].courierCompany.displayName}${items[index].trackingNumber == null ? '' : '\n${items[index].trackingNumber}'}',
                      onTap: () => widget.onOpenDetail(items[index]),
                      showChevron: false,
                      showSeparator: index < items.length - 1,
                      trailing: PHIconButton(
                        tooltip: '标记为已取件',
                        semanticsLabel: '标记为已取件',
                        onPressed: busy.contains(items[index].id)
                            ? null
                            : () => pick(items[index]),
                        icon: const Icon(CupertinoIcons.check_mark_circled),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

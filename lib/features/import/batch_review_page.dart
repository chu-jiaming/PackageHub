import 'dart:io';

import 'package:flutter/material.dart';
import 'package:packagehub/features/import/image_preview_page.dart';
import 'package:packagehub/features/import/pickup_review_form.dart';
import 'package:packagehub/features/import/pickup_review_item.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';

class PickupReviewGroup {
  final String imagePath;
  final List<PickupCredentialDraft> drafts;

  PickupReviewGroup({
    required this.imagePath,
    required List<PickupCredentialDraft> drafts,
  }) : drafts = List.of(drafts);

  PickupReviewGroup copy() =>
      PickupReviewGroup(imagePath: imagePath, drafts: drafts);
}

class BatchReviewPage extends StatefulWidget {
  final List<PickupReviewItem> items;
  final List<PickupReviewGroup> groups;
  final bool legacyFlat;

  BatchReviewPage({
    super.key,
    required List<PickupCredentialDraft> drafts,
    List<String?>? imagePaths,
  }) : items = List.generate(
         drafts.length,
         (index) => PickupReviewItem(
           imagePath:
               imagePaths != null &&
                   index < imagePaths.length &&
                   imagePaths[index] != null
               ? imagePaths[index]!
               : '',
           draft: drafts[index],
         ),
       ),
       groups = [
         for (var i = 0; i < drafts.length; i++)
           PickupReviewGroup(
             imagePath: imagePaths != null && i < imagePaths.length
                 ? imagePaths[i] ?? ''
                 : '',
             drafts: [drafts[i]],
           ),
       ],
       legacyFlat = false;

  BatchReviewPage.withItems({super.key, required this.items})
    : groups = [
        for (final item in items)
          PickupReviewGroup(imagePath: item.imagePath, drafts: [item.draft]),
      ],
      legacyFlat = true;

  const BatchReviewPage.withGroups({super.key, required this.groups})
    : items = const [],
      legacyFlat = false;

  @override
  State<BatchReviewPage> createState() => _BatchReviewPageState();
}

class _BatchReviewPageState extends State<BatchReviewPage> {
  late List<PickupReviewGroup> _groups;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _groups = widget.groups.map((group) => group.copy()).toList();
    if (_groups.length == 1 && _groups.single.drafts.length == 1) {
      _editingIndex = 0;
    }
  }

  void _updateDraft(
    int groupIndex,
    int draftIndex,
    PickupCredentialDraft draft,
  ) {
    setState(() {
      _groups[groupIndex].drafts[draftIndex] = draft;
    });
  }

  void _editItem(int index) {
    setState(() {
      _editingIndex = index;
    });
  }

  void _finishEditing(int index) {
    if (_editingIndex != index) {
      return;
    }

    setState(() {
      _editingIndex = null;
    });
  }

  void _removeDraft(int groupIndex, int draftIndex) {
    setState(() {
      _groups[groupIndex].drafts.removeAt(draftIndex);
    });
  }

  Future<void> _previewImage(String imagePath) async {
    if (imagePath.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(imagePath: imagePath),
      ),
    );
  }

  void _confirmAll() {
    Navigator.of(context).pop<List<PickupCredentialDraft>>([
      for (final group in _groups) ...group.drafts,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认取件信息')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const Text(
              '确认取件信息',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${_groups.fold<int>(0, (sum, group) => sum + group.drafts.length)} 个识别结果',
              key: const Key('batchReviewCountText'),
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            if (_groups.isEmpty ||
                _groups.every((group) => group.drafts.isEmpty))
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '暂无可核对的取件信息',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else if (widget.legacyFlat)
              for (var index = 0; index < _groups.length; index++) ...[
                _BatchReviewCard(
                  key: Key('batchReviewItem_$index'),
                  item: PickupReviewItem(
                    imagePath: _groups[index].imagePath,
                    draft: _groups[index].drafts.single,
                  ),
                  index: index,
                  isEditing: _editingIndex == index,
                  onEdit: () => _editItem(index),
                  onChanged: (draft) => _updateDraft(index, 0, draft),
                  onComplete: () => _finishEditing(index),
                  onRemove: () => _removeDraft(index, 0),
                  onPreviewImage: () => _previewImage(_groups[index].imagePath),
                ),
                const SizedBox(height: 12),
              ]
            else
              for (
                var groupIndex = 0;
                groupIndex < _groups.length;
                groupIndex++
              ) ...[
                if (_groups[groupIndex].drafts.isNotEmpty)
                  _BatchReviewGroup(
                    key: Key('batchReviewGroup_$groupIndex'),
                    group: _groups[groupIndex],
                    groupIndex: groupIndex,
                    editingIndex: _editingIndex,
                    onEdit: (index) => _editItem(index),
                    onChanged: (draftIndex, draft) =>
                        _updateDraft(groupIndex, draftIndex, draft),
                    onComplete: _finishEditing,
                    onRemove: (index) => _removeDraft(groupIndex, index),
                    onPreviewImage: () =>
                        _previewImage(_groups[groupIndex].imagePath),
                  ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('confirmAllButton'),
                onPressed: _groups.every((group) => group.drafts.isEmpty)
                    ? null
                    : _confirmAll,
                child: const Text('确认全部'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchReviewGroup extends StatelessWidget {
  final PickupReviewGroup group;
  final int groupIndex;
  final int? editingIndex;
  final ValueChanged<int> onEdit;
  final void Function(int, PickupCredentialDraft) onChanged;
  final ValueChanged<int> onComplete;
  final ValueChanged<int> onRemove;
  final VoidCallback onPreviewImage;

  const _BatchReviewGroup({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.editingIndex,
    required this.onEdit,
    required this.onChanged,
    required this.onComplete,
    required this.onRemove,
    required this.onPreviewImage,
  });

  @override
  Widget build(BuildContext context) {
    var base = 0;
    final parent = context.findAncestorStateOfType<_BatchReviewPageState>();
    if (parent != null) {
      for (var i = 0; i < groupIndex; i++) {
        base += parent._groups[i].drafts.length;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewScreenshotPreview(
          key: Key('reviewGroupScreenshot_$groupIndex'),
          imagePath: group.imagePath,
          width: double.infinity,
          height: 190,
          cacheWidth: 800,
          onTap: onPreviewImage,
        ),
        const SizedBox(height: 10),
        Text('识别出 ${group.drafts.length} 个取件凭证'),
        const SizedBox(height: 10),
        for (var i = 0; i < group.drafts.length; i++) ...[
          _BatchReviewCard(
            key: Key('batchReviewItem_${base + i}'),
            item: PickupReviewItem(imagePath: '', draft: group.drafts[i]),
            index: base + i,
            isEditing: editingIndex == base + i,
            showPreview: false,
            onEdit: () => onEdit(base + i),
            onChanged: (draft) => onChanged(i, draft),
            onComplete: () => onComplete(base + i),
            onRemove: () => onRemove(i),
            onPreviewImage: onPreviewImage,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BatchReviewCard extends StatelessWidget {
  final PickupReviewItem item;
  final int index;
  final bool isEditing;
  final VoidCallback onEdit;
  final ValueChanged<PickupCredentialDraft> onChanged;
  final VoidCallback onComplete;
  final VoidCallback onPreviewImage;
  final bool showPreview;
  final VoidCallback? onRemove;

  const _BatchReviewCard({
    super.key,
    required this.item,
    required this.index,
    required this.isEditing,
    required this.onEdit,
    required this.onChanged,
    required this.onComplete,
    required this.onPreviewImage,
    this.showPreview = true,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: isEditing ? _buildEditingContent() : _buildCompactContent(),
    );
  }

  Widget _buildCompactContent() {
    final draft = item.draft;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview)
          _ReviewScreenshotPreview(
            key: Key('reviewScreenshot_$index'),
            imagePath: item.imagePath,
            width: 116,
            height: 178,
            cacheWidth: 420,
            onTap: onPreviewImage,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _companyName(draft),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(draft.pickupCode ?? '取件码未识别'),
              if (draft.trackingNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  draft.trackingNumber!,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 4),
              Text(draft.status.displayName),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: Key('editDraftButton_$index'),
                  onPressed: onEdit,
                  child: const Text('编辑'),
                ),
              ),
              if (onRemove != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('removeDraftButton_$index'),
                    onPressed: onRemove,
                    child: const Text('移除'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview)
          _ReviewScreenshotPreview(
            key: Key('reviewScreenshot_$index'),
            imagePath: item.imagePath,
            height: 260,
            width: double.infinity,
            cacheWidth: 800,
            onTap: onPreviewImage,
          ),
        const SizedBox(height: 18),
        PickupReviewForm(
          key: ValueKey('pickupReviewForm_$index'),
          draft: item.draft,
          onChanged: onChanged,
          onComplete: onComplete,
        ),
      ],
    );
  }

  static String _companyName(PickupCredentialDraft draft) {
    if (draft.courierCompany == CourierCompany.unknown) {
      return '未识别快递公司';
    }

    return draft.courierCompany.displayName;
  }
}

class _ReviewScreenshotPreview extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final int cacheWidth;
  final VoidCallback onTap;

  const _ReviewScreenshotPreview({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.cacheWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: imagePath.isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Colors.black,
            child: imagePath.isEmpty
                ? Icon(Icons.image_outlined, color: Colors.grey.shade500)
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    cacheWidth: cacheWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade500,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

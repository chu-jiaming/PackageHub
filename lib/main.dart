import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packagehub/core/database/packagehub_database.dart';
import 'package:packagehub/core/duplicate/pickup_duplicate_detector.dart';
import 'package:packagehub/core/repository/pickup_credential_repository.dart';
import 'package:packagehub/features/credential/pickup_credential_card.dart';
import 'package:packagehub/features/credential/pickup_credential_detail_page.dart';
import 'package:packagehub/features/home/credential_grouping.dart';
import 'package:packagehub/features/import/batch_import_page.dart';
import 'package:packagehub/features/import/duplicate_review_page.dart';
import 'package:packagehub/features/import/batch_review_page.dart';
import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/ui/adaptive.dart';
import 'package:packagehub/core/launcher/identity_launcher.dart';
import 'package:packagehub/features/identity/identity_hub_page.dart';
import 'package:packagehub/features/settings/pickup_reminder_settings_page.dart';
import 'package:packagehub/core/reminder/pickup_reminder_service.dart';
import 'package:packagehub/core/reminder/pickup_notification_service.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';
import 'package:packagehub/map/station_map_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:packagehub/account/account_hub.dart';
import 'package:packagehub/account/account_repository.dart';
import 'package:packagehub/account/mock_account_repository.dart';
import 'package:packagehub/account/account_api_client.dart';
import 'package:packagehub/account/real_account_repository.dart';
import 'package:packagehub/subscription/mock_subscription_repository.dart';
import 'package:packagehub/subscription/subscription_repository.dart';
import 'package:packagehub/subscription/subscription_entitlement.dart';
import 'package:packagehub/subscription/entitlement_pro_feature_access.dart';
import 'package:packagehub/subscription/pro_feature.dart';
import 'package:packagehub/subscription/pro_feature_access.dart';
import 'package:packagehub/subscription/pro_upgrade_sheet.dart';
import 'package:packagehub/subscription/storekit_client.dart';
import 'package:packagehub/subscription/storekit_subscription_repository.dart';
import 'package:packagehub/subscription/backend_subscription_repository.dart';
import 'package:packagehub/subscription/debug/debug_subscription_override.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = PackageHubDatabase.instance;
  final repository = PickupCredentialRepository(database);

  const baseUrl = String.fromEnvironment('PACKAGEHUB_API_BASE_URL');
  final account = RealAccountRepository(
    api: baseUrl.isEmpty ? null : AccountApiClient(baseUrl),
  );
  account.restoreSession();
  final storeKit = StoreKitSubscriptionRepository(
    client: MethodChannelStoreKitClient(),
    accountRepository: account,
  );
  final subscription = baseUrl.isEmpty
      ? storeKit
      : BackendSubscriptionRepository(
          account: account,
          api: AccountApiClient(baseUrl),
          storeKit: MethodChannelStoreKitClient(),
          verifier:
              const String.fromEnvironment('PACKAGEHUB_ENTITLEMENT_PUBLIC_KEY')
                  .isEmpty
              ? const RejectingEntitlementTokenVerifier()
              : Es256EntitlementTokenVerifier(
                  const String.fromEnvironment(
                    'PACKAGEHUB_ENTITLEMENT_PUBLIC_KEY',
                  ),
                ),
        );
  final debugOverrideController = DebugSubscriptionOverrideController();
  final resolvedSubscription = ResolvedSubscriptionRepository(
    backendSubscriptionRepository: subscription,
    debugOverrideController: debugOverrideController,
  );
  runApp(
    PackageHubApp(
      repository: repository,
      accountRepository: account,
      subscriptionRepository: resolvedSubscription,
    ),
  );
}

typedef ImagePathPicker = Future<List<String>> Function();
typedef ImportPageBuilder = Widget Function(List<String> imagePaths);

Future<List<String>> pickGalleryImagePaths() async {
  final images = await ImagePicker().pickMultiImage(limit: kMaxBatchImageCount);
  return normalizeBatchImagePaths(images.map((image) => image.path));
}

class PackageHubApp extends StatelessWidget {
  final PickupCredentialRepositoryApi repository;
  final AccountRepository accountRepository;
  final SubscriptionRepository subscriptionRepository;

  const PackageHubApp({
    super.key,
    required this.repository,
    this.accountRepository = const MockAccountRepository(),
    this.subscriptionRepository = const MockSubscriptionRepository(),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionEntitlement>(
      stream: subscriptionRepository.changes,
      initialData: subscriptionRepository.current,
      builder: (context, _) => MaterialApp(
        title: 'PackageHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F2F7),
          splashFactory: InkSparkle.splashFactory,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A84FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF000000),
        ),
        themeMode: ThemeMode.system,
        home: PackageHubShell(
          repository: repository,
          accountRepository: accountRepository,
          subscriptionRepository: subscriptionRepository,
          proFeatureAccess: EntitlementProFeatureAccess(subscriptionRepository),
        ),
      ),
    );
  }
}

class PackageHubShell extends StatefulWidget {
  final PickupCredentialRepositoryApi repository;
  final IdentityLauncherApi? identityLauncher;
  final AccountRepository accountRepository;
  final SubscriptionRepository subscriptionRepository;
  final ProFeatureAccess? proFeatureAccess;

  const PackageHubShell({
    super.key,
    required this.repository,
    this.identityLauncher,
    this.accountRepository = const MockAccountRepository(),
    this.subscriptionRepository = const MockSubscriptionRepository(),
    this.proFeatureAccess,
  });

  @override
  State<PackageHubShell> createState() => _PackageHubShellState();
}

class _PackageHubShellState extends State<PackageHubShell> {
  int _index = 0;
  bool _accountHubOpen = false;
  final _homeKey = GlobalKey<_HomePageState>();
  final _mapKey = GlobalKey<StationMapPageState>();

  void _selectTab(int index) {
    setState(() => _index = index);
    if (index == 0) {
      _homeKey.currentState?._loadCredentials();
    } else if (index == 1) {
      _mapKey.currentState?.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomePage(
                key: _homeKey,
                repository: widget.repository,
                onAccountTap: () => setState(() => _accountHubOpen = true),
                proFeatureAccess: widget.proFeatureAccess,
                subscriptionRepository: widget.subscriptionRepository,
              ),
              StationMapPage(key: _mapKey, repository: widget.repository),
              IdentityHubPage(
                launcher: widget.identityLauncher ?? IdentityLauncher(),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: '取件',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.map),
                label: '地图',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_2_outlined),
                label: '身份码',
              ),
            ],
          ),
        ),
        if (_accountHubOpen)
          AccountHub(
            accountRepository: widget.accountRepository,
            subscriptionRepository: widget.subscriptionRepository,
            onDismiss: () => setState(() => _accountHubOpen = false),
          ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  final PickupCredentialRepositoryApi repository;
  final ImagePathPicker? imagePathPicker;
  final ImportPageBuilder? importPageBuilder;
  final VoidCallback? onAccountTap;
  final ProFeatureAccess? proFeatureAccess;
  final SubscriptionRepository? subscriptionRepository;

  const HomePage({
    super.key,
    required this.repository,
    this.imagePathPicker,
    this.importPageBuilder,
    this.onAccountTap,
    this.proFeatureAccess,
    this.subscriptionRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PickupCredential> _credentials = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  final Set<int> _updatingCredentialIds = {};
  String? _saveErrorMessage;
  List<PickupCredentialDraft>? _draftsWaitingForRetry;
  late final Future<void> _loadingFuture;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  bool _isBatchOperating = false;
  PickupReminderSettings _reminderSettings = const PickupReminderSettings();
  final _reminderService = const PickupReminderService();
  final _notificationService = PickupNotificationService();

  ProFeatureAccess? get _proAccess => widget.proFeatureAccess;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadCredentials();
  }

  /// Expose loading future for testing.
  Future<void> get loadingFuture => _loadingFuture;

  Future<void> _loadCredentials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credentials = await widget.repository.getAll();
      final reminderSettings = widget.repository is PickupCredentialRepository
          ? await (widget.repository as PickupCredentialRepository)
                .getReminderSettings()
          : const PickupReminderSettings();
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _reminderSettings = reminderSettings;
          _selectedIds.retainAll(_credentialIds);
          _isLoading = false;
        });
        if (widget.repository is PickupCredentialRepository) {
          await _notificationService.sync(
            credentials,
            settings: reminderSettings,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '无法加载取件凭证';
        });
      }
    }
  }

  Future<void> _openReminderSettings() async {
    final repository = widget.repository;
    if (repository is! PickupCredentialRepository) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupReminderSettingsPage(repository: repository),
      ),
    );
    await _loadCredentials();
  }

  Future<void> _openCredentialDetail(PickupCredential credential) async {
    if (_isSelectionMode) {
      _toggleSelection(credential);
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      adaptiveRoute(
        context,
        (context) => PickupCredentialDetailPage(
          credential: credential,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _loadCredentials();
    }
  }

  Future<void> _confirmDeleteCredential(PickupCredential credential) async {
    final id = credential.id;
    if (id == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法删除取件凭证')));
      return;
    }

    final confirmed = await showAdaptiveDeleteDialog(
      context,
      title: '删除取件凭证？',
      content: '删除后无法恢复。',
      cancelKey: const Key('cancelDeleteCredentialButton'),
      confirmKey: const Key('confirmDeleteCredentialButton'),
    );

    if (confirmed == true) {
      await _deleteCredential(id);
    }
  }

  Future<void> _deleteCredential(int id) async {
    try {
      await widget.repository.deleteById(id);
      await _loadCredentials();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法删除取件凭证')));
      }
    }
  }

  Future<void> _markPickedUp(PickupCredential credential) async {
    HapticFeedback.lightImpact();
    await _runLifecycleAction(
      credential,
      () => widget.repository.markPickedUp(credential.id!),
      successMessage: '已标记为已取件',
    );
  }

  Future<void> _markPending(PickupCredential credential) async {
    final limit = _proAccess?.activeCredentialLimit;
    if (limit != null && await _activeCredentialCount() >= limit) {
      await _showActiveLimitUpsell();
      return;
    }
    await _runLifecycleAction(
      credential,
      () => widget.repository.markPending(credential.id!),
      successMessage: '已恢复为待取件',
    );
  }

  Future<int> _activeCredentialCount() async {
    final repository = widget.repository;
    if (repository is PickupCredentialRepository) {
      return repository.countActiveCredentials();
    }
    return (await repository.getAll())
        .where((item) => item.status != PickupStatus.pickedUp)
        .length;
  }

  Future<void> _showActiveLimitUpsell() async {
    final subscriptionRepository = widget.subscriptionRepository;
    if (subscriptionRepository == null) return;
    await showProUpgradeSheet(
      context,
      subscriptionRepository: subscriptionRepository,
      title: '管理更多取件凭证',
      body: 'PackageHub Free 最多可同时管理 3 个待取件凭证。\n\nPro：无限管理待取件凭证。',
    );
  }

  Future<void> _runLifecycleAction(
    PickupCredential credential,
    Future<PickupCredential> Function() action, {
    required String successMessage,
  }) async {
    final id = credential.id;
    if (id == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法更新取件状态')));
      return;
    }

    if (_updatingCredentialIds.contains(id)) {
      return;
    }

    setState(() {
      _updatingCredentialIds.add(id);
    });

    try {
      await action();
      await _loadCredentials();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法更新取件状态')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingCredentialIds.remove(id);
        });
      }
    }
  }

  Future<void> _pickScreenshot() async {
    final rawImagePaths =
        await (widget.imagePathPicker ?? pickGalleryImagePaths)();
    final imagePaths = normalizeBatchImagePaths(rawImagePaths);

    if (imagePaths.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (rawImagePaths.length > imagePaths.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('一次最多处理 10 张截图，已导入前 10 张')));
    }

    final confirmedDrafts = await Navigator.of(context)
        .push<List<PickupCredentialDraft>>(
          adaptiveRoute(
            context,
            (context) =>
                (widget.importPageBuilder ?? _defaultImportPageBuilder)(
                  imagePaths,
                ),
          ),
        );

    if (!mounted) {
      return;
    }

    if (confirmedDrafts == null || confirmedDrafts.isEmpty) {
      return;
    }

    final draftsToInsert = await _resolveDuplicateDrafts(confirmedDrafts);
    if (!mounted || draftsToInsert == null) {
      return;
    }

    if (draftsToInsert.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已跳过重复凭证')));
      return;
    }

    await _saveDrafts(draftsToInsert);
  }

  Future<List<PickupCredentialDraft>?> _resolveDuplicateDrafts(
    List<PickupCredentialDraft> confirmedDrafts,
  ) async {
    final duplicateResult = await PickupDuplicateDetector(
      repository: widget.repository,
    ).check(confirmedDrafts);

    if (!mounted) {
      return null;
    }

    if (!duplicateResult.hasDuplicates) {
      return confirmedDrafts;
    }

    return Navigator.of(context).push<List<PickupCredentialDraft>>(
      adaptiveRoute(
        context,
        (context) => DuplicateReviewPage(result: duplicateResult),
      ),
    );
  }

  Future<void> _saveDrafts(List<PickupCredentialDraft> drafts) async {
    if (_isSaving) {
      return;
    }

    if (drafts.isEmpty) {
      return;
    }

    final limit = _proAccess?.activeCredentialLimit;
    if (limit != null) {
      final currentActiveCount = await _activeCredentialCount();
      final newActiveCount = drafts
          .where((draft) => draft.status != PickupStatus.pickedUp)
          .length;
      if (currentActiveCount + newActiveCount > limit) {
        final subscriptionRepository = widget.subscriptionRepository;
        if (subscriptionRepository == null) return;
        if (!mounted) return;
        final openedPro = await showProUpgradeSheet(
          context,
          subscriptionRepository: subscriptionRepository,
          title: '管理更多取件凭证',
          body:
              'PackageHub Free 最多可同时管理 3 个待取件凭证。\n'
              '当前已有 $currentActiveCount 个，本次将新增 $newActiveCount 个。',
        );
        if (!mounted) return;
        if (!openedPro) {
          final revised = await Navigator.of(context)
              .push<List<PickupCredentialDraft>>(
                MaterialPageRoute(
                  builder: (_) => BatchReviewPage(drafts: drafts),
                ),
              );
          if (revised != null && revised.isNotEmpty) await _saveDrafts(revised);
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
      _draftsWaitingForRetry = null;
    });

    try {
      await widget.repository.insertAll(drafts);
      await _loadCredentials();

      if (mounted) {
        final count = drafts.length;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count == 1 ? '已添加 1 个取件凭证' : '已添加 $count 个取件凭证'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveErrorMessage = '无法保存取件信息';
          _draftsWaitingForRetry = List<PickupCredentialDraft>.of(drafts);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法保存取件信息'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () {
                final retryDrafts = _draftsWaitingForRetry;
                if (retryDrafts != null) {
                  _saveDrafts(retryDrafts);
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<int> get _credentialIds =>
      _credentials.map((credential) => credential.id).whereType<int>().toList();

  bool get _hasSelection => _selectedIds.isNotEmpty;

  bool get _areAllCredentialsSelected {
    final ids = _credentialIds;
    return ids.isNotEmpty && ids.every(_selectedIds.contains);
  }

  String get _selectionCountText => '已选择 ${_selectedIds.length} 个';

  void _enterSelectionMode([PickupCredential? credential]) {
    if (_isBatchOperating) {
      return;
    }

    final subscriptionRepository = widget.subscriptionRepository;
    if (_proAccess != null &&
        !_proAccess!.canUse(ProFeature.batchManagement) &&
        subscriptionRepository != null) {
      showProUpgradeSheet(
        context,
        subscriptionRepository: subscriptionRepository,
        title: '批量管理属于 PackageHub Pro',
        body: '升级 Pro 后可批量标记已取件和批量删除。',
        secondaryLabel: '取消',
      );
      return;
    }

    setState(() {
      _isSelectionMode = true;
      final id = credential?.id;
      if (id != null) {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    if (_isBatchOperating) {
      return;
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(PickupCredential credential) {
    final id = credential.id;
    if (id == null || _isBatchOperating) {
      return;
    }

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _selectAllOrClear() {
    if (_isBatchOperating) {
      return;
    }

    setState(() {
      if (_areAllCredentialsSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_credentialIds);
      }
    });
  }

  Future<void> _markSelectedPickedUp() async {
    await _runBatchUpdate(
      () => widget.repository.markPickedUpAll(_selectedIds),
      successMessageBuilder: (count) =>
          count == 1 ? '已标记 1 个凭证为已取件' : '已标记 $count 个凭证为已取件',
    );
  }

  Future<void> _markSelectedPending() async {
    await _runBatchUpdate(
      () => widget.repository.markPendingAll(_selectedIds),
      successMessageBuilder: (count) =>
          count == 1 ? '已恢复 1 个凭证为待取件' : '已恢复 $count 个凭证为待取件',
    );
  }

  Future<void> _runBatchUpdate(
    Future<List<PickupCredential>> Function() action, {
    required String Function(int count) successMessageBuilder,
  }) async {
    if (_isBatchOperating || _selectedIds.isEmpty) {
      return;
    }

    final selectedCount = _selectedIds.length;
    setState(() {
      _isBatchOperating = true;
    });

    try {
      await action();
      await _loadCredentials();
      if (mounted) {
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessageBuilder(selectedCount))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法更新取件状态')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchOperating = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    if (_isBatchOperating || _selectedIds.isEmpty) {
      return;
    }

    final selectedCount = _selectedIds.length;
    final confirmed = await showAdaptiveDeleteDialog(
      context,
      title: '删除 $selectedCount 个取件凭证？',
      content: '删除后无法恢复。',
      cancelKey: const Key('cancelBatchDeleteButton'),
      confirmKey: const Key('confirmBatchDeleteButton'),
    );

    if (confirmed == true) {
      await _deleteSelected();
    }
  }

  Future<void> _deleteSelected() async {
    if (_isBatchOperating || _selectedIds.isEmpty) {
      return;
    }

    final selectedCount = _selectedIds.length;
    final selectedIds = Set<int>.of(_selectedIds);
    setState(() {
      _isBatchOperating = true;
    });

    try {
      await widget.repository.deleteAll(selectedIds);
      await _loadCredentials();
      if (mounted) {
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('已删除 $selectedCount 个取件凭证')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法删除取件凭证')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchOperating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'PackageHub',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              key: const Key('pickupReminderSettingsButton'),
              tooltip: '取件提醒设置',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _openReminderSettings,
            ),
          if (_isSelectionMode) ...[
            TextButton(
              key: const Key('selectAllCredentialsButton'),
              onPressed: _isBatchOperating ? null : _selectAllOrClear,
              child: Text(_areAllCredentialsSelected ? '取消全选' : '全选'),
            ),
            TextButton(
              key: const Key('cancelSelectionModeButton'),
              onPressed: _isBatchOperating ? null : _exitSelectionMode,
              child: const Text('取消'),
            ),
          ] else
            TextButton(
              key: const Key('enterSelectionModeButton'),
              onPressed: _credentials.isEmpty || _isLoading
                  ? null
                  : () => _enterSelectionMode(),
              child: const Text('批量操作'),
            ),
        ],
        leading: !_isSelectionMode
            ? Semantics(
                button: true,
                label: '账户',
                child: IconButton(
                  key: const Key('accountAvatarButton'),
                  tooltip: '账户',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Icons.account_circle, size: 34),
                  onPressed: widget.onAccountTap,
                ),
              )
            : null,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _isSelectionMode ? _buildBatchActionBar() : null,
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'addScreenshot',
              onPressed: _isSaving ? null : _pickScreenshot,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('添加截图'),
            ),
    );
  }

  Widget _buildBody() {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = _buildErrorState();
    } else if (_credentials.isEmpty) {
      body = _buildEmptyState();
    } else {
      body = _buildCredentialList();
    }

    final due = _reminderService.dueCredentials(
      _credentials,
      settings: _reminderSettings,
    );
    if (_saveErrorMessage == null && due.isEmpty) {
      return body;
    }

    return Column(
      children: [
        if (due.isNotEmpty)
          MaterialBanner(
            key: const Key('pickupReminderBanner'),
            leading: const Icon(Icons.notifications_active_outlined),
            content: Text(
              '有 ${due.length} 个包裹已超过 ${_reminderSettings.days} 天未取件',
            ),
            actions: const [SizedBox.shrink()],
          ),
        if (_saveErrorMessage != null) _buildSaveErrorBanner(),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _loadCredentials,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              '暂无取件凭证',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Text(
                  '添加快递截图后，',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                Text(
                  'PackageHub 会自动识别取件信息。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveErrorBanner() {
    final retryDrafts = _draftsWaitingForRetry;

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _saveErrorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const Key('retrySaveButton'),
              onPressed: _isSaving || retryDrafts == null
                  ? null
                  : () => _saveDrafts(retryDrafts),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialList() {
    final pendingCredentials = _credentials
        .where((credential) => credential.status == PickupStatus.pending)
        .toList();
    final unknownCredentials = _credentials
        .where((credential) => credential.status == PickupStatus.unknown)
        .toList();
    final pickedUpCredentials = _credentials
        .where((credential) => credential.status == PickupStatus.pickedUp)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadCredentials,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, _isSelectionMode ? 24 : 96),
        children: [
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _selectionCountText,
                key: const Key('selectedCredentialCount'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _buildCredentialSection('待取件', pendingCredentials),
          _buildCredentialSection('未判断', unknownCredentials),
          _buildCredentialSection('已取件', pickedUpCredentials),
        ].whereType<Widget>().toList(),
      ),
    );
  }

  Widget? _buildCredentialSection(
    String title,
    List<PickupCredential> credentials,
  ) {
    if (credentials.isEmpty) {
      return null;
    }

    return Semantics(
      container: true,
      child: Column(
        key: Key('credentialSection-$title'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 8),
            child: Text(
              '$title · ${credentials.length}',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final group in groupCredentialsByCourier(credentials))
            _buildCourierGroup(group),
        ],
      ),
    );
  }

  Widget _buildCourierGroup(CourierCredentialGroup group) {
    return Column(
      key: Key('credentialCourierGroup-${group.courierCompany.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            '${group.courierCompany.displayName} · ${group.credentials.length}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        for (final credential in group.credentials)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PickupCredentialCard(
              credential: credential,
              isSelectionMode: _isSelectionMode,
              isSelected:
                  credential.id != null && _selectedIds.contains(credential.id),
              isUpdating:
                  credential.id != null &&
                  _updatingCredentialIds.contains(credential.id),
              onTap: () => _openCredentialDetail(credential),
              onSelectionChanged: (_) => _toggleSelection(credential),
              onDelete: () => _confirmDeleteCredential(credential),
              onMarkPickedUp: credential.status == PickupStatus.pending
                  ? () => _markPickedUp(credential)
                  : null,
              onMarkPending: credential.status == PickupStatus.pickedUp
                  ? () => _markPending(credential)
                  : null,
              showCourierCompany: false,
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBatchActionBar() {
    final hasSelection = _hasSelection;
    final canOperate = hasSelection && !_isBatchOperating;

    return SafeArea(
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isBatchOperating ? '处理中...' : _selectionCountText,
                  key: const Key('batchSelectedCredentialCount'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      key: const Key('batchMarkPickedUpButton'),
                      onPressed: canOperate ? _markSelectedPickedUp : null,
                      child: const Text('已取件'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      key: const Key('batchMarkPendingButton'),
                      onPressed: canOperate ? _markSelectedPending : null,
                      child: const Text('恢复待取件'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('batchDeleteButton'),
                      onPressed: canOperate ? _confirmDeleteSelected : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _defaultImportPageBuilder(List<String> imagePaths) {
  return BatchImportPage(imagePaths: imagePaths);
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/admin_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_application_model.dart';
import '../../../shared/models/user_model.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.bgColor,
          elevation: 0,
          title: Text('Admin Paneli', style: AppTextStyles.titleMedium),
          iconTheme: IconThemeData(color: context.textPrimaryColor),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textSecondaryColor,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Başvurular'),
              Tab(text: 'Kullanıcılar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApplicationsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

String _parseError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
  }
  return fallback;
}

// ── Başvurular sekmesi ────────────────────────────────────────────────────────

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  List<RestaurantApplicationModel> _apps = [];
  bool _loading = true;
  String? _error;
  bool _pendingOnly = true;
  int? _busyId; // işlenen başvuru

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await AdminRepository.instance
          .getApplications(pendingOnly: _pendingOnly);
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Başvurular yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _approve(RestaurantApplicationModel app) async {
    setState(() => _busyId = app.id);
    try {
      await AdminRepository.instance.approveApplication(app.id);
      _snack('Başvuru onaylandı: ${app.restaurantName}');
      await _load();
    } catch (e) {
      _snack(_parseError(e, 'Onaylanamadı.'), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(RestaurantApplicationModel app) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text('Başvuruyu Reddet', style: AppTextStyles.titleSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${app.restaurantName}" reddedilsin mi?',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Red sebebi (opsiyonel)',
                hintStyle: AppTextStyles.bodySmall,
                filled: true,
                fillColor: ctx.surfaceElevatedColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ctx.dividerColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Reddet', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyId = app.id);
    try {
      await AdminRepository.instance
          .rejectApplication(app.id, note: noteCtrl.text.trim());
      _snack('Başvuru reddedildi.');
      await _load();
    } catch (e) {
      _snack(_parseError(e, 'Reddedilemedi.'), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Sadece bekleyenler'),
                selected: _pendingOnly,
                onSelected: (v) {
                  setState(() => _pendingOnly = v);
                  _load();
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: _error!,
        action: OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      );
    }
    if (_apps.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          _CenteredMessage(
            icon: Icons.inbox_rounded,
            message: 'Gösterilecek başvuru yok.',
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _apps.length,
      itemBuilder: (_, i) => _AdminApplicationCard(
        app: _apps[i],
        busy: _busyId == _apps[i].id,
        onApprove: () => _approve(_apps[i]),
        onReject: () => _reject(_apps[i]),
      ),
    );
  }
}

class _AdminApplicationCard extends StatelessWidget {
  const _AdminApplicationCard({
    required this.app,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });
  final RestaurantApplicationModel app;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  ({Color color, String label}) get _statusInfo => switch (app.status) {
        ApplicationStatus.pending => (color: const Color(0xFFF59E0B), label: 'Bekliyor'),
        ApplicationStatus.approved => (color: AppColors.success, label: 'Onaylı'),
        ApplicationStatus.rejected => (color: AppColors.error, label: 'Red'),
        ApplicationStatus.unknown => (color: AppColors.textSecondary, label: '—'),
      };

  @override
  Widget build(BuildContext context) {
    final s = _statusInfo;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(app.restaurantName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: s.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${app.type == 'CLAIM' ? 'Sahiplik talebi' : 'Yeni restoran'} · '
            '${[app.district, app.city].where((e) => e != null && e.isNotEmpty).join(', ')}',
            style: AppTextStyles.bodySmall,
          ),
          if (app.applicantUsername != null) ...[
            const SizedBox(height: 2),
            Text('Başvuran: @${app.applicantUsername} (${app.applicantEmail ?? ''})',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
          if (app.isRejected && (app.adminNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text('Red sebebi: ${app.adminNote}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],
          if (app.isPending) ...[
            const SizedBox(height: 12),
            busy
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error),
                          label: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success),
                          label: const Text('Onayla'),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

// ── Kullanıcılar sekmesi ──────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<UserModel> _users = [];
  bool _loading = true;
  String? _error;

  static const _roleLabels = {
    UserRole.user: 'Kullanıcı',
    UserRole.restaurantOwner: 'Restoran Sahibi',
    UserRole.admin: 'Admin',
  };
  static const _roleApi = {
    UserRole.user: 'USER',
    UserRole.restaurantOwner: 'RESTAURANT_OWNER',
    UserRole.admin: 'ADMIN',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await AdminRepository.instance.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Kullanıcılar yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _changeRole(UserModel user) async {
    final newRole = await showModalBottomSheet<UserRole>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('@${user.username} — Rol Değiştir',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            ...UserRole.values.map((role) => ListTile(
                  leading: Icon(
                    user.role == role
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: user.role == role
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(_roleLabels[role]!),
                  onTap: () => Navigator.pop(context, role),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (newRole == null || newRole == user.role) return;

    try {
      await AdminRepository.instance
          .changeUserRole(user.userId, _roleApi[newRole]!);
      _snack('@${user.username} → ${_roleLabels[newRole]}');
      await _load();
    } catch (e) {
      _snack(_parseError(e, 'Rol değiştirilemedi.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: _error!,
        action: OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        final roleColor = switch (u.role) {
          UserRole.admin => AppColors.error,
          UserRole.restaurantOwner => AppColors.primary,
          UserRole.user => AppColors.textSecondary,
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerColor),
          ),
          child: ListTile(
            title: Text(u.fullName, style: AppTextStyles.titleSmall),
            subtitle: Text('@${u.username} · ${u.email}',
                style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_roleLabels[u.role]!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: roleColor, fontWeight: FontWeight.w700)),
            ),
            onTap: () => _changeRole(u),
          ),
        );
      },
    );
  }
}

// ── Ortak ─────────────────────────────────────────────────────────────────────

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/admin_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_claim_model.dart';
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
              Tab(text: 'Talepler'),
              Tab(text: 'Kullanıcılar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ClaimsTab(),
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

// ── Sahiplik talepleri sekmesi ────────────────────────────────────────────────

class _ClaimsTab extends StatefulWidget {
  const _ClaimsTab();

  @override
  State<_ClaimsTab> createState() => _ClaimsTabState();
}

class _ClaimsTabState extends State<_ClaimsTab> {
  List<RestaurantClaimModel> _claims = [];
  bool _loading = true;
  String? _error;
  bool _pendingOnly = true;
  int? _busyId; // işlenen talep

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
      final claims =
          await AdminRepository.instance.getClaims(pendingOnly: _pendingOnly);
      if (mounted) {
        setState(() {
          _claims = claims;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Talepler yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _approve(RestaurantClaimModel claim) async {
    setState(() => _busyId = claim.id);
    try {
      await AdminRepository.instance.reviewClaim(claim.id, approve: true);
      _snack('Talep onaylandı: ${claim.restaurantName}');
      await _load();
    } catch (e) {
      _snack(_parseError(e, 'Talep onaylanamadı.'), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(RestaurantClaimModel claim) async {
    final noteCtrl = TextEditingController();
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Talebi Reddet', style: AppTextStyles.titleSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${claim.restaurantName}" için @${claim.username ?? ''} '
              'tarafından açılan talep reddedilecek.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: ctx.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Red sebebi (kullanıcı görecek)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _busyId = claim.id);
    try {
      await AdminRepository.instance
          .reviewClaim(claim.id, approve: false, note: noteCtrl.text.trim());
      _snack('Talep reddedildi.');
      await _load();
    } catch (e) {
      _snack(_parseError(e, 'Talep reddedilemedi.'), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        action:
            OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      );
    }
    if (_claims.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          _CenteredMessage(
            icon: Icons.inbox_rounded,
            message: 'Gösterilecek talep yok.',
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _claims.length,
      itemBuilder: (_, i) => _AdminClaimCard(
        claim: _claims[i],
        busy: _busyId == _claims[i].id,
        onApprove: () => _approve(_claims[i]),
        onReject: () => _reject(_claims[i]),
      ),
    );
  }
}

class _AdminClaimCard extends StatelessWidget {
  const _AdminClaimCard({
    required this.claim,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });
  final RestaurantClaimModel claim;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  ({Color color, String label}) get _statusInfo => switch (claim.status) {
        ClaimStatus.pending =>
          (color: const Color(0xFFF59E0B), label: 'Bekliyor'),
        ClaimStatus.approved => (color: AppColors.success, label: 'Onaylı'),
        ClaimStatus.rejected => (color: AppColors.error, label: 'Red'),
        ClaimStatus.unknown => (color: AppColors.textSecondary, label: '—'),
      };

  @override
  Widget build(BuildContext context) {
    final s = _statusInfo;
    return GestureDetector(
      // Karta dokunmak talebin tamamını açar: tam adres, talep sahibi,
      // tarihler. Kartta yalnızca özet var.
      onTap: () => _ClaimDetailSheet.show(context, claim),
      child: Container(
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
                  child: Text(claim.restaurantName,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.label,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: s.color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    claim.restaurantAddress?.trim().isNotEmpty == true
                        ? claim.restaurantAddress!
                        : 'Adres kayıtlı değil',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: context.textSecondaryColor),
              ],
            ),
            if (claim.username != null) ...[
              const SizedBox(height: 2),
              Text('Talep eden: @${claim.username}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
            if (claim.isRejected && (claim.adminNote?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text('Red sebebi: ${claim.adminNote}',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
            if (claim.isPending) ...[
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

// ── Talep Detayı ──────────────────────────────────────────────────────────────

/// Talebin tamamını gösterir. Kartta yalnızca restoran adı ve adres özeti var;
/// admin kararını verirken tam adresi ve talep sahibini görmeli.
class _ClaimDetailSheet extends StatelessWidget {
  const _ClaimDetailSheet({required this.claim});

  final RestaurantClaimModel claim;

  static Future<void> show(BuildContext context, RestaurantClaimModel claim) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClaimDetailSheet(claim: claim),
    );
  }

  static String _tarih(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${iki(l.day)}.${iki(l.month)}.${l.year} ${iki(l.hour)}:${iki(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(claim.restaurantName, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Sahiplik talebi',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 20),

              _DetaySatiri(
                icon: Icons.location_on_rounded,
                label: 'Adres',
                value: claim.restaurantAddress?.trim().isNotEmpty == true
                    ? claim.restaurantAddress!
                    : 'Kayıtlı değil',
              ),
              _DetaySatiri(
                icon: Icons.storefront_rounded,
                label: 'Restoran ID',
                value: '${claim.restaurantId}',
              ),

              const Divider(height: 32),

              _DetaySatiri(
                icon: Icons.person_rounded,
                label: 'Talep eden',
                value: [
                  if (claim.username != null) '@${claim.username}',
                  'Kullanıcı ID: ${claim.userId}',
                ].join('\n'),
              ),
              _DetaySatiri(
                icon: Icons.schedule_rounded,
                label: 'Talep tarihi',
                value: _tarih(claim.createdAt),
              ),
              if (claim.reviewedAt != null)
                _DetaySatiri(
                  icon: Icons.fact_check_rounded,
                  label: 'İnceleme tarihi',
                  value: _tarih(claim.reviewedAt),
                ),
              if (claim.adminNote?.isNotEmpty == true)
                _DetaySatiri(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Admin notu',
                  value: claim.adminNote!,
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetaySatiri extends StatelessWidget {
  const _DetaySatiri({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? context.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.textSecondaryColor)),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: color ?? context.textPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

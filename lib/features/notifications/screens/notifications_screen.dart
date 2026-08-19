import 'package:flutter/material.dart';

import '../../../core/network/notification_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/notification_model.dart';
import '../../reviews/screens/menu_item_reviews_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;

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
      final list = await NotificationRepository.instance.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Bildirimler yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  int get _unread => _notifications.where((n) => !n.read).length;

  Future<void> _markAllRead() async {
    try {
      await NotificationRepository.instance.markAllRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => NotificationModel(
                    id: n.id,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    menuItemId: n.menuItemId,
                    menuItemName: n.menuItemName,
                    read: true,
                    createdAt: n.createdAt,
                  ))
              .toList();
        });
      }
    } catch (_) {
      // sessiz — liste yenilenince düzelir
    }
  }

  Future<void> _onTap(NotificationModel n) async {
    if (!n.read) {
      // best-effort okundu işaretle
      NotificationRepository.instance.markRead(n.id).catchError((_) {});
      setState(() {
        final i = _notifications.indexWhere((x) => x.id == n.id);
        if (i != -1) {
          _notifications[i] = NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            menuItemId: n.menuItemId,
            menuItemName: n.menuItemName,
            read: true,
            createdAt: n.createdAt,
          );
        }
      });
    }
    // Değerlendirme bildirimi → ürünün yorumlarına git
    if (n.menuItemId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MenuItemReviewsScreen(
            menuItemId: n.menuItemId!,
            menuItemName: n.menuItemName ?? 'Ürün',
          ),
        ),
      );
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Bildirimler', style: AppTextStyles.titleMedium),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tümünü okundu yap',
                  style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _centered(Icons.cloud_off_rounded, _error!,
          OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')));
    }
    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _centered(Icons.notifications_none_rounded,
              'Henüz bildirimin yok.\nÜrünlerine değerlendirme gelince burada görünür.',
              null),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _notifications.length,
      itemBuilder: (_, i) {
        final n = _notifications[i];
        return GestureDetector(
          onTap: () => _onTap(n),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.read
                  ? context.surfaceColor
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: n.read ? context.dividerColor : AppColors.primary),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.star.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: AppColors.star, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: n.read
                                        ? FontWeight.w500
                                        : FontWeight.w700)),
                          ),
                          Text(_timeAgo(n.createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textDisabled, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(n.body, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (!n.read)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _centered(IconData icon, String msg, Widget? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/network/application_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_application_model.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  List<RestaurantApplicationModel> _applications = [];
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
      final apps = await ApplicationRepository.instance.getMyApplications();
      if (mounted) {
        setState(() {
          _applications = apps;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Başvuru Durumum', style: AppTextStyles.titleMedium),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
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
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: _error!,
        action: OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      );
    }
    if (_applications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          _CenteredMessage(
            icon: Icons.storefront_outlined,
            message:
                'Henüz bir restoran başvurun yok.\nKayıt olurken "Restoran Sahibiyim" ile başvurabilirsin.',
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _applications.length,
      itemBuilder: (_, i) => _ApplicationCard(app: _applications[i]),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app});
  final RestaurantApplicationModel app;

  ({Color color, String label, IconData icon}) get _statusInfo {
    return switch (app.status) {
      ApplicationStatus.pending => (
          color: const Color(0xFFF59E0B),
          label: 'İnceleniyor',
          icon: Icons.hourglass_top_rounded,
        ),
      ApplicationStatus.approved => (
          color: AppColors.success,
          label: 'Onaylandı',
          icon: Icons.check_circle_rounded,
        ),
      ApplicationStatus.rejected => (
          color: AppColors.error,
          label: 'Reddedildi',
          icon: Icons.cancel_rounded,
        ),
      ApplicationStatus.unknown => (
          color: AppColors.textSecondary,
          label: 'Bilinmiyor',
          icon: Icons.help_outline_rounded,
        ),
    };
  }

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: 13, color: s.color),
                    const SizedBox(width: 4),
                    Text(s.label,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: s.color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                [app.district, app.city]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(', '),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          if (app.isPending) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: 'Başvurun inceleniyor. Onaylanınca restoran sahibi olacaksın.',
            ),
          ],
          if (app.isApproved) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: 'Tebrikler! Başvurun onaylandı. "Restoranım"dan menünü yönetebilirsin.',
            ),
          ],
          if (app.isRejected && (app.adminNote?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: 'Red sebebi: ${app.adminNote}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: AppTextStyles.bodySmall.copyWith(color: color)),
    );
  }
}

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
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/network/claim_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_claim_model.dart';
import 'restaurant_claim_screen.dart';

/// Kullanıcının açtığı sahiplik taleplerinin durumu.
class ClaimStatusScreen extends StatefulWidget {
  const ClaimStatusScreen({super.key});

  @override
  State<ClaimStatusScreen> createState() => _ClaimStatusScreenState();
}

class _ClaimStatusScreenState extends State<ClaimStatusScreen> {
  List<RestaurantClaimModel> _claims = [];
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
      final claims = await ClaimRepository.instance.myClaims();
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

  Future<void> _yeniTalep() async {
    final gonderildi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RestaurantClaimScreen()),
    );
    if (gonderildi == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: const Text('Sahiplik Taleplerim', style: AppTextStyles.titleMedium),
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
        action:
            OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')),
      );
    }
    if (_claims.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const _CenteredMessage(
            icon: Icons.storefront_outlined,
            message: 'Henüz bir sahiplik talebin yok.',
          ),
          const SizedBox(height: 20),
          // Center şart: ListView çocuklarını yatayda gerdiği için buton
          // ekranın iki kenarına yapışıyordu.
          Center(
            child: FilledButton.icon(
              onPressed: _yeniTalep,
              icon: const Icon(Icons.storefront_rounded, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text('Restoranımı Sahiplen'),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _claims.length,
      itemBuilder: (_, i) => _ClaimCard(claim: _claims[i]),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});
  final RestaurantClaimModel claim;

  ({Color color, String label, IconData icon}) get _statusInfo {
    return switch (claim.status) {
      ClaimStatus.pending => (
          color: const Color(0xFFF59E0B),
          label: 'İnceleniyor',
          icon: Icons.hourglass_top_rounded,
        ),
      ClaimStatus.approved => (
          color: AppColors.success,
          label: 'Onaylandı',
          icon: Icons.check_circle_rounded,
        ),
      ClaimStatus.rejected => (
          color: AppColors.error,
          label: 'Reddedildi',
          icon: Icons.cancel_rounded,
        ),
      ClaimStatus.unknown => (
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
                child: Text(claim.restaurantName,
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
          if ((claim.restaurantAddress ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(claim.restaurantAddress!,
                      style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (claim.isPending) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: 'Talebin inceleniyor. Onaylanınca restoranın sahibi '
                  'olacaksın.',
            ),
          ],
          if (claim.isApproved) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: 'Tebrikler! Talebin onaylandı. "Restoranım"dan menünü '
                  'yönetebilirsin.',
            ),
          ],
          if (claim.isRejected) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              color: s.color,
              text: (claim.adminNote?.isNotEmpty ?? false)
                  ? 'Red sebebi: ${claim.adminNote}'
                  : 'Talebin reddedildi. Tekrar deneyebilirsin.',
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
      child:
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
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

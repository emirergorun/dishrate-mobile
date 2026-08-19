import 'package:flutter/material.dart';

import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_model.dart';
import 'restaurant_manage_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<RestaurantModel> _restaurants = [];
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
      final list = await RestaurantRepository.instance.getMyRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Restoranların yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openManage(RestaurantModel r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantManageScreen(restaurant: r)),
    );
    // Yönetim ekranından dönünce (ad/adres değişmiş olabilir) tazele
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Restoranım', style: AppTextStyles.titleMedium),
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
      return _centered(Icons.cloud_off_rounded, _error!,
          OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')));
    }
    if (_restaurants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _centered(Icons.storefront_outlined,
              'Henüz yönetebileceğin bir restoran yok.', null),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _restaurants.length,
      itemBuilder: (_, i) {
        final r = _restaurants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.primary),
            ),
            title: Text(r.name, style: AppTextStyles.titleSmall),
            subtitle: Text(
              [r.district, r.city].where((e) => e != null && e.isNotEmpty).join(', '),
              style: AppTextStyles.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onTap: () => _openManage(r),
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

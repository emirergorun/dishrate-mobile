import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/diary/screens/diary_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'pressable.dart';
import 'rating_sheet.dart';

/// Uygulama içinden sekme değiştirmek için (örn. profildeki "Değerlendirme"
/// sayacına dokununca Günlük sekmesine geçmek). Ekran indeksi:
/// 0=Keşfet, 1=Ara, 2=Günlük, 3=Profil
final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  // 0=Keşfet, 1=Ara, 2=Günlük, 3=Profil (+ modal, ekran değil)
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DiscoverScreen(),
    SearchScreen(),
    DiaryScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int navIndex) {
    if (navIndex == 2) {
      _openAddRatingModal();
      return;
    }
    // Nav: 0→screen 0, 1→screen 1, 3→screen 2, 4→screen 3
    final screenIndex = navIndex > 2 ? navIndex - 1 : navIndex;
    _goToScreen(screenIndex);
  }

  void _goToScreen(int screenIndex) {
    setState(() => _currentIndex = screenIndex);
    // Provider'ı senkron tut (dışarıdan gelen isteklerle çakışmasın)
    if (ref.read(selectedTabProvider) != screenIndex) {
      ref.read(selectedTabProvider.notifier).state = screenIndex;
    }
    // Profil sekmesi → güncel veriyi sessizce yenile (IndexedStack canlı tutuyor)
    if (screenIndex == 3) {
      ref.read(profileRefreshProvider.notifier).state++;
    }
  }

  Future<void> _openAddRatingModal() async {
    await RatingSheet.show(context);
    // Puan eklenmiş olabilir → profil verisini tazele
    if (mounted) ref.read(profileRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    // Uygulama içinden sekme değiştirme isteklerini dinle
    ref.listen<int>(selectedTabProvider, (_, next) {
      if (next != _currentIndex) _goToScreen(next);
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _DishRateBottomNav(
        currentScreenIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _DishRateBottomNav extends StatelessWidget {
  const _DishRateBottomNav({
    required this.currentScreenIndex,
    required this.onTap,
  });

  final int currentScreenIndex;
  final ValueChanged<int> onTap;

  // Screen index → nav index: 0→0, 1→1, 2→3, 3→4
  int get _activeNavIndex =>
      currentScreenIndex >= 2 ? currentScreenIndex + 1 : currentScreenIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.navBgColor,
        border: Border(
          top: BorderSide(color: context.dividerColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: TablerIcons.home,
                activeIcon: TablerIcons.home_filled,
                label: 'Keşfet',
                isSelected: _activeNavIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: TablerIcons.search,
                activeIcon: TablerIcons.search,
                label: 'Ara',
                isSelected: _activeNavIndex == 1,
                onTap: () => onTap(1),
              ),
              // Merkezi + butonu
              _AddButton(onTap: () => onTap(2)),
              _NavItem(
                icon: TablerIcons.notebook,
                activeIcon: TablerIcons.notebook,
                label: 'Günlük',
                isSelected: _activeNavIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: TablerIcons.user,
                activeIcon: TablerIcons.user_filled,
                label: 'Profil',
                isSelected: _activeNavIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;

  /// Seçili sekmede dolu ikon: yalnızca renk farkı küçük ikonda zor seçiliyor.
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? context.accentTextColor : context.navUnselectedColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.label.copyWith(fontSize: 11, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Turuncu parıltı gölgesi kaldırıldı: şablon alt menülerinin en tanıdık
    // imzasıydı. Buton zaten menüdeki tek dolu turuncu şekil; öne çıkması
    // için gölgeye ihtiyacı yok.
    return Expanded(
      child: Center(
        child: Pressable(
          onTap: onTap,
          scale: 0.92,
          semanticLabel: 'Değerlendirme ekle',
          child: Container(
            width: 48,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              TablerIcons.plus,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

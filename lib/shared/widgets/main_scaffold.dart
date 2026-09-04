import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/rating/screens/add_rating_screen.dart';
import '../../features/diary/screens/diary_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRatingSheet(),
    );
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
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Keşfet',
                isSelected: _activeNavIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Ara',
                isSelected: _activeNavIndex == 1,
                onTap: () => onTap(1),
              ),
              // Merkezi + butonu
              _AddButton(onTap: () => onTap(2)),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Günlük',
                isSelected: _activeNavIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
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
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppColors.navSelected : context.navUnselectedColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Puan Ekle Modal ───────────────────────────────────────────────────────────

class _AddRatingSheet extends StatelessWidget {
  const _AddRatingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Column(
        children: [
          SizedBox(height: 12),
          // Tutma çubuğu
          SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(child: AddRatingScreen()),
        ],
      ),
    );
  }
}

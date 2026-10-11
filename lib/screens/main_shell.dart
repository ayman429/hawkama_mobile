import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/booking_store.dart';
import 'booking/service_pick_screen.dart';
import 'bookings_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

/// Active tab: 0 home, 1 bookings, 2 reports, 3 profile.
final shellIndex = ValueNotifier<int>(0);

/// App shell with the 5-slot tab bar + center gold FAB (mobile.md §2.2).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(key: PageStorageKey('home')),
    BookingsScreen(key: PageStorageKey('bookings')),
    ReportsScreen(key: PageStorageKey('reports')),
    ProfileScreen(key: PageStorageKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return ValueListenableBuilder<int>(
      valueListenable: shellIndex,
      builder: (context, index, _) {
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: index, children: _screens),
          floatingActionButton: FloatingActionButton(
            elevation: 6,
            backgroundColor: AppColors.gold,
            shape: CircleBorder(
                side: BorderSide(color: c.background, width: 3)),
            onPressed: () {
              // The FAB always starts a NEW booking (mobile.md §5).
              BookingStore.instance.reset();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServicePickScreen()));
            },
            child:
                const Icon(Icons.add, size: 26, color: AppColors.greenDarker),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: c.surface,
            surfaceTintColor: c.surface,
            shape: const CircularNotchedRectangle(),
            notchMargin: 7,
            height: 56,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(Icons.home_outlined, tr('tabHome'), index == 0,
                    () => shellIndex.value = 0),
                _NavItem(Icons.calendar_month_outlined, tr('tabBookings'),
                    index == 1, () => shellIndex.value = 1),
                const SizedBox(width: 56),
                _NavItem(Icons.description_outlined, tr('tabReports'),
                    index == 2, () => shellIndex.value = 2),
                _NavItem(Icons.person_outline, tr('tabProfile'), index == 3,
                    () => shellIndex.value = 3),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final color = active ? AppColors.greenDeep : c.stone;
    final shown = context.isDark && active ? AppColors.goldLight : color;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: shown),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 8.5,
                    color: shown,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

import "dart:ui";
import "package:flutter/material.dart";
import "../core/theme/colors.dart";

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}

const kBottomNavItems = [
  BottomNavItem(icon: Icons.home_rounded, label: "Home"),
  BottomNavItem(icon: Icons.history_rounded, label: "History"),
  BottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: "Chat"),
  BottomNavItem(icon: Icons.groups_rounded, label: "Lawyers"),
];

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const AppBottomNav({super.key, required this.activeIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface.withOpacity(0.75),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < kBottomNavItems.length; i++)
                _NavButton(
                  item: kBottomNavItems[i],
                  active: i == activeIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final BottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(item.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

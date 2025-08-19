// lib/widgets/main/custom_bottom_nav_bar.dart

import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      decoration: BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 'Home', 0, context),
            _buildNavItem(Icons.inventory_2_rounded, 'Inventory', 1, context),
            const SizedBox(width: 50), // Khoảng trống cho FAB
            _buildNavItem(Icons.receipt_long_rounded, 'Orders', 2, context),
            _buildNavItem(Icons.settings_rounded, 'Settings', 3, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, BuildContext context) {
    final bool isSelected = selectedIndex == index;
    final Color activeColor = Theme.of(context).primaryColor;
    final Color inactiveColor = Colors.grey.shade500;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemTapped(index),
          borderRadius: BorderRadius.circular(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
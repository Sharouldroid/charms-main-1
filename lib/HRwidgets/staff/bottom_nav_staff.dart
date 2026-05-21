import 'package:flutter/material.dart';

class BottomNavStaff extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool showMyselfDot; // new

  const BottomNavStaff({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.showMyselfDot = false, // default false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red[300],
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          items: [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.beach_access,
              label: 'Leave',
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.monetization_on,
              label: 'Payment Reports',
              isSelected: selectedIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.receipt,
              label: 'Claim',
              isSelected: selectedIndex == 3,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'MySelf',
              isSelected: selectedIndex == 4,
              showDot: showMyselfDot, // pass dot flag
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    bool showDot = false, //  new
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[100]!.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[300]!.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          Icon(
            icon,
            size: 25,
            color: isSelected ? Colors.red[300] : Colors.grey,
          ),
          // ✅ Red dot indicator
          if (showDot)
            Positioned(
              top: -2,
              right: -6,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}
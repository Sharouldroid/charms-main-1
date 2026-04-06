import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4), // Shadow position
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
              icon: Icons.people_alt_outlined,
              label: 'Staff',
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              isSelected: selectedIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Myself',
              isSelected: selectedIndex == 3,
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
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red[100]!.withOpacity(0.8), // Highlight circle
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
            size: 28,
            color: isSelected ? Colors.red[300] : Colors.grey,
          ),
        ],
      ),
      label: label,
    );
  }
}

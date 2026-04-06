import 'package:flutter/material.dart';
import 'package:provider/provider.dart';                     // ✅ Added for Provider
import 'package:charms/utils/responsive_helper.dart';
import 'package:charms/providers/users.dart';                   // ✅ Adjust import to your user model
import 'safety_history_page.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Get user role from Provider
    final user = Provider.of<Users>(context, listen: false).userlist.first;
    final int role = user.usertype;                          // e.g. 9 = Marine Biologist

    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final spacing = ResponsiveHelper.getSpacing(context, baseSpacing: 16);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety'),
        backgroundColor: const Color(0xFFF05179),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSafetyReminder(),
                const SizedBox(height: 24),

                // Header section
                Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        color: const Color(0xFFF05179), size: isTablet ? 40 : 32),
                    SizedBox(width: isTablet ? 14 : 10),
                    Text(
                      "Safety Resources",
                      style: TextStyle(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 24 : 20),

                // Grid layout (unchanged)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: isTablet ? 1.0 : 0.85,
                  children: [
                    buildSafetyCard(
                      context,
                      title: "First Aid Kit",
                      subtitle: "Check and update first aid items",
                      icon: Icons.medical_services,
                      route: '/firstaid',
                    ),
                    buildSafetyCard(
                      context,
                      title: "Backpacking",
                      subtitle: "Ensure safe and light packing",
                      icon: Icons.backpack,
                      route: '/backpacking',
                    ),
                    buildSafetyCard(
                      context,
                      title: "Landscape and Infrastructure",
                      subtitle: "Inspect signage, trees and hazards",
                      icon: Icons.nature,
                      route: '/landscape',
                    ),
                    buildSafetyCard(
                      context,
                      title: "Water Quality",
                      subtitle: "Monitor pH, Chlorine and chemical levels",
                      icon: Icons.water_drop_outlined,
                      route: '/water_quality',
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ✅ History button – only shown if role is NOT Marine Biologist (9)
                if (role != 9)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text(
                        'VIEW REPORT HISTORY',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SafetyHistoryPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- SAFETY REMINDER WIDGET (unchanged) ----------------------
  Widget _buildSafetyReminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF05179).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF05179).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gpp_maybe, color: Color(0xFFF05179)),
              SizedBox(width: 8),
              Text(
                'Safety Protocol Reminder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF05179),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'To ensure the site remains hazard-free, all safety categories below MUST be inspected and logged immediately after every volunteer slot finish.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Custom card widget (unchanged)
  Widget buildSafetyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final iconSize = ResponsiveHelper.getIconSize(context, baseSize: 40);
    final titleSize = isTablet ? 18.0 : 16.0;
    final subtitleSize = isTablet ? 14.0 : 12.0;
    final cardPadding = isTablet ? 20.0 : 16.0;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB9C4CA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.black87),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: subtitleSize, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
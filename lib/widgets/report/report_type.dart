import 'package:charms/models/user.dart';
import 'package:charms/widgets/report/boat_report.dart';
import 'package:charms/widgets/report/daytrip_report.dart';
import 'package:charms/widgets/report/kpp_report.dart';
import 'package:charms/widgets/report/researcher_report.dart';
import 'package:charms/widgets/report/rss_report.dart';
import 'package:charms/widgets/report/volunteer_report.dart';
import 'package:flutter/material.dart';

class ReportType extends StatelessWidget {
  const ReportType({
    super.key,
    required this.isstaff,
    required this.user,
    required this.hostname,
  });

  final bool isstaff;
  final User user;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 4 / 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          DashItem(
            icon: Icons.volunteer_activism,
            title: 'Volunteer',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => VolunteerReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 1,
                        ),
                  ),
                ),
          ),
          DashItem(
            icon: Icons.science_outlined,
            title: 'Researcher',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => ResearcherReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 1,
                        ),
                  ),
                ),
          ),
          DashItem(
            icon: Icons.auto_awesome,
            title: 'Researcher Slot',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => RSSReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 1,
                        ),
                  ),
                ),
          ),
          DashItem(
            icon: Icons.calendar_today,
            title: 'Day Trip',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => DayTripReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 0,
                        ),
                  ),
                ),
          ),
          DashItem(
            icon: Icons.beach_access,
            title: 'Kem Penyu',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => KPPReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 0,
                        ),
                  ),
                ),
          ),
          DashItem(
            icon: Icons.directions_boat_filled_outlined,
            title: 'Boat',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (ctx) => BoatReport(
                          staff: isstaff,
                          user: user,
                          hostname: hostname,
                          eventtype: 1,
                        ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class DashItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

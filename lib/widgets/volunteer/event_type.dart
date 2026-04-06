import 'package:charms/models/user.dart';
import 'package:charms/screens/daytrip_screen.dart';
import 'package:charms/screens/volunteer_screen.dart';
import 'package:charms/screens/kpp_screen.dart';
import 'package:charms/screens/researcher_screen.dart';
import 'package:flutter/material.dart';

class EventType extends StatelessWidget {
  const EventType({
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
    final List<Widget> gridItems = [];

    if (isstaff || user.usertype == 2) {
      gridItems.add(
        DashItem(
          icon: Icons.volunteer_activism,
          title: 'Volunteer Program',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => VolunteerScreen(
                      isstaff: isstaff,
                      user: user,
                      hostname: hostname,
                    ),
              ),
            );
          },
        ),
      );
    }

    if (isstaff || user.usertype == 3) {
      gridItems.add(
        DashItem(
          icon: Icons.science_outlined,
          title: 'Researcher Trip',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => ResearcherScreen(
                      isstaff: isstaff,
                      user: user,
                      hostname: hostname,
                    ),
              ),
            );
          },
        ),
      );
    }

    if (isstaff || user.usertype == 7) {
      gridItems.add(
        DashItem(
          icon: Icons.beach_access_outlined,
          title: 'Kem Prihatin Penyu',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => KPPScreen(
                      isstaff: isstaff,
                      user: user,
                      hostname: hostname,
                    ),
              ),
            );
          },
        ),
      );
    }

    if (isstaff || user.usertype == 4) {
      gridItems.add(
        DashItem(
          icon: Icons.calendar_today,
          title: 'Day Trip',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => DaytripScreen(
                      isstaff: isstaff,
                      user: user,
                      hostname: hostname,
                    ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Booking Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio:1.0,
          children: gridItems,
        ),
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

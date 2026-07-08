import 'package:flutter/material.dart';

/// Shared visual language for the HR Admin screens.
///
/// Pure presentation (colors, text styles, reusable chrome) — no business
/// logic lives here. Screens keep their own state/providers/API calls and
/// only borrow these building blocks for a consistent, professional look
/// that also behaves well when the app is installed as a PWA (bounded
/// content width, no fixed pixel layouts, standard Material text scaling).
class HRColors {
  HRColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color background = Color(0xFFF4F7FA);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
}

class HRTextStyles {
  HRTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: HRColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: HRColors.textMuted,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: HRColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: HRColors.textSecondary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: HRColors.textMuted,
  );
}

/// Standard rounded, elevated card decoration used across list tiles,
/// summary tiles and section containers.
BoxDecoration hrCardDecoration({double radius = 16}) {
  return BoxDecoration(
    color: HRColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Consistent AppBar used across HR Admin screens: primary-blue background,
/// white foreground, rounded bottom edge, centered bold title.
class HRAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? bottom;
  final double bottomHeight;

  const HRAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: HRColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.6,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      actions: actions,
      bottom: bottom == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight),
              child: bottom!,
            ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + bottomHeight);
}

/// Centers and caps content width so screens stay readable instead of
/// stretching edge-to-edge when the app runs as a desktop PWA / wide window.
class HRPageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const HRPageContainer({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Standard "nothing here" placeholder used for empty lists.
class HREmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const HREmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

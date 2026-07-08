import 'package:flutter/material.dart';

/// Shared visual language for the HR Staff screens — mirrors
/// `HRwidgets/admin/hr_theme.dart` but keeps the staff side's own identity
/// (indigo primary, bordered cards instead of shadowed ones) which was
/// already established across the staff screens.
///
/// Pure presentation — no business logic lives here.
class StaffColors {
  StaffColors._();

  static const Color primary = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
}

/// Consistent AppBar used across HR Staff screens: indigo background,
/// white foreground, rounded bottom edge, centered bold title. Standardizes
/// the mix of rounded/flat AppBars that existed across the staff screens.
class StaffAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? bottom;
  final double bottomHeight;
  final Color? backgroundColor;
  final bool centerTitle;
  final double toolbarHeight;
  final bool roundedBottom;

  const StaffAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.bottomHeight = 0,
    this.backgroundColor,
    this.centerTitle = true,
    this.toolbarHeight = kToolbarHeight,
    this.roundedBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor ?? StaffColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.6,
        ),
      ),
      shape: roundedBottom
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            )
          : null,
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
  Size get preferredSize => Size.fromHeight(toolbarHeight + bottomHeight);
}

/// Centers and caps content width so screens stay readable instead of
/// stretching edge-to-edge when the app runs as a desktop PWA / wide window.
class StaffPageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const StaffPageContainer({super.key, required this.child, this.maxWidth = 720});

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

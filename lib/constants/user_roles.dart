// lib/constants/user_roles.dart

class UserRoles {
  // ── HR Admin ──────────────────────────────────────────
  static const int superID      = 1;
  static const int manager      = 5;
  static const int staffAdmin   = 6;

  // ── Staff Member ──────────────────────────────────────
  static const int staff            = 7;
  static const int centralLabOfficer = 8;
  static const int marineBiologist  = 9;
  static const int researcher       = 3;

  // ── Intern Member ──────────────────────────────────────
  static const int trainee          = 10;

  // ── Else ──────────────────────────────────────────────
  static const int volunteer    = 2;
  static const int boatOwner    = 4;
  static const int turtleRanger = 11;

  // ── Part Timer ────────────────────────────────────────
  static const int partTimer         = 12;

  // ── Group helpers ─────────────────────────────────────
  static const List<int> hrAdmin = [superID, manager, staffAdmin];

  static const List<int> staffMember = [
    staff, centralLabOfficer, marineBiologist, researcher,
  ];

  static const List<int> internGroup = [trainee];
  static const List<int> partTimerGroup = [partTimer];
  static const List<int> elseGroup = [volunteer, boatOwner, turtleRanger];

  // ── Name lookup ───────────────────────────────────────
  static String getRoleName(int usertype) {
    switch (usertype) {
      case superID:           return 'Super ID';
      case manager:           return 'Manager';
      case staffAdmin:        return 'Staff Admin';
      case staff:             return 'Staff';
      case centralLabOfficer: return 'Central Lab Officer';
      case marineBiologist:   return 'Marine Biologist';
      case trainee:           return 'Intern / Trainee';
      case researcher:        return 'Researcher';
      case partTimer:         return 'Part Timer';
      case volunteer:         return 'Volunteer';
      case boatOwner:         return 'Boat Owner';
      case turtleRanger:      return 'Turtle Ranger';
      default:                return 'Unknown Role';
    }
  }
}
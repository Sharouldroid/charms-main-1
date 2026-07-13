import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/boats.dart';
import 'package:charms/providers/users.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:charms/screens/certificate_screen.dart';
import 'package:charms/screens/feedback_screen.dart';
import 'package:charms/screens/feedbackadmin_screen.dart';
import 'package:charms/screens/manage_indemnity_screen.dart';
import 'package:charms/screens/manage_optionalitem_screen.dart';
import 'package:charms/screens/manage_user_screen.dart';
import 'package:charms/screens/report_screen.dart';
import 'package:charms/widgets/boat/company_list.dart';
import 'package:charms/widgets/calendar.dart';
import 'package:charms/widgets/main_drawer.dart';
import 'package:charms/widgets/volunteer/event_type.dart';
import 'package:charms/widgets/boat/boat_assignmenttile.dart';
import 'package:charms/app_startup.dart';
import 'package:charms/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/admin_checklist_page.dart';
import 'package:charms/notification_page.dart';
//import 'package:charms/utils/logout_helper.dart';
//import 'package:charms/HRscreens/login_screen.dart';
import 'package:charms/providers/auth.dart' as app_auth;
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/constants/user_roles.dart';
import 'package:charms/internshipscreens/dashboard_screen.dart' as internship_screens;

// --- CONTROLLER (Recent Activity) ---
class RecentActivityController {
  static final RecentActivityController _instance =
      RecentActivityController._internal();
  factory RecentActivityController() => _instance;
  RecentActivityController._internal();

  Future<List<String>> fetchRecentActivities(
      String hostname, int userId) async {
    try {
      final base = hostname.replaceAll(RegExp(r'\/+$'), '');
      final response = await http
          .get(
            Uri.parse('$base/api/recent-activities?limit=5&userid=$userId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map<String>((activity) {
          String timestamp = activity['created_at'] ?? '';
          String title = activity['title'] ?? '';
          String desc = activity['description'] ?? '';
          return "$timestamp: $title ${desc.isNotEmpty ? '- $desc' : ''}";
        }).toList();
      } else {
        return ["Failed to fetch recent activities"];
      }
    } catch (e) {
      return ["Error: $e"];
    }
  }
}

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({
    super.key,
    required this.usertype,
    required this.userid,
    required this.hostname,
  });

  final int usertype;
  final int userid;
  final String hostname;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _isInit = true;
  bool _isLoading = true;
  User? userdata;

  // Variable to track if dialog has been shown
  bool _dialogShown = false;
  bool _versionChecked = false;

  late Future<List<String>> _recentActivitiesFuture;

  @override
  void initState() {
    super.initState();
    _recentActivitiesFuture = RecentActivityController()
        .fetchRecentActivities(widget.hostname, widget.userid);

    // Check for app updates after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (!_versionChecked && mounted) {
      _versionChecked = true;
      await AppStartup.checkForUpdates(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _fetchUser();
      _isInit = false;
    }

    // Check for Payment Reminder Argument
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Check if args exist, if 'showReminder' is true, and if we haven't shown it yet
    if (args != null && args['showReminder'] == true && !_dialogShown) {
      _dialogShown = true; // Mark as shown so it doesn't loop

      // Schedule the dialog to show after the UI finishes building
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showReminderDialog();
      });
    }
  }

  // The Dialog Function
  void _showReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to tap OK
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder'),
        content: const Text(
          'All volunteers are required to complete the pre-survey before the program date.\n\n'
          'This is important to help us prepare for your participation and ensure a smooth program experience.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUser() async {
    // HR-DB users don't exist in main DB — skip fetch, use auth data directly
    final appAuth = Provider.of<app_auth.Auth>(context, listen: false);

    if (appAuth.authenticatedViaHRFallback) {
      setState(() {
        // Build a minimal User object from auth data
        userdata = User(
          id: appAuth.token ?? '0',
          firstname: appAuth.username,
          lastname: '',
          phone: '',
          dob: '',
          address1: '',
          city: '',
          postcode: 0,
          state: '',
          country: '',
          occupation: '',
          username: appAuth.username,
          email: '',
          password: '',
          usertype: appAuth.usertype,
          gender: 0,
          idnum: '',
        );
        _isLoading = false;
      });
      return;
    }

    // Normal main DB fetch
    try {
      final fetchedUser = await Provider.of<Users>(
        context,
        listen: false,
      ).fetchIndividual(widget.hostname, widget.userid);

      if (!mounted) return;
      setState(() {
        userdata = fetchedUser;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD _fetchUser error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  void _refreshRecentActivities() {
    setState(() {
      _recentActivitiesFuture = RecentActivityController()
          .fetchRecentActivities(widget.hostname, widget.userid);
    });
  }

  Future<void> _refreshPage() async {
    await _fetchUser();
    _refreshRecentActivities();
  }

  // --- Role Helpers ---
  bool _isAdmin()          => UserRoles.hrAdmin.contains(widget.usertype);
  bool _isStaff()          => UserRoles.hrAdmin.contains(widget.usertype);
  bool _isManager()        => widget.usertype == UserRoles.manager;
  bool _isBoatOwner()      => widget.usertype == UserRoles.boatOwner;
  bool _isLabOfficer()     => widget.usertype == UserRoles.centralLabOfficer;
  bool _isMarineBiologist() => widget.usertype == UserRoles.marineBiologist 
                              || widget.usertype == UserRoles.trainee;

  // --- UI Builder: Single Dashboard Card ---
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final iconSize = ResponsiveHelper.getIconSize(context, baseSize: 24);
    final fontSize = isTablet ? 14.0 : 12.0;
    final containerPadding = isTablet ? 14.0 : 10.0;

    return Semantics(
      label: '$title button. Double tap to open.',
      button: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(containerPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: isTablet ? 14 : 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Builder: Smart Section (with optional forced expansion tile) ---
  Widget _buildSmartSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
    bool forceExpansionTile = false,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    // Responsive grid settings
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    final aspectRatio = ResponsiveHelper.getCardAspectRatio(context);

    // Decide whether to use expansion tile (staff OR forced)
    final bool useExpansionTile = _isStaff() || forceExpansionTile;

    if (!useExpansionTile) {
      // For non-staff and not forced: plain grid
      return Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: children,
        ),
      );
    }

    // For staff or forced: expandable card with tile
    final isTablet = ResponsiveHelper.isTablet(context);
    final tilePadding = isTablet ? 20.0 : 16.0;
    final titleFontSize = isTablet ? 15.0 : 13.0;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            tilePadding:
                EdgeInsets.symmetric(horizontal: tilePadding, vertical: 4),
            leading: Icon(icon,
                color: Colors.grey[700],
                size: ResponsiveHelper.getIconSize(context)),
            title: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                letterSpacing: 0.5,
              ),
            ),
            childrenPadding: EdgeInsets.fromLTRB(
                tilePadding, 0, tilePadding, tilePadding),
            children: [
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartK = Provider.of<BookingCartOut>(context, listen: false);
    final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);

    // Read auth once for use in AppBar actions
    final appAuth = Provider.of<app_auth.Auth>(context, listen: false);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHARMS Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userdata == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHARMS Dashboard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load dashboard data.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchUser();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    String today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final String initials =
        '${userdata!.firstname.isNotEmpty ? userdata!.firstname[0] : ''}${userdata!.lastname.isNotEmpty ? userdata!.lastname[0] : ''}'
            .toUpperCase();

    return ConnectivityAwareScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('CHARMS Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // ── Switch to HR Dashboard (only visible for HR users) ──
          if (appAuth.isHRUser)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Switch to HR Dashboard',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => AdminDashboardScreen(
                      username: appAuth.username,
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          // ── Notifications (admin and manager only) ──
          if (_isAdmin() || _isManager())
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(
                      userId: widget.userid,
                      hostname: widget.hostname,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: MainDrawer(
        userid: widget.userid,
        hostname: widget.hostname,
        usertype: widget.usertype,
        user: userdata!,
        isAdmin: _isAdmin(),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
            child: ListView(
              padding: ResponsiveHelper.getResponsivePadding(context),
              children: [
                // ===========================
                // 1. HEADER
                // ===========================
                Container(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.isTablet(context) ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: ResponsiveHelper.getAvatarRadius(context),
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.isTablet(context) ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                          width:
                              ResponsiveHelper.isTablet(context) ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: ResponsiveHelper.isTablet(context)
                                    ? 14
                                    : 12,
                              ),
                            ),
                            Text(
                              userdata!.firstname,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.isTablet(context)
                                    ? 22
                                    : 18,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              today,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: ResponsiveHelper.isTablet(context)
                                    ? 14
                                    : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===========================
                // 2. CALENDAR
                // ===========================
                CalendarWidget(
                  hostname: widget.hostname,
                  staff: _isStaff(),
                  user: userdata!,
                  usertype: widget.usertype,
                ),

                const SizedBox(height: 10),

                if (_isBoatOwner()) ...[
                  const SizedBox(height: 10),
                  FutureBuilder(
                    future: Provider.of<Boats>(context, listen: false)
                        .fetchEventGeneral(widget.hostname, 1),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.error != null) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Consumer<Boats>(
                          builder: (ctx, eventData, child) => ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: eventData.eventlist.length,
                            itemBuilder: (_, i) => BoatAssignmentTile(
                              event: eventData.eventlist[i],
                              hostname: widget.hostname,
                              usertype: widget.usertype,
                              userid: widget.userid,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],

                const SizedBox(height: 10),

                // ===========================
                // 3. SMART SECTIONS
                // ===========================

                // SECTION 1: BOOKING & OPERATIONS
                // Only non-manager and non-marine biologists can see this section
                if (!_isManager() && !_isMarineBiologist())
                  _buildSmartSection(
                    title: 'Booking & Operations',
                    icon: Icons.layers_outlined,
                    initiallyExpanded: true,
                    children: [
                      if (!_isBoatOwner() && !_isLabOfficer())
                        _buildDashboardCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Booking',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EventType(
                                  isstaff: _isStaff(),
                                  user: userdata!,
                                  hostname: widget.hostname,
                                ),
                              ),
                            );
                            cartK.clear();
                            cartI.clear();
                            cartG.clear();
                          },
                        ),
                      if (_isStaff())
                        _buildDashboardCard(
                          icon: Icons.directions_boat_outlined,
                          title: 'Boat Management',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompanyList(
                                hostname: widget.hostname,
                                userid: widget.userid,
                                isAdmin: _isAdmin(),
                              ),
                            ),
                          ),
                        ),
                      if (_isStaff())
                        _buildDashboardCard(
                          icon: Icons.gavel_outlined,
                          title: 'Liability',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageIndemnityScreen(
                                userid: widget.userid,
                                hostname: widget.hostname,
                              ),
                            ),
                          ),
                        ),
                      if (!_isBoatOwner() && !_isLabOfficer())
                        _buildDashboardCard(
                          icon: Icons.workspace_premium_outlined,
                          title: 'E-Certificate',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CertificateScreen(
                                isadmin: _isStaff(),
                                user: userdata!,
                                hostname: widget.hostname,
                                volorres: widget.usertype == 2 ? 1 : 2,
                              ),
                            ),
                          ),
                        ),
                      if (!_isBoatOwner())
                        _buildDashboardCard(
                          icon: Icons.assignment_outlined,
                          title: _isStaff()
                              ? 'Survey Management'
                              : 'Survey',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  _isStaff() || _isLabOfficer()
                                      ? FeedbackAdminScreen(
                                          isadmin: true,
                                          user: userdata!,
                                          hostname: widget.hostname,
                                          isLabOfficer: _isLabOfficer(),
                                        )
                                      : FeedbackScreen(
                                          isadmin: false,
                                          user: userdata!,
                                          hostname: widget.hostname,
                                          volorres:
                                              widget.usertype == 2 ? 1 : 2,
                                        ),
                            ),
                          ),
                        ),
                    ],
                  ),

                // SECTION 2: ADMINISTRATION
                _buildSmartSection(
                  title: 'Administration',
                  icon: Icons.admin_panel_settings_outlined,
                  initiallyExpanded: false,
                  children: [
                    if (_isStaff())
                      _buildDashboardCard(
                        icon: Icons.people_outline,
                        title: 'Manage User',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageUserScreen(
                              hostname: widget.hostname,
                              user: userdata!,
                            ),
                          ),
                        ),
                      ),
                    if (_isStaff())
                      _buildDashboardCard(
                        icon: Icons.analytics_outlined,
                        title: 'Reports',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(
                              isstaff: true,
                              user: userdata!,
                              hostname: widget.hostname,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // SECTION 3: MERCHANDISE
                _buildSmartSection(
                  title: 'Merchandise',
                  icon: Icons.storefront_outlined,
                  initiallyExpanded: false,
                  children: [
                    if (_isStaff())
                      _buildDashboardCard(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Add On',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageOptionalitemScreen(
                              userid: widget.userid,
                              hostname: widget.hostname,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // SECTION 4: MAINTENANCE & SAFETY
                if (_isAdmin() || _isManager() || _isMarineBiologist())
                  _buildSmartSection(
                    title: 'Maintenance & Safety',
                    icon: Icons.handyman_outlined,
                    initiallyExpanded: false,
                    forceExpansionTile: true,
                    children: [
                      _buildDashboardCard(
                        icon: Icons.handyman_outlined,
                        title: 'Maintenance',
                        onTap: () =>
                            Navigator.pushNamed(context, '/maintenance'),
                      ),
                      _buildDashboardCard(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Safety',
                        onTap: () =>
                            Navigator.pushNamed(context, '/safety'),
                      ),
                      _buildDashboardCard(
                        icon: Icons.apartment_outlined,
                        title: 'Facilities',
                        onTap: () =>
                            Navigator.pushNamed(context, '/facilities'),
                      ),
                      _buildDashboardCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Incident',
                        onTap: () =>
                            Navigator.pushNamed(context, '/incident'),
                      ),
                      _buildDashboardCard(
                        icon: Icons.electrical_services,
                        title: 'Others (Boat/Genset)',
                        onTap: () => Navigator.pushNamed(
                            context, '/others_maintenance'),
                      ),
                      // Hide Admin Verification from Marine Biologist
                      if (!_isMarineBiologist())
                        _buildDashboardCard(
                          icon: Icons.fact_check_outlined,
                          title: 'Admin Verification',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminChecklistPage(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                // ===========================
                // SECTION 5: INTERNSHIP
                // ===========================
               if (_isAdmin())
                _buildSmartSection(
                  title: 'Internship Management',
                  icon: Icons.school_outlined,
                  initiallyExpanded: false,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Internship Dashboard',
                      onTap: () {
                        final appAuth = Provider.of<app_auth.Auth>(context, listen: false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => internship_screens.DashboardScreen(
                              username: appAuth.username,
                              role: 'Admin',
                              userId: appAuth.userId ?? 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // ===========================
                // SECTION 6: HR MODULE
                // ===========================
                // if (_isAdmin())
                //   _buildSmartSection(
                //     title: 'HR Management',
                //     icon: Icons.people_alt_outlined,
                //     initiallyExpanded: false,
                //     children: [
                //       _buildDashboardCard(
                //         icon: Icons.admin_panel_settings_outlined,
                //         title: 'HR Dashboard',
                //         onTap: () {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) =>
                //                   const HRSelectionScreen(),
                //             ),
                //           );
                //         },
                //       ),
                //     ],
                //   ),

                // SECTION 7: LOGISTIK (Bahan)
                if (_isAdmin() || _isManager() || _isMarineBiologist())
                  _buildSmartSection(
                    title: 'Logistik (Bahan Mentah & Kering)',
                    icon: Icons.inventory_2_outlined,
                    initiallyExpanded: false,
                    forceExpansionTile: true,
                    children: [
                      _buildDashboardCard(
                        icon: Icons.list_alt_outlined,
                        title: 'Logistik (Bahan Mentah & Kering)',
                        onTap: () =>
                            Navigator.pushNamed(context, '/list-bahan'),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // =======================================================
                // RECENT ACTIVITY - ONLY VIEWABLE BY ADMIN
                // =======================================================
                if (_isAdmin()) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.refresh, color: Colors.grey),
                        onPressed: _refreshRecentActivities,
                        tooltip: 'Refresh Activity',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  FutureBuilder<List<String>>(
                    future: _recentActivitiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }

                      final activities = snapshot.data ?? [];
                      if (activities.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB9C4CA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.black87),
                              SizedBox(width: 10),
                              Text("No recent activities",
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: activities.map((activity) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(activity,
                                      style:
                                          const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '© 2024 CHARMS System',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HR Selection Screen (Login-like page)
// ==========================================
// class HRSelectionScreen extends StatelessWidget {
//   const HRSelectionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select HR Role'),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.red,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//             onPressed: () => LogoutHelper.backToMainDashboard(context),
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 'HR Module Login',
//                 style:
//                     TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 40),

//               // Login as HR Admin → goes to LoginScreen first
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   icon: const Icon(Icons.admin_panel_settings,
//                       color: Colors.white),
//                   label: const Text(
//                     'Login as HR Admin',
//                     style:
//                         TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             const LoginScreen(role: 'HR Admin'),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Login as Staff → goes to LoginScreen first
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   icon: const Icon(Icons.group, color: Colors.white),
//                   label: const Text(
//                     'Login as Staff',
//                     style:
//                         TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             const LoginScreen(role: 'Staff'),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRmodels/schedule_exchange.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';

class StaffNotificationScreen extends StatefulWidget {
  final int staffId;
  final bool isPartTimer;

  const StaffNotificationScreen({
    super.key,
    required this.staffId,
    this.isPartTimer = false,
  });

  @override
  State<StaffNotificationScreen> createState() =>
      _StaffNotificationScreenState();
}

class _StaffNotificationScreenState
    extends State<StaffNotificationScreen> {
  Set<String> _dismissedLeaves    = {};
  Set<String> _dismissedClaims    = {};
  Set<String> _dismissedSchedules = {};
  Set<String> _dismissedExchanges = {};
  DateTime?   _lastClearedAt;

  bool _isLoadingPrefs = true;

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  String get _leaveKey       => 'dismissed_leaves_${widget.staffId}';
  String get _claimKey       => 'dismissed_claims_${widget.staffId}';
  String get _scheduleKey    => 'dismissed_schedules_${widget.staffId}';
  String get _exchangeKey    => 'dismissed_exchanges_${widget.staffId}';
  String get _clearedAtKey   => 'notif_cleared_at_${widget.staffId}';

  @override
  void initState() {
    super.initState();

    // 🔍 DEBUG: confirm staffId is consistent across logins/sessions
    debugPrint('🔍 [NotifScreen] initState -> staffId=${widget.staffId} '
        '(isPartTimer=${widget.isPartTimer})');
    debugPrint('🔍 [NotifScreen] prefs keys -> '
        'leave=$_leaveKey | claim=$_claimKey | '
        'schedule=$_scheduleKey | exchange=$_exchangeKey | '
        'clearedAt=$_clearedAtKey');

    _loadDismissed();
    Future.microtask(() =>
        Provider.of<ScheduleExchanges>(context, listen: false)
            .fetchExchangesByStaff(widget.staffId));
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final clearedStr = prefs.getString(_clearedAtKey);

    final loadedLeaves    = prefs.getStringList(_leaveKey)    ?? [];
    final loadedClaims    = prefs.getStringList(_claimKey)    ?? [];
    final loadedSchedules = prefs.getStringList(_scheduleKey) ?? [];
    final loadedExchanges = prefs.getStringList(_exchangeKey) ?? [];

    // 🔍 DEBUG: see exactly what was read back from SharedPreferences
    debugPrint('🔍 [NotifScreen] _loadDismissed -> staffId=${widget.staffId}');
    debugPrint('🔍 [NotifScreen] loaded dismissedLeaves=$loadedLeaves');
    debugPrint('🔍 [NotifScreen] loaded dismissedClaims=$loadedClaims');
    debugPrint('🔍 [NotifScreen] loaded dismissedSchedules=$loadedSchedules');
    debugPrint('🔍 [NotifScreen] loaded dismissedExchanges=$loadedExchanges');
    debugPrint('🔍 [NotifScreen] loaded clearedAt(raw)=$clearedStr');

    setState(() {
      _dismissedLeaves    = loadedLeaves.toSet();
      _dismissedClaims    = loadedClaims.toSet();
      _dismissedSchedules = loadedSchedules.toSet();
      _dismissedExchanges = loadedExchanges.toSet();
      _lastClearedAt      = clearedStr != null ? DateTime.tryParse(clearedStr) : null;
      _isLoadingPrefs     = false;
    });

    // 🔍 DEBUG: confirm parsed clearedAt and final in-memory sets
    debugPrint('🔍 [NotifScreen] parsed _lastClearedAt=$_lastClearedAt');
    debugPrint('🔍 [NotifScreen] in-memory dismissedLeaves=$_dismissedLeaves');
  }

  Future<void> _saveDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_leaveKey,    _dismissedLeaves.toList());
    await prefs.setStringList(_claimKey,    _dismissedClaims.toList());
    await prefs.setStringList(_scheduleKey, _dismissedSchedules.toList());
    await prefs.setStringList(_exchangeKey, _dismissedExchanges.toList());
    if (_lastClearedAt != null) {
      await prefs.setString(_clearedAtKey, _lastClearedAt!.toIso8601String());
    }

    // 🔍 DEBUG: confirm what was just written to disk, and read it back
    debugPrint('🔍 [NotifScreen] _saveDismissed -> staffId=${widget.staffId}');
    debugPrint('🔍 [NotifScreen] saved dismissedLeaves=$_dismissedLeaves');
    debugPrint('🔍 [NotifScreen] saved dismissedClaims=$_dismissedClaims');
    debugPrint('🔍 [NotifScreen] saved dismissedSchedules=$_dismissedSchedules');
    debugPrint('🔍 [NotifScreen] saved dismissedExchanges=$_dismissedExchanges');
    debugPrint('🔍 [NotifScreen] saved _lastClearedAt=$_lastClearedAt');

    // Read-back sanity check (helps catch silent write failures, esp. on web)
    final verifyLeaves = prefs.getStringList(_leaveKey);
    debugPrint('🔍 [NotifScreen] verify read-back dismissedLeaves=$verifyLeaves');
  }

  Future<void> _dismissLeave(String id) async {
    setState(() => _dismissedLeaves.add(id));
    await _saveDismissed();
  }

  Future<void> _dismissClaim(String id) async {
    setState(() => _dismissedClaims.add(id));
    await _saveDismissed();
  }

  Future<void> _dismissSchedule(String id) async {
    setState(() => _dismissedSchedules.add(id));
    await _saveDismissed();
  }

  Future<void> _dismissExchange(String id) async {
    setState(() => _dismissedExchanges.add(id));
    await _saveDismissed();
  }

  void _dismissAll(List leaves, List claims, List schedules,
      List exchanges) {
    // 🔍 DEBUG: snapshot exactly which IDs are about to be cleared
    debugPrint('🔍 [NotifScreen] _dismissAll called -> staffId=${widget.staffId}');
    debugPrint('🔍 [NotifScreen] about to clear leaves='
        '${leaves.map((l) => l.leaveId).toList()}');
    debugPrint('🔍 [NotifScreen] about to clear claims='
        '${claims.map((c) => c.claimId).toList()}');
    debugPrint('🔍 [NotifScreen] about to clear schedules='
        '${schedules.map((s) => s.schedId).toList()}');
    debugPrint('🔍 [NotifScreen] about to clear exchanges='
        '${exchanges.map((e) => e.exchangeId).toList()}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                shape: BoxShape.circle),
            child: const Icon(Icons.delete_sweep_rounded,
                color: Colors.red, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Clear All',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
            'Are you sure you want to clear all notifications?',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final now = DateTime.now();
              // 🔍 DEBUG: confirm the exact timestamp being stored as the cutoff
              debugPrint('🔍 [NotifScreen] Clear All confirmed -> '
                  'setting _lastClearedAt=$now');

              setState(() {
                _lastClearedAt = now;
                for (final l in leaves)
                  _dismissedLeaves.add(l.leaveId.toString());
                for (final c in claims)
                  _dismissedClaims.add(c.claimId.toString());
                for (final s in schedules)
                  _dismissedSchedules.add(s.schedId.toString());
                for (final e in exchanges)
                  _dismissedExchanges.add(e.exchangeId.toString());
              });
              await _saveDismissed();

              debugPrint('🔍 [NotifScreen] Clear All -> save complete. '
                  'Re-open the app/screen now and check the '
                  '_loadDismissed logs above to confirm persistence.');
            },
            child: const Text('Clear All',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _getBranchName(int workLocation) {
    const branches = {
      1: 'Chagar Hutang',
      2: 'Turtle Lab',
      3: 'UMT',
    };
    return branches[workLocation] ?? 'Unknown Location';
  }

  Widget _buildDismissBackground() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 22),
      );

  Widget _buildSectionHeader(
      String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B))),
      ]),
    );
  }

  Widget _buildNotifCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leading,
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  height: 1.5)),
        ),
        trailing: GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.close_rounded,
                size: 14, color: Colors.grey.shade500),
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    final bool approved = status == 'Approved';
    final color = approved ? Colors.green : Colors.red;
    final icon  = approved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10), shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: color),
    );
  }

  // ── Incoming exchange card ──────────────────────────────────────────────────
  Widget _buildExchangeIncomingCard(ScheduleExchange exchange) {
    String locationName(String? loc) {
      switch (loc) {
        case '1': return 'Chagar Hutang';
        case '2': return 'Turtle Lab';
        case '3': return 'UMT';
        default:  return loc ?? '—';
      }
    }

    Color locationColor(String? loc) {
      switch (loc) {
        case '1': return const Color(0xFF0891B2);
        case '2': return const Color(0xFF7C3AED);
        case '3': return const Color(0xFFF59E0B);
        default:  return Colors.grey;
      }
    }

    Widget locationBadge(String? loc) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: locationColor(loc).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: locationColor(loc).withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_rounded,
                size: 11, color: locationColor(loc)),
            const SizedBox(width: 3),
            Text(locationName(loc),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: locationColor(loc))),
          ]),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.indigo, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${exchange.requesterName ?? "Someone"} wants to swap schedules with you',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Their schedule',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(exchange.requesterWorkDate ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text(exchange.requesterStartTime ?? '—',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  locationBadge(exchange.requesterWorkLocation),
                ]),
              ),
              const Icon(Icons.compare_arrows_rounded,
                  color: Colors.grey),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Text('Your schedule',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(exchange.targetWorkDate ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text(exchange.targetStartTime ?? '—',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  locationBadge(exchange.targetWorkLocation),
                ]),
              ),
            ]),
          ),
          if (exchange.requesterNote != null &&
              exchange.requesterNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: "${exchange.requesterNote}"',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () => _respondToExchange(exchange, true),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Accept',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () => _respondToExchange(exchange, false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _respondToExchange(
      ScheduleExchange exchange, bool accept) async {
    final success = await Provider.of<ScheduleExchanges>(
            context, listen: false)
        .targetRespond(exchange.exchangeId, accept);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? accept
              ? '✅ Exchange accepted! Waiting for HR approval.'
              : '❌ Exchange rejected.'
          : 'Failed to respond. Try again.'),
      backgroundColor: success
          ? accept
              ? Colors.green
              : Colors.redAccent
          : Colors.grey,
    ));

    if (success) {
      Provider.of<ScheduleExchanges>(context, listen: false)
          .fetchExchangesByStaff(widget.staffId);
      if (accept && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pop(context, {'refreshDashboard': true});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return Scaffold(
        backgroundColor: staffBg,
        body: Center(
            child: CircularProgressIndicator(color: staffPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: staffBg,
      appBar: const StaffAppBar(title: 'NOTIFICATIONS', roundedBottom: false),
      body: Consumer4<Leaves, Claims, Schedules, ScheduleExchanges>(
        builder: (context, leavesProvider, claimsProvider,
            schedulesProvider, exchangesProvider, child) {
          final clearedAt = _lastClearedAt;

          final myLeaves = widget.isPartTimer
              ? []
              : leavesProvider.leaves
                  .where((l) =>
                      l.staffId == widget.staffId &&
                      l.status != 'Pending' &&
                      !_dismissedLeaves.contains(l.leaveId.toString()) &&
                      (clearedAt == null || l.updatedAt.isAfter(clearedAt)))
                  .toList();

          final myClaims = widget.isPartTimer
              ? []
              : claimsProvider.claims
                  .where((c) =>
                      c.staffId == widget.staffId &&
                      c.status != 'Pending' &&
                      !_dismissedClaims.contains(c.claimId.toString()) &&
                      (clearedAt == null || c.updatedAt.isAfter(clearedAt)))
                  .toList();

          final mySchedules = widget.isPartTimer
              ? []
              : schedulesProvider.schedules
                  .where((s) =>
                      s.staffId == widget.staffId &&
                      !_dismissedSchedules
                          .contains(s.schedId.toString()))
                  .toList();

          final incomingExchanges = exchangesProvider.exchanges
              .where((e) =>
                  e.targetId == widget.staffId &&
                  e.status == 0 &&
                  !_dismissedExchanges
                      .contains(e.exchangeId.toString()))
              .toList();

          final myExchanges = exchangesProvider.exchanges
              .where((e) =>
                  e.requesterId == widget.staffId &&
                  e.status != 0 &&
                  !_dismissedExchanges
                      .contains(e.exchangeId.toString()))
              .toList();

          final hasAny = myLeaves.isNotEmpty ||
              myClaims.isNotEmpty ||
              mySchedules.isNotEmpty ||
              incomingExchanges.isNotEmpty ||
              myExchanges.isNotEmpty;

          final totalCount = myLeaves.length +
              myClaims.length +
              mySchedules.length +
              incomingExchanges.length +
              myExchanges.length;

          // 🔍 DEBUG: per-build snapshot — compare this across app restarts
          debugPrint('🔍 [NotifScreen] build() -> staffId=${widget.staffId} '
              'clearedAt=$clearedAt totalCount=$totalCount '
              '(leaves=${myLeaves.length}, claims=${myClaims.length}, '
              'schedules=${mySchedules.length}, '
              'incomingExch=${incomingExchanges.length}, '
              'myExch=${myExchanges.length})');
          if (mySchedules.isNotEmpty) {
            debugPrint('🔍 [NotifScreen] mySchedules ids='
                '${mySchedules.map((s) => s.schedId).toList()} '
                '(NOTE: schedules are not filtered by clearedAt time, '
                'only by _dismissedSchedules)');
          }

          return Column(children: [
            // ── Header banner ───────────────────────────────────── (full-bleed, not width-capped)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 16, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                color: staffPrimary,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text('$totalCount',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('notifications',
                        style: TextStyle(
                            color: Colors.indigo.shade200,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ]),
                  if (hasAny)
                    GestureDetector(
                      onTap: () => _dismissAll(
                          myLeaves,
                          myClaims,
                          mySchedules,
                          [
                            ...incomingExchanges,
                            ...myExchanges
                          ]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.delete_sweep_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Clear all',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),

            // ── List body (width-capped) ────────────────────────────
            Expanded(
              child: StaffPageContainer(
              child: !hasAny
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.notifications_off_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No notifications right now',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600)),
                      ]))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          16, 20, 16, 40),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                        // ── Leave notifications ──────────────
                        if (myLeaves.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Leave Notifications',
                              Icons.beach_access_rounded,
                              Colors.red),
                          ...myLeaves.map((leave) => Dismissible(
                                key: Key(
                                    'leave_${leave.leaveId}'),
                                direction:
                                    DismissDirection.endToStart,
                                background:
                                    _buildDismissBackground(),
                                onDismissed: (_) => _dismissLeave(
                                    leave.leaveId.toString()),
                                child: _buildNotifCard(
                                  leading: _buildStatusIcon(
                                      leave.status),
                                  title: 'Leave ${leave.status}',
                                  subtitle:
                                      'From: ${leave.startDate}\nTo: ${leave.endDate}',
                                  accentColor:
                                      leave.status == 'Approved'
                                          ? Colors.green
                                          : Colors.red,
                                  onDismiss: () => _dismissLeave(
                                      leave.leaveId.toString()),
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],

                        // ── Claim notifications ──────────────
                        if (myClaims.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Claim Notifications',
                              Icons.request_page_rounded,
                              Colors.teal),
                          ...myClaims.map((claim) => Dismissible(
                                key: Key(
                                    'claim_${claim.claimId}'),
                                direction:
                                    DismissDirection.endToStart,
                                background:
                                    _buildDismissBackground(),
                                onDismissed: (_) => _dismissClaim(
                                    claim.claimId.toString()),
                                child: _buildNotifCard(
                                  leading: _buildStatusIcon(
                                      claim.status),
                                  title: 'Claim ${claim.status}',
                                  subtitle:
                                      'Type: ${claim.claimType}\nAmount: RM ${claim.amount}',
                                  accentColor:
                                      claim.status == 'Approved'
                                          ? Colors.green
                                          : Colors.red,
                                  onDismiss: () => _dismissClaim(
                                      claim.claimId.toString()),
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],

                        // ── Schedule notifications ───────────
                        if (mySchedules.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Your Schedules',
                              Icons.calendar_today_rounded,
                              Colors.orange),
                          ...mySchedules
                              .map((schedule) => Dismissible(
                                    key: Key(
                                        'schedule_${schedule.schedId}'),
                                    direction: DismissDirection
                                        .endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) =>
                                        _dismissSchedule(schedule
                                            .schedId
                                            .toString()),
                                    child: _buildNotifCard(
                                      leading: Container(
                                        padding:
                                            const EdgeInsets.all(
                                                10),
                                        decoration: BoxDecoration(
                                            color: staffPrimary
                                                .withOpacity(0.10),
                                            shape:
                                                BoxShape.circle),
                                        child: Icon(
                                            Icons
                                                .location_on_rounded,
                                            size: 22,
                                            color: staffPrimary),
                                      ),
                                      title: _getBranchName(
                                          schedule.workLocation),
                                      subtitle:
                                          'Date: ${DateFormat('dd MMM yyyy').format(schedule.workDate)}\n'
                                          'Time: ${schedule.workStartTime} – ${schedule.workEndTime}',
                                      accentColor: staffPrimary,
                                      onDismiss: () =>
                                          _dismissSchedule(schedule
                                              .schedId
                                              .toString()),
                                    ),
                                  )),
                          const SizedBox(height: 20),
                        ],

                        // ── Incoming exchange requests ────────
                        if (incomingExchanges.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Schedule Exchange Requests',
                              Icons.swap_horiz_rounded,
                              Colors.indigo),
                          ...incomingExchanges
                              .map((exchange) => Dismissible(
                                    key: Key(
                                        'exchange_${exchange.exchangeId}'),
                                    direction: DismissDirection
                                        .endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) =>
                                        _dismissExchange(exchange
                                            .exchangeId
                                            .toString()),
                                    child:
                                        _buildExchangeIncomingCard(
                                            exchange),
                                  )),
                          const SizedBox(height: 20),
                        ],

                        // ── My sent exchange updates ──────────
                        if (myExchanges.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Exchange Request Updates',
                              Icons.update_rounded,
                              Colors.teal),
                          ...myExchanges
                              .map((exchange) => Dismissible(
                                    key: Key(
                                        'myexchange_${exchange.exchangeId}'),
                                    direction: DismissDirection
                                        .endToStart,
                                    background:
                                        _buildDismissBackground(),
                                    onDismissed: (_) =>
                                        _dismissExchange(exchange
                                            .exchangeId
                                            .toString()),
                                    child: _buildNotifCard(
                                      leading: Container(
                                        padding:
                                            const EdgeInsets.all(
                                                10),
                                        decoration: BoxDecoration(
                                            color: exchange
                                                .statusColor
                                                .withOpacity(0.1),
                                            shape:
                                                BoxShape.circle),
                                        child: Icon(
                                            Icons
                                                .swap_horiz_rounded,
                                            color: exchange
                                                .statusColor,
                                            size: 22),
                                      ),
                                      title:
                                          'Exchange ${exchange.statusText}',
                                      subtitle:
                                          'Your request to swap with ${exchange.targetName ?? "staff"}\n'
                                          'Their date: ${exchange.targetWorkDate ?? "—"}'
                                          '${exchange.status == 4 && exchange.hrNote != null && exchange.hrNote!.isNotEmpty ? "\nHR Reason: ${exchange.hrNote}" : ""}',
                                      accentColor:
                                          exchange.statusColor,
                                      onDismiss: () =>
                                          _dismissExchange(exchange
                                              .exchangeId
                                              .toString()),
                                    ),
                                  )),
                          const SizedBox(height: 20),
                        ],
                      ]),
                    ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
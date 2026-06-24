import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
import 'package:charms/internshipscreens/intern_detail_submissions.dart';
import 'package:charms/internshipscreens/monitor_performance.dart';
import 'package:charms/internshipscreens/offer_letter_screen.dart';
import 'package:charms/internshipmodels/schedule.dart';

// ── Shared helper to build photo URL ──────────────────────────────────────────
String? buildPhotoUrl(String? filepath) {
  if (filepath == null || filepath.isEmpty) return null;
  return 'https://devcms.com.my/charmsAPI/public/storage/$filepath';
}

// ── Shared avatar widget ───────────────────────────────────────────────────────
Widget internAvatar(String firstName, String? photoUrl) {
  return CircleAvatar(
    radius: 25,
    backgroundColor: Colors.blueAccent,
    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
    child: photoUrl == null
        ? Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )
        : null,
  );
}

// ── Shared function to fetch all photos (user_id => filepath map) ──────────────
Future<Map<String, String>> fetchAllPhotos() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.hostname}/api/internship/registers/photos'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((k, v) => MapEntry(k, v.toString()));
    }
  } catch (_) {}
  return {};
}

// ─────────────────────────────────────────
// INTERN LIST — view only (admin sees details)
// ─────────────────────────────────────────
class InternListPage extends StatefulWidget {
  final bool canAssess;

  const InternListPage({super.key, this.canAssess = false});

  @override
  _InternListPageState createState() => _InternListPageState();
}

class _InternListPageState extends State<InternListPage> {
  List<dynamic> _allInterns = [];
  List<dynamic> _filteredInterns = [];
  Map<String, String> _photoMap = {}; // user_id => filepath

  String _searchQuery = '';
  String? _selectedTeam; // null = All teams
  int? _selectedYear; // null = All years
  String? _selectedStatus; // null = All, 'active', 'completed'
  bool _sortAscending = true; // A-Z by default
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadInterns();
  }

  Future<void> _loadInterns() async {
    await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;

    final photos = await fetchAllPhotos();

    final years = interns
        .map((i) => _getYear(i))
        .where((y) => y != null)
        .cast<int>()
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _allInterns = interns;
      _photoMap = photos;
      _availableYears = years;
    });
    _applyFilters();
  }

  // ── Helpers to read team/year, with fallback keys in case your API uses
  //    a different field name — adjust here if needed ─────────────────────
  String? _getTeam(dynamic intern) {
    return intern['team'] ?? intern['internship_team'] ?? intern['department'];
  }

  int? _getYear(dynamic intern) {
    final raw = intern['year'] ??
        intern['created_at'] ??
        intern['registration_date'] ??
        intern['start_date'];
    if (raw == null) return null;
    if (raw is int) return raw;
    final match = RegExp(r'(\d{4})').firstMatch(raw.toString());
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  // Returns 'active' or 'completed' based on end_date or status field.
  String _getStatus(dynamic intern) {
    final rawStatus = intern['status']?.toString().toLowerCase();
    if (rawStatus != null) {
      if (rawStatus == 'completed' || rawStatus == 'inactive' || rawStatus == 'done') {
        return 'completed';
      }
      if (rawStatus == 'active' || rawStatus == 'ongoing') return 'active';
    }
    final endRaw = intern['end_date'] ?? intern['schedule_end_date'];
    if (endRaw != null) {
      final endDate = DateTime.tryParse(endRaw.toString());
      if (endDate != null) {
        return DateTime.now().isAfter(endDate) ? 'completed' : 'active';
      }
    }
    return 'active';
  }

  void _applyFilters() {
    List<dynamic> result = List.from(_allInterns);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((i) => (i['first_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedTeam != null) {
      result = result.where((i) => _getTeam(i) == _selectedTeam).toList();
    }

    if (_selectedYear != null) {
      result = result.where((i) => _getYear(i) == _selectedYear).toList();
    }

    if (_selectedStatus != null) {
      result = result.where((i) => _getStatus(i) == _selectedStatus).toList();
    }

    result.sort((a, b) {
      final nameA = (a['first_name'] ?? '').toString().toLowerCase();
      final nameB = (b['first_name'] ?? '').toString().toLowerCase();
      return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });

    setState(() {
      _filteredInterns = result;
    });
  }

  void _filterInterns(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _selectedTeam != null || _selectedYear != null || _selectedStatus != null || !_sortAscending;

  void _clearFilters() {
    setState(() {
      _selectedTeam = null;
      _selectedYear = null;
      _selectedStatus = null;
      _sortAscending = true;
    });
    _applyFilters();
  }

  void _openFilterSheet() {
    String? tempTeam = _selectedTeam;
    int? tempYear = _selectedYear;
    String? tempStatus = _selectedStatus;
    bool tempAscending = _sortAscending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Status filter
                  const Text('Status',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: tempStatus == null,
                          onSelected: (_) =>
                              setSheetState(() => tempStatus = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Active'),
                          selected: tempStatus == 'active',
                          selectedColor: Colors.green[100],
                          onSelected: (_) =>
                              setSheetState(() => tempStatus = 'active'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Completed'),
                          selected: tempStatus == 'completed',
                          selectedColor: Colors.grey[300],
                          onSelected: (_) =>
                              setSheetState(() => tempStatus = 'completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort by name
                  const Text('Sort by name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('A → Z'),
                          selected: tempAscending,
                          onSelected: (_) =>
                              setSheetState(() => tempAscending = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Z → A'),
                          selected: !tempAscending,
                          onSelected: (_) =>
                              setSheetState(() => tempAscending = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Team filter
                  const Text('Team',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: tempTeam,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Teams'),
                      ),
                      ...kInternshipTeams.map(
                        (team) => DropdownMenuItem<String?>(
                          value: team,
                          child: Text(team),
                        ),
                      ),
                    ],
                    onChanged: (val) => setSheetState(() => tempTeam = val),
                  ),
                  const SizedBox(height: 20),

                  // Year filter
                  const Text('Year',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: tempYear,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Years'),
                      ),
                      ..._availableYears.map(
                        (year) => DropdownMenuItem<int?>(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      ),
                    ],
                    onChanged: (val) => setSheetState(() => tempYear = val),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempTeam = null;
                              tempYear = null;
                              tempStatus = null;
                              tempAscending = true;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedTeam = tempTeam;
                              _selectedYear = tempYear;
                              _selectedStatus = tempStatus;
                              _sortAscending = tempAscending;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Apply',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intern List'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterInterns,
                    decoration: InputDecoration(
                      hintText: 'Search Interns...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasActiveFilters
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          _hasActiveFilters ? Colors.blueAccent : Colors.grey,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_selectedTeam != null)
                        Chip(
                          label: Text(_selectedTeam!),
                          onDeleted: () {
                            setState(() => _selectedTeam = null);
                            _applyFilters();
                          },
                        ),
                      if (_selectedYear != null)
                        Chip(
                          label: Text(_selectedYear!.toString()),
                          onDeleted: () {
                            setState(() => _selectedYear = null);
                            _applyFilters();
                          },
                        ),
                      if (_selectedStatus != null)
                        Chip(
                          label: Text(
                            _selectedStatus == 'active' ? 'Active' : 'Completed',
                          ),
                          backgroundColor: _selectedStatus == 'active'
                              ? Colors.green[100]
                              : Colors.grey[300],
                          onDeleted: () {
                            setState(() => _selectedStatus = null);
                            _applyFilters();
                          },
                        ),
                      if (!_sortAscending)
                        Chip(
                          label: const Text('Z → A'),
                          onDeleted: () {
                            setState(() => _sortAscending = true);
                            _applyFilters();
                          },
                        ),
                      ActionChip(
                        label: const Text('Clear all'),
                        onPressed: _clearFilters,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            _filteredInterns.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'No interns found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _filteredInterns.length,
                      itemBuilder: (context, index) {
                        final intern = _filteredInterns[index];
                        final userId = intern['user_id'].toString();
                        final photoUrl = buildPhotoUrl(_photoMap[userId]);
                        final internIdInt = (intern['user_id'] as num).toInt();
                        final firstName = intern['first_name'] ?? '?';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: internAvatar(firstName, photoUrl),
                                title: Text(firstName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Age: ${intern['age']} - Gender: ${intern['gender']}"),
                                    if ((intern['slot_count'] ?? 1) > 1)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.blueAccent),
                                        ),
                                        child: Text(
                                          '${intern['slot_count']} slots registered',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InternDetailScreen(
                                          internId: internIdInt),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MonitorPerformancePage(
                                                role: 'Admin',
                                                userId: internIdInt,
                                                internId: userId,
                                                internName: firstName,
                                                preselectedInternId:
                                                    internIdInt,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.bar_chart,
                                            size: 18),
                                        label: const Text('Monitor'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blueAccent,
                                          side: const BorderSide(
                                              color: Colors.blueAccent),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AssessmentInternPage(
                                                internId: internIdInt,
                                                photoUrl: photoUrl,
                                                canAssess: widget.canAssess,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.rate_review,
                                            size: 18, color: Colors.white),
                                        label: const Text('Assess',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blueAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OfferLetterScreen(
                                            userId: internIdInt,
                                            role: 'Admin',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.description_rounded,
                                        size: 18),
                                    label: const Text('View Offer Letter'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.teal,
                                      side: const BorderSide(
                                          color: Colors.teal),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:charms/internshipscreens/assessment_intern.dart';
import 'package:charms/internshipscreens/intern_detail_submissions.dart';
import 'package:charms/internshipscreens/monitor_performance.dart'; 

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
  const InternListPage({super.key});

  @override
  _InternListPageState createState() => _InternListPageState();
}

class _InternListPageState extends State<InternListPage> {
  List<dynamic> _filteredInterns = [];
  Map<String, String> _photoMap = {}; // user_id => filepath

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

    setState(() {
      _filteredInterns = interns;
      _photoMap = photos;
    });
  }

  void _filterInterns(String query) {
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    setState(() {
      _filteredInterns = query.isEmpty
          ? interns
          : interns
              .where((intern) => intern['first_name']
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
    });
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
            TextField(
              onChanged: _filterInterns,
              decoration: InputDecoration(
                hintText: 'Search Interns...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
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
                                  Text("Age: ${intern['age']} - Gender: ${intern['gender']}"),
                                  if ((intern['slot_count'] ?? 1) > 1)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blueAccent),
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
                                    builder: (context) => InternDetailScreen(internId: internIdInt),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MonitorPerformancePage(
                                              role: 'Admin',
                                              userId: internIdInt,
                                              internId: userId,
                                              internName: firstName,
                                              preselectedInternId: internIdInt,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.bar_chart, size: 18),
                                      label: const Text('Monitor'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blueAccent,
                                        side: const BorderSide(color: Colors.blueAccent),
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
                                            builder: (context) => AssessmentInternPage(
                                              internId: internIdInt,
                                              photoUrl: photoUrl,
                                              isAdmin: true,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.rate_review, size: 18, color: Colors.white),
                                      label: const Text('Assess', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    ),
                                  ),
                                ],
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

// ─────────────────────────────────────────
// ASSESSMENT LIST — tap to rate intern
// ─────────────────────────────────────────
class AssessmentListPage extends StatefulWidget {
  const AssessmentListPage({super.key});

  @override
  _AssessmentListPageState createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends State<AssessmentListPage> {
  List<dynamic> _filteredInterns = [];
  Map<String, String> _photoMap = {};

  @override
  void initState() {
    super.initState();
    _loadInterns();
  }

  Future<void> _loadInterns() async {
    await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    for (var intern in interns) {
    print('DEBUG intern: $intern');
  }
    final photos = await fetchAllPhotos();

    print('DEBUG photoMap keys: ${photos.keys.toList()}');
    print('DEBUG intern user_ids: ${interns.map((i) => i['user_id']).toList()}');

    setState(() {
      //Filter out any interns with missing required fields
      _filteredInterns = interns.where((intern) =>
        intern != null &&
        intern['first_name'] != null &&
        intern['user_id'] != null
      ).toList();
      _photoMap = photos;
    });
  }

  void _filterInterns(String query) {
  final interns =
      Provider.of<RegisterProvider>(context, listen: false).internList;
  final safe = interns.where((i) =>
    i != null && i['first_name'] != null).toList();

  setState(() {
    _filteredInterns = query.isEmpty
        ? safe
        : safe.where((intern) => intern['first_name']
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _filterInterns,
              decoration: InputDecoration(
                hintText: 'Search Interns...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
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
                        final userId = intern['user_id']?.toString() ?? '';
                        final firstName = intern['first_name'] ?? '?';
                        final photoUrl = userId.isNotEmpty ? buildPhotoUrl(_photoMap[userId]) : null;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: internAvatar(firstName, photoUrl),
                            title: Text(firstName),
                            subtitle: Text(
                              "Age: ${intern['age']} - Gender: ${intern['gender']}",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      final userId = intern['user_id']?.toString() ?? '';
                                      final photoUrl = buildPhotoUrl(_photoMap[userId]);
                                      return AssessmentInternPage(
                                        internId: (intern['user_id'] as num).toInt(), 
                                        photoUrl: photoUrl,
                                        isAdmin: true,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text('Assess',
                                  style: TextStyle(color: Colors.white)),
                            ),
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
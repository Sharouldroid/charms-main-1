import 'package:flutter/material.dart';
import 'package:charms/internshipscreens/intern_detail_submissions.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class InternListScreen extends StatefulWidget {
  const InternListScreen({super.key});

  @override
  _InternListScreenState createState() => _InternListScreenState();
}

class _InternListScreenState extends State<InternListScreen> {
  List<dynamic> _filteredInterns = [];
  Map<String, String> _photoMap = {}; // user_id => filepath
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInterns();
  }

  Future<void> _loadInterns() async {
    await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;

    // Fetch photos in parallel
    final photos = await _fetchAllPhotos();

    setState(() {
      _filteredInterns = interns;
      _photoMap = photos;
    });
  }

  Future<Map<String, String>> _fetchAllPhotos() async {
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

  String? _buildPhotoUrl(String? filepath) {
    if (filepath == null || filepath.isEmpty) return null;
    return 'https://devcms.com.my/charmsAPI/public/storage/$filepath';
  }

  void _filterInterns(String query) {
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    setState(() {
      _filteredInterns = query.isEmpty
          ? interns
          : interns
              .where((intern) => intern['first_name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Intern Submissions"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterInterns(_searchQuery);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Interns...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // List Section
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
                        final photoUrl =
                            _buildPhotoUrl(_photoMap[userId]);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Text(
                                      firstName.isNotEmpty
                                          ? firstName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              '${intern['first_name']} ${intern['last_name'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Age: ${intern['age']} - Gender: ${intern['gender']}"),
                                if ((intern['slot_count'] ?? 1) > 1)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.blueAccent),
                                    ),
                                    child: Text(
                                      '${intern['slot_count']} slots',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InternDetailScreen(
                                      // ← FIXED: use user_id not id
                                      internId: (intern['user_id'] as num)
                                          .toInt(),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text("Review"),
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
import 'package:flutter/material.dart';
import 'package:charms/internshipservices/register_service.dart';
import 'package:charms/internshipscreens/intern_list_assesstment.dart'
    show buildPhotoUrl, internAvatar, fetchAllPhotos;
import 'package:charms/internshipscreens/alumni_update_screen.dart';

/// Admin-only screen listing interns whose internship has ended, so their
/// alumni career updates can be reviewed.
class AlumniListScreen extends StatefulWidget {
  const AlumniListScreen({super.key});

  @override
  State<AlumniListScreen> createState() => _AlumniListScreenState();
}

class _AlumniListScreenState extends State<AlumniListScreen> {
  final RegisterService _registerService = RegisterService();

  List<dynamic> _alumni = [];
  List<dynamic> _filtered = [];
  Map<String, String> _photoMap = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAlumni();
  }

  // Same completed/active classification used in intern_list_assesstment.dart.
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

  Future<void> _loadAlumni() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _registerService.fetchInterns(),
        fetchAllPhotos(),
      ]);
      final allInterns = results[0] as List<dynamic>;
      final photoMap = results[1] as Map<String, String>;
      setState(() {
        _alumni = allInterns.where((i) => _getStatus(i) == 'completed').toList();
        _photoMap = photoMap;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load alumni list.';
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_alumni);
      return;
    }
    final q = _searchQuery.toLowerCase();
    _filtered = _alumni.where((i) {
      final name = '${i['first_name'] ?? ''} ${i['last_name'] ?? ''}'.toLowerCase();
      final institution = (i['institution_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || institution.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Alumni'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAlumni,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadAlumni,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search alumni by name or institution',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _applySearch();
                        }),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                _alumni.isEmpty ? 'No alumni yet' : 'No alumni match your search',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final intern = _filtered[index];
                                final userId = (intern['user_id'] as num).toInt();
                                final firstName = (intern['first_name'] ?? '').toString();
                                final lastName = (intern['last_name'] ?? '').toString();
                                final name = '$firstName $lastName'.trim();
                                final photoUrl = buildPhotoUrl(_photoMap[userId.toString()]);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    leading: internAvatar(firstName, photoUrl),
                                    title: Text(name.isEmpty ? 'Unknown' : name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: intern['institution_name'] != null
                                        ? Text(intern['institution_name'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)
                                        : null,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AlumniUpdateScreen(
                                            userId: userId,
                                            isAdminView: true,
                                            internName: name.isEmpty ? null : name,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

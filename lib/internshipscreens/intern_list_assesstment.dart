import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'assesstment_screen.dart';
import 'package:charms/internshipscreens/intern_detail_submissions.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInterns();
  }

  Future<void> _loadInterns() async {
    await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    setState(() {
      _filteredInterns = interns;
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
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                intern['first_name'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(intern['first_name']),
                            subtitle: Text(
                              "Age: ${intern['age']} - Gender: ${intern['gender']}",
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InternDetailScreen(internId: intern['id']),
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

  @override
  void initState() {
    super.initState();
    _loadInterns();
  }

  Future<void> _loadInterns() async {
    await Provider.of<RegisterProvider>(context, listen: false).loadInterns();
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    setState(() {
      _filteredInterns = interns;
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
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                intern['first_name'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(intern['first_name']),
                            subtitle: Text(
                              "Age: ${intern['age']} - Gender: ${intern['gender']}",
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NextPage(internId: intern['id']),
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
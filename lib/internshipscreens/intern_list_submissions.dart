import 'package:flutter/material.dart';
import 'package:charms/internshipscreens/intern_detail_submissions.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/register_provider.dart';

class InternListScreen extends StatefulWidget {
  const InternListScreen({super.key});

  @override
  _InternListScreenState createState() => _InternListScreenState();
}

class _InternListScreenState extends State<InternListScreen> {
  List<dynamic> _filteredInterns = [];
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
    setState(() {
      _filteredInterns = interns;
    });
  }

  void _filterInterns(String query) {
    final interns =
        Provider.of<RegisterProvider>(context, listen: false).internList;
    if (query.isEmpty) {
      setState(() {
        _filteredInterns = interns;
      });
    } else {
      setState(() {
        _filteredInterns = interns
            .where((intern) => intern['first_name']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Intern Submissions"),
        backgroundColor: Colors.blueAccent,
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
                                    builder: (context) => InternDetailScreen(
                                        internId: intern['id']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
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

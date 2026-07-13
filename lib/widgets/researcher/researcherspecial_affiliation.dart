import 'package:charms/providers/events_special.dart';
import 'package:charms/utils/download_bytes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ResearcherspecialAffiliation extends StatelessWidget {
  const ResearcherspecialAffiliation({
    super.key,
    required this.hostname,
    required this.specialid,
  });

  final String hostname;
  final int specialid;

  Future<void> downloadPdf(String url, String filename) async {
    // Validate URL
    if (!Uri.parse(url).isAbsolute) {
      throw Exception('Invalid URL: $url');
    }

    // Sanitize filename
    final sanitizedFilename = filename.replaceAll(RegExp(r'[^\w.-]'), '_');
    if (sanitizedFilename.isEmpty) {
      throw Exception('Invalid filename');
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }
      await downloadBytes(bytes: response.bodyBytes, fileName: sanitizedFilename);
    } catch (e) {
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Affiliation Data')),
      body: FutureBuilder(
        future: Provider.of<EventsSpecial>(
          context,
          listen: false,
        ).fetchAffiliation(hostname, specialid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<EventsSpecial>(
              builder: (ctx, rssdata, child) {
                if (rssdata.rssAffiliation.isEmpty) {
                  return const Center(child: Text('No data.'));
                }

                return ListView.builder(
                  itemCount: rssdata.rssAffiliation.length,
                  itemBuilder: (_, i) {
                    final affiliation = rssdata.rssAffiliation[i];
                    // final fileUrl =
                    //     '${hostname}uploads/abstract/${affiliation.filename}';

                    final fileUrl =
                        'https://devcms.com.my/charmsAPI/public/uploads/abstract/${affiliation.filename}';
                    final filename = affiliation.filename;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${affiliation.title}, ${affiliation.department}, ${affiliation.institution}, ${affiliation.location}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            if (affiliation.filename.isNotEmpty)
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await downloadPdf(fileUrl, filename);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Downloaded'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Download failed: $e'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Abstract'),
                              )
                            else
                              const Text(
                                'No document available.',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

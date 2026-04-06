import 'dart:io';
import 'package:charms/providers/events_special.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ResearcherspecialAffiliation extends StatelessWidget {
  const ResearcherspecialAffiliation({
    super.key,
    required this.hostname,
    required this.specialid,
  });

  final String hostname;
  final int specialid;

  Future<String> downloadPdf(String url, String filename) async {
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
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$sanitizedFilename';
      final file = File(filePath);

      // Check if file already exists
      if (await file.exists()) {
        final modified = await file.lastModified();
        final age = DateTime.now().difference(modified);
        if (age.inDays < 7) {
          // Use cached file if less than 7 days old
          return filePath;
        }
      }

      // Create request
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      // Track download progress
      final contentLength = response.contentLength;
      int receivedLength = 0;
      final List<int> chunks = [];

      await for (final chunk in response) {
        chunks.addAll(chunk);
        receivedLength += chunk.length;

        // Optional: Add progress callback here if needed
        // progressCallback?.call(receivedLength, contentLength);
      }

      // Write file
      await file.writeAsBytes(chunks, flush: true);
      return filePath;
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP request failed: ${e.message}');
    } on FileSystemException catch (e) {
      throw Exception('File system error: ${e.message}');
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
                                    final filePath = await downloadPdf(
                                      fileUrl,
                                      filename,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Downloaded to: $filePath',
                                        ),
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

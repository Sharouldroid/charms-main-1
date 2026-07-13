import 'package:charms/providers/events_kpp.dart';
import 'package:charms/utils/download_bytes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class KPPUpload extends StatefulWidget {
  const KPPUpload({
    super.key,
    required this.hostname,
    required this.type,
    required this.kppid,
  });

  final String hostname;
  final String type;
  final int kppid;

  @override
  State<KPPUpload> createState() => _KPPUploadState();
}

class _KPPUploadState extends State<KPPUpload> {
  String? _filename;
  PlatformFile? _selectedFile;
  String? urlsegment;
  String? fileUrl;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
    }
  }

  void _uploadData(String type) async {
    if (_selectedFile != null) {
      _filename = '${DateTime.now().toIso8601String()}-${_selectedFile!.name}';

      if (type == 'Participants') {
        urlsegment = 'uploadkppgroup';
        Provider.of<EventsKPP>(context, listen: false)
            .storeKPP(widget.hostname, widget.kppid, _filename!, 1);
      } else {
        urlsegment = 'uploadkppindemnity';
        Provider.of<EventsKPP>(context, listen: false)
            .storeKPP(widget.hostname, widget.kppid, _filename!, 2);
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.hostname}$urlsegment'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFile!.bytes!,
        filename: _filename,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedResponse = responseData;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload successful: $decodedResponse')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
      }
    } else if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
    }
  }

  Future<void> downloadPdf(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await downloadBytes(bytes: response.bodyBytes, fileName: filename);
    } else {
      throw Exception('Failed to download file');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'Participants') {
      fileUrl = '${widget.hostname}uploads/kpp/group/';
    } else {
      fileUrl = '${widget.hostname}uploads/kpp/indemnity/';
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.type)),
      body: FutureBuilder(
        future: widget.type == 'Participants'
            ? Provider.of<EventsKPP>(context, listen: false)
                .fetchKPPData(widget.hostname, widget.kppid, 1)
            : Provider.of<EventsKPP>(context, listen: false)
                .fetchKPPData(widget.hostname, widget.kppid, 2),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return Consumer<EventsKPP>(
                builder: (ctx, eventData, child) => eventData.kppdata.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: eventData.kppdata.length,
                        itemBuilder: (_, i) =>
                            // ListTile(
                            //   title: Text(
                            //     eventData.kppdata[i].filename,
                            //     style: const TextStyle(
                            //         fontWeight: FontWeight.bold,
                            //         color: Colors.yellow),
                            //   ),
                            // ),
                            // widget.type == 'Participants'
                            //     ? PdfViewer(
                            //         fileUrl:
                            //             '${widget.hostname}uploads/kpp/group/${eventData.kppdata[i].filename}')
                            //     : PdfViewer(
                            //         fileUrl:
                            //             '${widget.hostname}uploads/kpp/indemnity/${eventData.kppdata[i].filename}'))

                            Center(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await downloadPdf(
                                        '$fileUrl${eventData.kppdata[i].filename}',
                                        eventData.kppdata[i].filename);
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
                                child: Text('Download ${widget.type}'),
                              ),
                            ))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                'No ${widget.type.toLowerCase()} data available.'),
                            TextButton(
                                onPressed: _pickFile,
                                child: const Text('Choose File')),
                            if (_selectedFile != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                    'Selected File: ${_selectedFile!.name}'),
                              ),
                            TextButton.icon(
                              onPressed: () => _uploadData(widget.type),
                              icon: const Icon(Icons.upload),
                              label: Text('Upload ${widget.type}'),
                            ),
                          ],
                        ),
                      ),
              );
            }
          }
        },
      ),
    );
  }
}

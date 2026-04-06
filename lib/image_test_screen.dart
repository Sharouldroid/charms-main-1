import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:charms/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/attendances.dart';

class ImageTestScreen extends StatefulWidget {
  const ImageTestScreen({Key? key}) : super(key: key);

  @override
  _ImageTestScreenState createState() => _ImageTestScreenState();
}

class _ImageTestScreenState extends State<ImageTestScreen> {
  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = true;
  String? selectedImageData;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => isLoading = true);
    try {
      final attendanceProvider =
          Provider.of<Attendances>(context, listen: false);
      final records = await attendanceProvider.getAllAttendances();
      setState(() {
        attendanceRecords = records;
        isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendances: $error')),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Test'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: attendanceRecords.length,
                    itemBuilder: (ctx, index) {
                      final record = attendanceRecords[index];
                      return ListTile(
                        title: Text('Record ID: ${record['attendance_id']}'),
                        subtitle: Text('Staff ID: ${record['staff_id']}'),
                        trailing: record['clock_in_image'] != null
                            ? Icon(Icons.image, color: Colors.green)
                            : Icon(Icons.no_photography, color: Colors.red),
                        onTap: () {
                          setState(() {
                            selectedImageData = record['clock_in_image'];
                            selectedIndex = index;
                          });
                        },
                        selected: index == selectedIndex,
                      );
                    },
                  ),
                ),
                Divider(thickness: 2),
                Expanded(
                  flex: 2,
                  child: selectedImageData == null
                      ? Center(child: Text('Select a record to view its image'))
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Text('Image Data Type: ${selectedImageData.runtimeType}'),
                              if (selectedImageData is String)
                                Text('String Length: ${selectedImageData?.length}'),
                              // Removed block assuming selectedImageData is a Map
                              SizedBox(height: 20),
                              Text('Image Preview:'),
                              SizedBox(height: 10),
                              ImageUtils.buildImageWidget(
                                selectedImageData,
                                height: 200,
                                width: 200,
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedImageData is String) {
                                    _testBase64Decoding(selectedImageData!);
                                  }
                                },
                                child: Text('Test Base64 Decoding'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _testBase64Decoding(String data) {
    try {
      // Try to decode the base64 string
      final bytes = base64Decode(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully decoded ${bytes.length} bytes')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decoding base64: $e')),
      );
      
      // Try to clean up the string
      try {
        String cleaned = data.trim();
        cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
        while (cleaned.length % 4 != 0) {
          cleaned += '=';
        }
        
        final bytes = base64Decode(cleaned);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully decoded ${bytes.length} bytes after cleaning')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error decoding even after cleaning: $e')),
        );
      }
    }
  }
}

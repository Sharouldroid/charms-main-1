import 'package:charms/models/user.dart';
import 'package:charms/screens/specialindemnity_screen.dart';
import 'package:charms/widgets/researcher/groupspecial_booking.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ResearcherSpecialInfo extends StatefulWidget {
  const ResearcherSpecialInfo({
    super.key,
    required this.hostname,
    required this.user,
    required this.pax,
    required this.eventprice,
    required this.boatprice,
    required this.startdate,
    required this.enddate,
  });

  final String hostname;
  final User user;
  final int pax;
  final int eventprice;
  final int boatprice;
  final String startdate;
  final String enddate;

  @override
  State<ResearcherSpecialInfo> createState() => _ResearcherSpecialInfoState();
}

class _ResearcherSpecialInfoState extends State<ResearcherSpecialInfo> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _department;
  String? _institution;
  String? _location;
  String? _filename;
  PlatformFile? _selectedFile;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

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

  void _submitForm(int pax) async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      _formKey.currentState!.save();
      _filename = '${DateTime.now().toIso8601String()}-${_selectedFile!.name}';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.hostname}rss/uploadabstract'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path!,
        filename: _filename,
      ));

      final response = await request.send();
      // final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // final decodedResponse = responseData;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File Uploaded')));

        if (pax > 1) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => GroupSpecialBooking(
                    pax: pax,
                    user: widget.user,
                    eventid: 0,
                    title: 'Researcher Special Slot',
                    price: widget.eventprice + widget.boatprice,
                    confirmnum: 0,
                    startdate: widget.startdate,
                    enddate: widget.enddate,
                    hostname: widget.hostname,
                    booktype: 4,
                    staff: false,
                    boatprice: widget.boatprice,
                    eventprice: widget.eventprice,
                    affiliatetitle: _title!,
                    department: _department!,
                    institution: _institution!,
                    location: _location!,
                    filename: _filename!,
                  )));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => SpecialIndemnityScreen(
                    pax: pax,
                    user: widget.user,
                    eventid: 0,
                    title: 'Researcher Special Slot',
                    startdate: widget.startdate,
                    enddate: widget.enddate,
                    hostname: widget.hostname,
                    type: 4,
                    answers: '',
                    boatprice: widget.boatprice,
                    eventprice: widget.eventprice,
                    affiliatetitle: _title!,
                    department: _department!,
                    institution: _institution!,
                    location: _location!,
                    filename: _filename!,
                  )));
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Researcher Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Title / Position'),
                onSaved: (value) {
                  _title = value;
                },
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Department / Division'),
                onSaved: (value) {
                  _department = value;
                },
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Institution Name'),
                onSaved: (value) {
                  _institution = value;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (value) {
                  _location = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Upload Research Abstract'),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Selected File: ${_selectedFile!.name}'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitForm(widget.pax),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:charms/providers/events.dart';
// IMPORT BOOKEVENTS PROVIDER
import 'package:charms/providers/bookevents.dart';
import 'package:charms/utils/download_bytes.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import 'package:charms/models/user.dart';
import 'package:charms/widgets/volunteer/book_slot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewEvent extends StatefulWidget {
  const ViewEvent({
    super.key,
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.eventid,
    required this.datebook,
    required this.price,
    this.confirmnum = 0,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.datediff,
    this.booktype = 0,
    this.ischild = false,
    this.pax = 1,
    this.paid = 0,
    required this.total,
    required this.status,
    required this.cancelreason,
    required this.slotvolunteer,
  });

  final String title;
  final String startdate;
  final String enddate;
  final int eventid;
  final String datebook;
  final double price;
  final int confirmnum;
  final bool staff;
  final User user;
  final String hostname;
  final Duration datediff;
  final int booktype;
  final bool ischild;
  final int pax;
  final int paid;
  final double total;
  final int status;
  final String cancelreason;
  final int slotvolunteer;

  @override
  State<ViewEvent> createState() => _ViewEventState();
}

class _ViewEventState extends State<ViewEvent> {
  final StreamController _streamController = StreamController();
  final GlobalKey<FormState> _shirtFormKey = GlobalKey();
  final GlobalKey<FormState> _groupFormKey = GlobalKey();
  final GlobalKey<FormState> _groupShirtFormKey = GlobalKey();
  int pax = 7;
  int confirmnum = 0;
  String? _currentPosterUrl;
  bool _posterLoading = false;
  bool _posterError = false;
  late num slotcount;
  String shirtsize = 'XS';
  List<String> size = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  // --- Diet Restriction State ---
  String _selectedDiet = 'None';
  final TextEditingController _allergyController = TextEditingController();

  // --- Health Info State ---
  String _selectedHealth = 'No Health Issue';
  final TextEditingController _healthController = TextEditingController();

  // --- NEW: Emergency Contact State ---
  final TextEditingController _eNameController = TextEditingController();
  final TextEditingController _ePhoneController = TextEditingController();
  String? _selectedRelationship;
  final GlobalKey<FormState> _emergencyFormKey = GlobalKey();
  bool _contactLoading = false;
  final List<String> _relationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Relative',
    'Friend',
    'Guardian',
    'Partner',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentPoster();
    slotcount = widget.slotvolunteer;
  }

  @override
  void dispose() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _allergyController.dispose();
    _healthController.dispose();
    _eNameController.dispose();
    _ePhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPoster() async {
    setState(() {
      _posterLoading = true;
      _posterError = false;
    });

    try {
      final response = await http
          .get(Uri.parse('${widget.hostname}fileupload/getcurrentposter'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentPosterUrl = data['url'];
          _posterLoading = false;
        });
      } else {
        setState(() {
          _posterLoading = false;
          _posterError = true;
        });
      }
    } catch (e) {
      setState(() {
        _posterLoading = false;
        _posterError = true;
      });
      debugPrint('Error loading poster: $e');
    }
  }

  // --- UPDATED: _proceed now accepts diet and health info ---
  Future<void> _proceed(
      int pax, int type, String shirtsize, String dietRestriction, String healthInfo) async {
    
    setState(() {});

    var rnd = math.Random();
    var next = rnd.nextDouble() * 1000000;
    while (next < 100000) {
      next *= 10;
    }
    confirmnum = next.toInt();

    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => BookSlot(
            booktype: type,
            pax: pax,
            user: widget.user,
            eventid: widget.eventid,
            confirmnum: confirmnum,
            startdate: widget.startdate,
            enddate: widget.enddate,
            hostname: widget.hostname,
            price: widget.price,
            title: widget.title,
            shirtsize: shirtsize,
            staff: widget.staff,
            diet: dietRestriction,
            health: healthInfo,
            // NOTE: Ensure BookSlot accepts 'health' parameter. 
            // If not, you will need to add it to BookSlot.dart just like you did for diet.
            // health: healthInfo, 
          ),
        ),
      );
    } catch (e) {
      rethrow;
    }

    setState(() {});
  }

  // --- 1. Emergency Contact Dialog (Step 4) ---
  void _showEmergencyContactDialog(
      int p, int type, String shirt, String finalDietData, String finalHealthData) async {
    
    // Fetch existing contact first
    setState(() => _contactLoading = true);
    final existing = await Provider.of<BookEvents>(context, listen: false)
        .fetchEmergencyContact(widget.hostname, int.parse(widget.user.id));
    
    if (existing != null) {
      _eNameController.text = existing['name'];
      _ePhoneController.text = existing['phone'];
      _selectedRelationship = existing['relationship'];
    } else {
      _eNameController.clear();
      _ePhoneController.clear();
      _selectedRelationship = null;
    }
    setState(() => _contactLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.contact_emergency, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            const Text('Emergency Contact', textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _emergencyFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please provide an emergency contact who can be reached during the event.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _eNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter contact\'s full name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ePhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter contact\'s phone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelationship,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.people),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _relationships.map((String relationship) {
                    return DropdownMenuItem<String>(
                      value: relationship,
                      child: Text(relationship),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelationship = value;
                    });
                  },
                  validator: (val) => val == null ? 'Please select a relationship' : null,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_emergencyFormKey.currentState!.validate()) {
                // Save to DB
                await Provider.of<BookEvents>(context, listen: false)
                    .saveEmergencyContact(
                  widget.hostname,
                  int.parse(widget.user.id),
                  _eNameController.text,
                  _ePhoneController.text,
                  _selectedRelationship!,
                );

                Navigator.of(ctx).pop();
                // Minor (16-17) check before refund policy
                _handleMinorCheck(p, type, shirt, finalDietData, finalHealthData);
              }
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _handleMinorCheck(
    int p,
    int type,
    String shirt,
    String finalDietData,
    String finalHealthData,
  ) {
    int? age;
    try {
      if (widget.user.dob.isNotEmpty) {
        final dob = DateTime.parse(widget.user.dob);
        final now = DateTime.now();
        age = now.year - dob.year;
        final hasHadBirthday = (now.month > dob.month) ||
            (now.month == dob.month && now.day >= dob.day);
        if (!hasHadBirthday) age -= 1;
      }
    } catch (_) {
      age = null;
    }

    final isMinor16to17 = age != null && age >= 16 && age <= 17;
    if (!isMinor16to17) {
      _showRefundPolicyDialog(p, type, shirt, finalDietData, finalHealthData);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.family_restroom, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            const Text('Parental/Guardian Presence', textAlign: TextAlign.center),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, color: Colors.blue, size: 24),
              SizedBox(height: 12),
              Text(
                'You are 16-17 years old. Will you be attending with a parent/guardian?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'If not, you must download and bring a signed consent form.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRefundPolicyDialog(p, type, shirt, finalDietData, finalHealthData);
            },
            child: const Text('Yes, with parent'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showConsentFormDialog(p, type, shirt, finalDietData, finalHealthData);
            },
            child: const Text('No, need consent form'),
          ),
        ],
      ),
    );
  }

  void _showConsentFormDialog(
    int p,
    int type,
    String shirt,
    String finalDietData,
    String finalHealthData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.description, size: 48, color: Colors.orange.shade700),
            const SizedBox(height: 12),
            const Text('Consent Form Required', textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You must download, print, and bring a signed parental consent form to participate.',
                        style: TextStyle(fontSize: 13, color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                try {
                  final ByteData data = await rootBundle.load(
                    'assets/PARENTAL_CONSENT_LETTER_FOR_UNDERAGE_VOLUNTEER.pdf',
                  );
                  await downloadBytes(
                    bytes: data.buffer.asUint8List(
                      data.offsetInBytes,
                      data.lengthInBytes,
                    ),
                    fileName: 'parental_consent.pdf',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening consent form: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download & View Consent Form'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After printing and signing, tap "I have the consent form" to continue.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRefundPolicyDialog(p, type, shirt, finalDietData, finalHealthData);
            },
            child: const Text('I have the consent form'),
          ),
        ],
      ),
    );
  }

  void _showRefundPolicyDialog(
    int p,
    int type,
    String shirt,
    String finalDietData,
    String finalHealthData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.policy, size: 48, color: Colors.indigo.shade700),
            const SizedBox(height: 12),
            const Text('Reschedule & Refund Policy', textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please read our policy carefully before proceeding.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPolicySection(
                '31 Days or More Before Slot Start Date:',
                [
                  'Reschedule and refund requests are allowed without any penalty.',
                  'You may choose to move to another available slot or request a full refund.',
                ],
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                '30 Days Before Slot Start Date:',
                [
                  'Reschedule and refund requests are allowed but subject to a penalty fee of RM200 per person.',
                  'The remaining balance will be refunded.',
                ],
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPolicySection(
                '14 Days or Less Before Slot Start Date:',
                [
                  'Reschedule and refund requests are NOT permitted.',
                  'All fees paid will be forfeited.',
                ],
                Colors.red,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _proceed(p, type, shirt, finalDietData, finalHealthData);
            },
            child: const Text('Agree and Proceed'),
          ),
        ],
      ),
    );
  }

  // Helper method for building policy sections with color-coded boxes
  Widget _buildPolicySection(String title, List<String> points, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $point', style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  // --- 2. Health Info Dialog (Step 3) ---
  void _showHealthDialog(int p, int type, String shirt, String finalDietData) {
    _selectedHealth = 'No Health Issue';
    _healthController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  Icon(Icons.medical_services, size: 48, color: Colors.orange.shade700),
                  const SizedBox(height: 12),
                  const Text('Health Information', textAlign: TextAlign.center),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Do you have any health conditions we should be aware of?',
                              style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    RadioListTile<String>(
                      title: const Text('No Health Issue'),
                      value: 'No Health Issue',
                      groupValue: _selectedHealth,
                      onChanged: (value) => setState(() => _selectedHealth = value!),
                    ),

                    RadioListTile<String>(
                      title: const Text('Asthma'),
                      value: 'Asthma',
                      groupValue: _selectedHealth,
                      onChanged: (value) => setState(() => _selectedHealth = value!),
                    ),

                    RadioListTile<String>(
                      title: const Text('Heart Disease'),
                      value: 'Heart Disease',
                      groupValue: _selectedHealth,
                      onChanged: (value) => setState(() => _selectedHealth = value!),
                    ),

                    RadioListTile<String>(
                      title: const Text('Tuberculosis'),
                      value: 'Tuberculosis',
                      groupValue: _selectedHealth,
                      onChanged: (value) => setState(() => _selectedHealth = value!),
                    ),

                    RadioListTile<String>(
                      title: const Text('Other (please specify)'),
                      value: 'Other',
                      groupValue: _selectedHealth,
                      onChanged: (value) => setState(() => _selectedHealth = value!),
                    ),

                    if (_selectedHealth == 'Other') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          controller: _healthController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Please specify condition',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],

                    if (_selectedHealth != 'No Health Issue') ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          "*If you have selected any health condition above, you are required to bring your own prescribed medication and ensure it is sufficient for the entire duration of the program.\nYou are fully responsible for managing your medication and informing the program coordinator of any necessary precautions related to your condition.",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.deepOrange),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    String finalHealthData = _selectedHealth;
                    if (_selectedHealth == 'Other') {
                      if (_healthController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please specify your condition")),
                        );
                        return;
                      }
                      finalHealthData = "Other: ${_healthController.text.trim()}";
                    }
                    
                    Navigator.of(ctx).pop(); 
                    // Go to Emergency Contact Dialog
                    _showEmergencyContactDialog(p, type, shirt, finalDietData, finalHealthData);
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. Diet Restriction Dialog (Step 2) ---
  void _showDietDialog(int p, int type, String shirt) {
    _selectedDiet = 'None';
    _allergyController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 12),
                  const Text('Dietary Restrictions', textAlign: TextAlign.center),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Do you have any dietary requirements?',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    RadioListTile<String>(
                      title: const Text('None'),
                      value: 'None',
                      groupValue: _selectedDiet,
                      onChanged: (value) => setState(() => _selectedDiet = value!),
                    ),

                    RadioListTile<String>(
                      title: const Text('Vegetarian / Vegan'),
                      value: 'Vegetarian/Vegan',
                      groupValue: _selectedDiet,
                      onChanged: (value) => setState(() => _selectedDiet = value!),
                    ),
                    if (_selectedDiet == 'Vegetarian/Vegan')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text(
                          "We will provide the basic cooking ingredients. Participants are required to prepare their own meals. Alternatively, you may bring ready-to-eat food that suits your dietary needs.",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green),
                        ),
                      ),

                    RadioListTile<String>(
                      title: const Text('Allergic'),
                      value: 'Allergic',
                      groupValue: _selectedDiet,
                      onChanged: (value) => setState(() => _selectedDiet = value!),
                    ),

                    if (_selectedDiet == 'Allergic')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _allergyController,
                          decoration: const InputDecoration(
                            labelText: 'Please specify allergy',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    String finalDietData = _selectedDiet;
                    if (_selectedDiet == 'Allergic') {
                      if (_allergyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please specify your allergy")),
                        );
                        return;
                      }
                      finalDietData = "Allergic: ${_allergyController.text.trim()}";
                    }

                    Navigator.of(ctx).pop(); 
                    // Go to Health Dialog
                    _showHealthDialog(p, type, shirt, finalDietData);
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 4. Shirt Size Dialog (Step 1) ---
  void _showshirtDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.checkroom, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            const Text('T-Shirt Size', textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/sizechart.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Size chart not found', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _shirtFormKey,
                child: DropdownButtonFormField<String>(
                  initialValue: shirtsize,
                  decoration: InputDecoration(
                    labelText: 'Select Size',
                    hintText: 'Choose your T-shirt size',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.straighten),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: size.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => shirtsize = value);
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_shirtFormKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                _showDietDialog(1, 1, shirtsize); // Go to Diet
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // --- 5. Booking Type Dialog (Start) ---
  void _showbooktypeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.event_seat, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            const Text(
              'Choose Booking Type',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how you would like to book this event',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBookingTypeCard(
                context: ctx,
                icon: Icons.person,
                title: 'Individual Booking',
                subtitle: 'Book for yourself',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showshirtDialog();
                },
              ),
              const SizedBox(height: 12),
              _buildBookingTypeCard(
                context: ctx,
                icon: Icons.groups,
                title: 'Group Booking',
                subtitle: 'Book for 7 or more people',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showBookDialog();
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 6. Group Booking Dialog ---
  void _showBookDialog() async {
    // Fetch current booked slots to calculate available slots
    final bookedSlots = await Provider.of<Events>(context, listen: false)
        .fetchSlot(widget.hostname, widget.eventid);
    final availableSlots = widget.slotvolunteer - bookedSlots;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.groups, size: 48, color: Colors.purple.shade700),
            const SizedBox(height: 12),
            const Text(
              'Group Booking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: _groupFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Minimum 7 participants required for group booking',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_available, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Available Slots:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$availableSlots',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number of Participants',
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of participants';
                    }
                    final paxNum = int.tryParse(value);
                    if (paxNum == null) {
                      return 'Please enter a valid number';
                    }
                    if (paxNum < 7) {
                      return 'Minimum 7 participants';
                    }
                    if (paxNum > availableSlots) {
                      return 'Exceeds available slots ($availableSlots remaining)';
                    }
                    return null;
                  },
                  onChanged: (val) { 
                    if(val.isNotEmpty) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) pax = parsed;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_groupFormKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                _showGroupShirtDialog();
              }
            }, 
            child: const Text('Next'),
          ),
        ],
      )
    );
  }

  void _showGroupShirtDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.checkroom, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            const Text('T-Shirt Size', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Group Leader',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/sizechart.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Size chart not found', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _groupShirtFormKey,
                child: DropdownButtonFormField<String>(
                  initialValue: shirtsize,
                  decoration: InputDecoration(
                    labelText: 'Select Size',
                    hintText: 'Choose your T-shirt size',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.straighten),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: size.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => shirtsize = value);
                  },
                  validator: (value) => value == null ? 'Please select shirt size' : null,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_groupShirtFormKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                _showDietDialog(pax, 2, shirtsize);
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterWidget() {
    if (_posterLoading) return const Center(child: CircularProgressIndicator());
    if (_currentPosterUrl == null) return const SizedBox(height: 200, child: Center(child: Text('No Poster')));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          _currentPosterUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPosterWidget(),
            const SizedBox(height: 8),
            
            // Date Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: primaryColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Event Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.startdate,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: primaryColor, size: 16),
                      ),
                      Text(
                        widget.enddate,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Booking Status Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: widget.staff == false
                  ? widget.datediff.inDays < 0
                      ? widget.datebook == ''
                          ? FutureBuilder(
                              future: Provider.of<Events>(context, listen: false).checkBooked(
                                  widget.hostname, widget.eventid, int.parse(widget.user.id), 1),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.data == true) {
                                  return _buildStatusCard(
                                    context: context,
                                    icon: Icons.check_circle,
                                    iconColor: Colors.green,
                                    title: 'Already Booked',
                                    message: 'You have booked this event. Please proceed to Booked / Associated Events Tab for further information.',
                                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  );
                                } else {
                                  return FutureBuilder(
                                    future: Provider.of<Events>(context, listen: false).checkBookedMembers(
                                        widget.hostname, widget.eventid, widget.user.email),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.data == true) {
                                        return _buildStatusCard(
                                          context: context,
                                          icon: Icons.check_circle,
                                          iconColor: Colors.green,
                                          title: 'Already Booked',
                                          message: 'You have booked this event. Please proceed to Booked / Associated Events Tab for further information.',
                                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                                        );
                                      } else {
                                        // Now check if event is fully booked
                                        return FutureBuilder(
                                          future: Provider.of<Events>(context, listen: false).fetchSlot(widget.hostname, widget.eventid),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            } else {
                                              if (snapshot.error != null) return Center(child: Text('Error: ${snapshot.error}'));
                                              
                                              final bookedSlots = snapshot.data ?? 0;
                                              final totalSlots = widget.slotvolunteer;
                                              final isFullyBooked = bookedSlots >= totalSlots;
                                              
                                              if (isFullyBooked) {
                                                return _buildStatusCard(
                                                  context: context,
                                                  icon: Icons.event_busy,
                                                  iconColor: Colors.red,
                                                  title: 'Fully Booked',
                                                  message: 'This event is fully booked. Please check other available events.',
                                                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                                                );
                                              } else {
                                                return Card(
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.event_available, color: primaryColor, size: 28),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              'Slots Available',
                                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                color: primaryColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 16),
                                                        SizedBox(
                                                          width: double.infinity,
                                                          child: ElevatedButton.icon(
                                                            onPressed: () => _showbooktypeDialog(),
                                                            icon: const Icon(Icons.bookmark_add),
                                                            label: const Text('BOOK NOW'),
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        );
                                      }
                                    },
                                  );
                                }
                              },
                            )
                            : _buildStatusCard(
                              context: context,
                              icon: Icons.check_circle,
                              iconColor: Colors.green,
                              title: 'Already Booked',
                              message: 'You have booked this program on ${widget.datebook}',
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                            )
                          : _buildStatusCard(
                            context: context,
                          icon: Icons.history,
                          iconColor: Colors.grey,
                          title: 'Event Ended',
                          message: 'This slot has passed',
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
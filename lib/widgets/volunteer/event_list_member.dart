import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/providers/bookevents.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Required for PDF
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // Required for PDF
import 'package:open_file/open_file.dart'; // Required for PDF
import 'package:provider/provider.dart';
import 'package:signature/signature.dart'; // For signature pad

class EventListMember extends StatefulWidget {
  const EventListMember({
    super.key,
    required this.staff,
    required this.user,
    required this.hostname,
    required this.volorres,
  });

  final bool staff;
  final User user;
  final String hostname;
  final int volorres;

  @override
  State<EventListMember> createState() => _EventListMemberState();
}

class _EventListMemberState extends State<EventListMember> {
  final GlobalKey<FormState> _emergencyContactFormKey = GlobalKey();
  final TextEditingController _eNameController = TextEditingController();
  final TextEditingController _ePhoneController = TextEditingController();
  String? _selectedRelationship;
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
  void dispose() {
    _eNameController.dispose();
    _ePhoneController.dispose();
    super.dispose();
  }

  // --- 1. Emergency Contact Dialog ---
  void _showEmergencyContactDialog(int confirmnum, int booktype, String startdate, String enddate) async {
    // Fetch existing contact first
    final existing = await Provider.of<BookEvents>(
      context,
      listen: false,
    ).fetchEmergencyContact(widget.hostname, int.parse(widget.user.id));

    if (existing != null) {
      _eNameController.text = existing['name'];
      _ePhoneController.text = existing['phone'];
      _selectedRelationship = existing['relationship'];
    } else {
      _eNameController.clear();
      _ePhoneController.clear();
      _selectedRelationship = null;
    }

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
            key: _emergencyContactFormKey,
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
                  value: _selectedRelationship,
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
            onPressed: () async {
              if (_emergencyContactFormKey.currentState!.validate()) {
                // Save to DB
                await Provider.of<BookEvents>(
                  context,
                  listen: false,
                ).saveEmergencyContact(
                  widget.hostname,
                  int.parse(widget.user.id),
                  _eNameController.text,
                  _ePhoneController.text,
                  _selectedRelationship!,
                );

                Navigator.of(ctx).pop();
                // Proceed to Age Check Logic
                if (mounted) {
                  _handleMinorCheck(confirmnum, booktype, startdate, enddate);
                }
              }
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  // --- 2. Minor Age Check Logic (Ported from view_event.dart) ---
  void _handleMinorCheck(int confirmnum, int booktype, String startdate, String enddate) {
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
    
    // If NOT minor (18+), proceed directly to Indemnity
    if (!isMinor16to17) {
      _showIndemityDialog(confirmnum, booktype, startdate, enddate);
      return;
    }

    // If Minor (16-17), Show Dialog
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
              _showIndemityDialog(confirmnum, booktype, startdate, enddate);
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
              _showConsentFormDialog(confirmnum, booktype, startdate, enddate);
            },
            child: const Text('No, need consent form'),
          ),
        ],
      ),
    );
  }

  // --- 3. Consent Form Download Dialog (Ported from view_event.dart) ---
  void _showConsentFormDialog(int confirmnum, int booktype, String startdate, String enddate) {
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
                      // Copy PDF from assets to temporary directory
                      final ByteData data = await rootBundle.load(
                        'assets/PARENTAL_CONSENT_LETTER_FOR_UNDERAGE_VOLUNTEER.pdf',
                      );
                      final Directory tempDir = await getTemporaryDirectory();
                      final String filePath = '${tempDir.path}/parental_consent.pdf';
                      final File file = File(filePath);
                      await file.writeAsBytes(
                        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
                      );

                      // Open the PDF file
                      final result = await OpenFile.open(filePath);
                      
                      if (result.type != ResultType.done && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open PDF: ${result.message}')),
                        );
                      }
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
              _showIndemityDialog(confirmnum, booktype, startdate, enddate);
            },
            child: const Text('I have the consent form'),
          ),
        ],
      ),
    );
  }

  // --- Hardcoded Indemnity Clauses (same as IndemnityScreen) ---
  final List<Map<String, dynamic>> _indemnityClauses = [
    {
      "title": "(A) EXPRESS ASSUMPTION OF ALL INHERENT RISKS OF OUTDOOR/WATER ACTIVITIES",
      "content": <TextSpan>[
        const TextSpan(
          text: "There are numerous risks inherent in and associated with participation in outdoor/water activities. By executing this ",
        ),
        const TextSpan(text: "RELEASE", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: ", you are acknowledging that participation in outdoor/water activities is an inherently dangerous activity that involves risks of death and/or serious bodily injury that cannot be prevented or avoided even by the exercise of reasonable care. The following list, though not exhaustive, exemplifies many of the types of risks and potential injuries you could encounter in connection with your participation in water sports:\n\n"
              "❖ changing water flow, tides, currents, wave action, eddies, whirlpools, and vessel wakes;\n"
              "❖ collision with other participants; collision with watercraft, whether owned or operated by the Released, collision with man-made or natural objects;\n"
              "❖ the negligent actions and/or omissions of other participants;\n"
              "❖ your own actions and/or omissions, your level of competency as to the activity, and your own physical and mental conditions;\n"
              "❖ your sense of balance, physical coordination, ability to operate equipment, and ability to swim;\n"
              "❖ wind shear, inclement weather, lightning, variances and extremes of wind, weather and temperature;\n"
              "❖ collision, capsizing, sinking, falling, slipping or other hazards that may result in wetness, injury, exposure to the elements, hypothermia, impact of the body upon the water, injection of water into any body orifices, and/or drowning;\n"
              "❖ the presence of insects, wild animals, as well as dangerous plant life, bacteria, amoebas, and marine life forms;\n"
              "❖ equipment failure, improper use of equipment and/or impacting equipment;\n"
              "❖ heat or sun related injuries or illnesses, including sunburn, sun stroke or dehydration;\n"
              "❖ fatigue, chill, shock and/or dizziness which may increase your reaction time.\n\n"
              "By initialing this section and executing this ",
        ),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " below, you are agreeing that you have reviewed the preceding non-exclusive list of sample inherent risks involved in your participation in these activities, and with full knowledge and understanding, you are voluntarily agreeing to engage and participate in these activities and to ",
        ),
        const TextSpan(
            text: "VOLUNTARILY AND EXPRESSLY ASSUME THE RISK OF SERIOUS BODILY HARM, PERSONAL INJURY, DEATH OR DAMAGE",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " resulting from any and all inherent risks while participating and engaging in (including transit to and from) these outdoor/water activities. By expressly assuming ",
        ),
        const TextSpan(text: "ANY AND ALL INHERENT RISKS", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " involved with these water activities, you are voluntarily relinquishing the ability to seek or collect damages from the Released due to any personal injury, claim, or incident occurring or in any way related to or arising from the inherent risks of your involvement in these water activities.",
        ),
      ]
    },
    {
      "title": "(B) AGREEMENT TO FOLLOW DIRECTIONS",
      "content": <TextSpan>[
        const TextSpan(
          text: "I agree to follow the rules for the Activity provided to me and to follow directions given to me by the leaders of the Activity.",
        ),
      ]
    },
    {
      "title": "(C) INDEMNITY AGREEMENT STATEMENT",
      "content": <TextSpan>[
        const TextSpan(text: "By initialing this section and executing this "),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " below, you are further agreeing to hold harmless and to indemnify the Released against any and all claims, demands, losses, damages, causes of action, judgments, costs, expenses, attorneys' fees, and other liabilities, including those from third parties, arising out of or relating to your participation in any outdoor/water activities and/or presence upon the property on which they are located, even if caused by the active or passive negligence of the Released, but excluding any ",
        ),
        const TextSpan(text: "GROSS NEGLIGENCE OR INTENTIONAL MISCONDUCT", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: ". By agreeing to indemnify the Released for the acts, occurrences, and expenses as contained within this subsection you are knowingly and voluntarily agreeing that you may be required to reimburse or provide the cost of a legal defence or representation for the Released for any expenses or actions it has to take arising out of your participation in these water activities.",
        ),
      ]
    },
    {
      "title": "(D) WAIVER AND RELEASE OF LIABILITY",
      "content": <TextSpan>[
        const TextSpan(text: "By initialing this section and signing this "),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: " below, "),
        const TextSpan(
            text: "YOU ARE AGREEING TO KNOWINGLY, VOLUNTARILY, AND UNEQUIVICALLY WAIVE ANY AND ALL CLAIMS, INCLUDING ACTIVE OR PASSIVE NEGLIGENCE BUT EXCLUDING GROSS NEGLIGENCE OR INTENTIONAL MISCONDUCT",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: ", against the Released arising out of any act, omission, or condition existing prior to the signing of the agreement, and extending to any act, omission, or condition in any way connected with your participation in (including transit to and from) these outdoor/water activities occurring at any point in the future. ",
        ),
        const TextSpan(
            text: "THIS WAIVER AND RELEASE OF LIABILITY IS EXPRESSLY PROVIDED TO EXCULPATE THE RELEASED FROM THOSE LIABILITIES WHICH ARE SEPARATE FROM AND IN ADDITION TO THE POTENTIAL LIABILITIES CREATED BY THE RISKS INHERENT IN WATER ACTIVITIES PARTICIPATION.",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " Furthermore, by initialling and signing this waiver below, you are binding your spouse, heirs, assigns, and any similarly situated personal or legal representative to the waiver's terms.",
        ),
      ]
    },
    {
      "title": "(E) DECLARATION OF COMPETENCY AND INTENT TO BE BOUND",
      "content": <TextSpan>[
        const TextSpan(text: "By initialing this section and signing this "),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " below, you are signifying that you have read first, then initialed, all sections contained within this agreement. You are further signifying that you are voluntarily agreeing to execute this ",
        ),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(
          text: " and release, and that you understand the legal implications and consequences of doing so. If there are any aspects of this agreement with which you do not have a full and complete understanding, you are encouraged to ask or inquire with the Released ",
        ),
        const TextSpan(text: "BEFORE", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: " initialing this section or signing this "),
        const TextSpan(text: "WAIVER", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: "."),
      ]
    },
  ];

  // Helper widget for indemnity section with checkbox
  Widget _buildIndemnitySection({
    required String title,
    required List<TextSpan> contentSpans,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(158, 158, 158, 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.0,
                height: 1.4,
                color: Colors.black,
              ),
              children: contentSpans,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text(
              "I have read and agree",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            value: isChecked,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  // --- 4. Indemnity Dialog (Matching IndemnityScreen style with hardcoded clauses) ---
  void _showIndemityDialog(int confirmnum, int booktype, String startdate, String enddate) {
    // Track checkbox state for each indemnity section
    List<bool> sectionChecked = [false, false, false, false, false];
    
    // Signature controller
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
    
    // Flag to track if listener has been added
    bool listenerAdded = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Add listener only once to update UI when signature changes
          if (!listenerAdded) {
            signatureController.addListener(() {
              setDialogState(() {});
            });
            listenerAdded = true;
          }
          
          // Helper to check if all sections are checked and signature is present
          bool allSectionsChecked = !sectionChecked.contains(false);
          bool isSigned = signatureController.isNotEmpty;
          bool isFormValid = allSectionsChecked && isSigned;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              children: [
                Icon(Icons.gavel, size: 48, color: Colors.indigo.shade700),
                const SizedBox(height: 12),
                const Text('Indemnity Form', textAlign: TextAlign.center),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER BOX ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "OUTDOOR/WATER ACTIVITIES PARTICIPATION\nUNCONDITIONAL GENERAL RELEASE FROM LIABILITY",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.justify,
                            text: const TextSpan(
                              style: TextStyle(fontSize: 11, height: 1.4, color: Colors.black),
                              children: <TextSpan>[
                                TextSpan(text: "Please read the following agreement carefully "),
                                TextSpan(
                                    text: "BEFORE DECIDING TO PARTICIPATE.",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: " By signing this document and initialing the required sections, "),
                                TextSpan(
                                    text: "YOU ARE EXPRESSLY AGREEING TO HAVE KNOWLINGLY, FULLY AND TOTALLY RELEASED",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: " the "),
                                TextSpan(
                                    text: "UNIVERSITI MALAYSIA TERENGGANU",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: ", His Agents and Employees (hereinafter “the Released”) "),
                                TextSpan(
                                    text: "FROM ANY AND ALL CLAIMS, INCLUDING ACTIVE OR PASSIVE NEGLIGENCE BUT EXCLUDING GROSS NEGLIGENCE AND/OR INTENTIONAL MISCONDUCT",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: ", arising out of any act, omission, or condition existing prior to the signing of the agreement."),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // --- INDEMNITY SECTIONS (A-E) ---
                    ..._indemnityClauses.asMap().entries.map((entry) {
                      final i = entry.key;
                      final clause = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildIndemnitySection(
                          title: clause['title'] as String,
                          contentSpans: clause['content'] as List<TextSpan>,
                          isChecked: sectionChecked[i],
                          onChanged: (val) {
                            setDialogState(() {
                              sectionChecked[i] = val ?? false;
                            });
                          },
                        ),
                      );
                    }).toList(),
                    
                    // --- SECTION (F) UNCONDITIONAL GENERAL RELEASE ---
                    const Divider(thickness: 2),
                    const SizedBox(height: 16),
                    const Text(
                      "(F) UNCONDITIONAL GENERAL RELEASE FROM LIABILITY",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your signature below reflects your express assent to be bound to the terms of this agreement.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- SIGNATURE PAD ---
                    const Text(
                      "SIGNATURE:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Signature(
                          controller: signatureController,
                          height: 150,
                          backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                        ),
                      ),
                    ),
                    // Clear Signature Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          signatureController.clear();
                          setDialogState(() {}); // Update button state
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text("Clear Signature"),
                      ),
                    ),
                    
                    // --- Validation Message ---
                    if (!allSectionsChecked || !isSigned)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                !allSectionsChecked && !isSigned
                                    ? 'Please check all sections and provide your signature.'
                                    : !allSectionsChecked
                                        ? 'Please check all sections (A-E) to proceed.'
                                        : 'Please provide your signature to proceed.',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
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
                onPressed: () {
                  signatureController.dispose();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Decline'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid ? Colors.green : Colors.grey.shade300,
                  foregroundColor: isFormValid ? Colors.white : Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('I AGREE'),
                onPressed: isFormValid
                    ? () async {
                        try {
                          // Export signature to PNG bytes
                          final Uint8List? signature = await signatureController.toPngBytes();
                          
                          await Provider.of<Indemnitites>(
                            context,
                            listen: false,
                          ).addIndemnitiestoBooking(
                            widget.hostname,
                            int.parse(widget.user.id),
                            'Agreed',
                            confirmnum,
                            signature,
                          );

                          signatureController.dispose();
                          Navigator.of(ctx).pop();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registration Completed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            setState(() {}); // Refresh UI
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _checkMemberStatus(
    int eventid,
    int confirmnum,
    int booktype,
  ) async {
    try {
      final isRegistered = await Provider.of<Indemnitites>(
        context,
        listen: false,
      ).checkUserRegistration(widget.hostname, widget.user.email);

      final indemCompleted = await Provider.of<Indemnitites>(
        context,
        listen: false,
      ).checkIndemnityStatus(widget.hostname, widget.user.email, confirmnum);

      return {
        'isRegistered': isRegistered,
        'indemCompleted': indemCompleted,
        'booktype': booktype,
      };
    } catch (e) {
      return {'isRegistered': false, 'indemCompleted': false};
    }
  }

  // Helper widget for "No Member Events" state
  Widget _buildNoMemberEventsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "No Member Events Yet",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You haven't been added to any events yet.",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    
    return FutureBuilder(
      future: Provider.of<Events>(
        context,
        listen: false,
      ).fetchMemberEvent(widget.hostname, widget.user.email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            // Use styled "No Member Events" state instead of error text
            return _buildNoMemberEventsState(context);
          } else {
            return Consumer<Events>(
              builder: (ctx, eventData, child) {
                if (eventData.memberevents.isEmpty) {
                  return _buildNoMemberEventsState(context);
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventData.memberevents.length,
                  itemBuilder: (_, i) {
                    final event = eventData.memberevents[i];
                    final int confirmnum = event['confirmnum'] ?? 0;
                    final int eventid = int.parse(event['id']);
                    final int booktype = event['booktype'] ?? 0;
                    final String startdate = f.format(DateTime.parse(event['startdate']));
                    final String enddate = f.format(DateTime.parse(event['enddate']));

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Card(
                        elevation: 2,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(event['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$startdate - $enddate'),
                            ),
                            
                            // Status Check Logic
                            FutureBuilder<Map<String, dynamic>>(
                              future: _checkMemberStatus(eventid, confirmnum, booktype),
                              builder: (context, statusSnapshot) {
                                if (statusSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }

                                final status = statusSnapshot.data ?? {};
                                final bool indemCompleted = status['indemCompleted'] ?? false;

                                if (indemCompleted) {
                                  // COMPLETED CARD
                                  return Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'All Set! Registration completed.',
                                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // ACTION REQUIRED CARD
                                  return Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      border: Border.all(color: Colors.orange),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Action Required',
                                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Complete Registration'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                            // Call Emergency Contact -> Minor Check -> Indemnity
                                            onPressed: () => _showEmergencyContactDialog(
                                              confirmnum, 
                                              booktype,
                                              startdate,
                                              enddate
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
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
        }
      },
    );
  }
}
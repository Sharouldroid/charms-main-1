import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/screens/checkout_screen.dart';
import 'package:charms/widgets/optional/add_on.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:charms/utils/responsive_helper.dart';

class IndemnityScreen extends StatefulWidget {
  const IndemnityScreen({
    super.key,
    required this.eventid,
    required this.title,
    required this.price,
    required this.startdate,
    required this.enddate,
    required this.type,
    required this.hostname,
    required this.confirmnum,
    required this.user,
    this.edit = false,
    required this.answers,
    this.pax = 1,
    this.shirtsize = '',
    required this.staff,
    required this.volres,
    required this.diet,
    required this.health,
  });

  final int eventid;
  final String title;
  final double price;
  final String startdate;
  final String enddate;
  final int type;
  final String hostname;
  final int confirmnum;
  final User user;
  final bool edit;
  final String answers;
  final int pax;
  final String shirtsize;
  final bool staff;
  final int volres;
  final String diet;
  final String health;

  @override
  State<IndemnityScreen> createState() => _IndemnityScreenState();
}

class _IndemnityScreenState extends State<IndemnityScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  // Track the state of the 5 checkboxes (A, B, C, D, E)
  late List<bool> _sectionChecked;

  // --- HARDCODED INDEMNITY TEXT ---
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

  @override
  void initState() {
    super.initState();
    // Initialize all checkboxes to false
    _sectionChecked = List.generate(_indemnityClauses.length, (index) => false);
    
    // Listen to signature changes to update button state
    _signatureController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  // Helper to check if form is valid
  bool get _isFormValid {
    bool allChecked = !_sectionChecked.contains(false);
    bool isSigned = _signatureController.isNotEmpty;
    return allChecked && isSigned;
  }

  void _showBookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Add-ons Available',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Would you like to purchase some optional add-ons to enhance your experience?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => AddOn(
                  hostname: widget.hostname,
                  confirmnum: widget.confirmnum,
                  pax: widget.pax,
                  ischecked: 'Agreed',
                  user: widget.user,
                  eventid: widget.eventid,
                  booktype: widget.type,
                  shirtsize: widget.shirtsize,
                  staff: widget.staff,
                  volres: widget.volres,
                  isRSS: 0,
                  startdate: widget.startdate,
                  enddate: widget.enddate,
                  needboat: 0,
                ),
              ),
            ),
            child: const Text('VIEW ADD-ONS'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => CheckoutScreen(
                  confirmnum: widget.confirmnum,
                  hostname: widget.hostname,
                  pax: widget.pax,
                  ischecked: 'Agreed',
                  user: widget.user,
                  eventid: widget.eventid,
                  booktype: widget.type,
                  shirtsize: widget.shirtsize,
                  staff: widget.staff,
                  volres: widget.volres,
                ),
              ),
            ),
            child: const Text('PROCEED DIRECTLY'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;

    // 1. Export Signature to PNG Bytes
    final Uint8List? signature = await _signatureController.toPngBytes();

    if (signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error capturing signature")),
      );
      return;
    }

    // 2. Add Item to Cart
    Provider.of<BookingCartOut>(context, listen: false).addItem(
      '${widget.eventid}-${widget.user.id}',
      widget.title,
      widget.price,
      widget.confirmnum,
      int.parse(widget.user.id),
      widget.pax,
      widget.type,
      'Agreed',
      widget.shirtsize,
      widget.diet,
      widget.health,
      signature: signature,
    );

    _showBookDialog();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Indemnity Form'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // --- Participant Details Card ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participant Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Name',
                      '${widget.user.firstname} ${widget.user.lastname}',
                    ),
                    _buildDetailRow('IC/Passport', widget.user.idnum),
                    _buildDetailRow('Email', widget.user.email),
                    _buildDetailRow('Diet', widget.diet),
                    _buildDetailRow('Health', widget.health),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Header Box ---
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: "Please read the following agreement carefully "),
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
                            text: ", arising out of any act, omission, or condition existing prior to the signing of the agreement, and extending to include any act, omission, or condition in any way connected with your participation in (including transit to and from) these outdoor/water activities, occurring at any point in the future from the activities in which you are about to engage."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Hardcoded Indemnity Sections (A-E) ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _indemnityClauses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (_, i) {
                return _buildIndemnitySection(
                  title: _indemnityClauses[i]['title'] as String,
                  contentSpans: _indemnityClauses[i]['content'] as List<TextSpan>,
                  isChecked: _sectionChecked[i],
                  onChanged: (val) {
                    setState(() {
                      _sectionChecked[i] = val ?? false;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // --- (F) UNCONDITIONAL GENERAL RELEASE (Signature Only) ---
            const Text(
              "(F) UNCONDITIONAL GENERAL RELEASE FROM LIABILITY",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your signature below reflects your express assent to be bound to the terms of this agreement.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Signature Pad
            const Text("SIGNATURE:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: const Color.fromARGB(255, 245, 245, 245),
              ),
            ),

            // Clear Signature
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _signatureController.clear();
                  setState(() {}); // Update button state
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text("Clear Signature"),
              ),
            ),

            const SizedBox(height: 32),

            // --- Action Button ---
            SizedBox(
              width: double.infinity,
              child: Consumer2<Indemnitites, StripeService>(
                builder: (context, providerA, providerB, child) {
                  return ElevatedButton.icon(
                    // Disable button if form is invalid
                    onPressed: _isFormValid ? () => _submit() : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'AGREE & PROCEED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13.0,
                height: 1.4,
                color: Colors.black,
              ),
              children: contentSpans,
            ),
          ),
          const SizedBox(height: 12),
          // Checkbox for agreement
          CheckboxListTile(
            title: const Text(
              "I have read and agree",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
}
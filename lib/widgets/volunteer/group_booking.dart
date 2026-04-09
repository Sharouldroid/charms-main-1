import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/user.dart';
import 'package:charms/screens/indemnity_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupBooking extends StatefulWidget {
  const GroupBooking({
    super.key,
    required this.pax,
    required this.user,
    required this.eventid,
    required this.title,
    required this.price,
    required this.confirmnum,
    required this.startdate,
    required this.enddate,
    required this.hostname,
    required this.booktype,
    required this.shirtsize, // Passed from ViewEvent
    required this.staff,
    required this.diet,
    required this.health,
  });

  final int pax;
  final User user;
  final int eventid;
  final String title;
  final double price;
  final int confirmnum;
  final String startdate;
  final String enddate;
  final String hostname;
  final int booktype;
  final String shirtsize; // Leader's Shirt Size
  final bool staff;
  final String diet;
  final String health;

  @override
  State<GroupBooking> createState() => _GroupBookingState();
}

class _GroupBookingState extends State<GroupBooking> {
  // Members State (For the other (pax-1) people)
  List<Map<String, dynamic>>? _memberName;
  List<Map<String, dynamic>>? _memberIdnum;
  List<Map<String, dynamic>>? _memberEmail;
  List<Map<String, dynamic>>? _memberSize;
  List<Map<String, dynamic>>? _memberDiet;
  List<Map<String, dynamic>>? _memberDietRemark;
  List<Map<String, dynamic>>? _memberHealth;
  List<Map<String, dynamic>>? _memberHealthRemark;

  List<String> size = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final List<String> _dietOptions = ['None', 'Vegetarian/Vegan', 'Allergic'];
  final List<String> _healthOptions = ['No Health Issue', 'Asthma', 'Heart Disease', 'Tuberculosis', 'Other'];

  @override
  void initState() {
    super.initState();
    _memberName = [];
    _memberIdnum = [];
    _memberEmail = [];
    _memberSize = [];
    _memberDiet = [];
    _memberDietRemark = [];
    _memberHealth = [];
    _memberHealthRemark = [];
  }

  final GlobalKey<FormState> _formKey = GlobalKey();

  // --- SAVE HELPERS ---
  void _saveField(List<Map<String, dynamic>>? list, int key, String value) {
    int foundkey = -1;
    for (var map in list!) {
      if (map.containsKey('id') && map['id'] == key) {
        foundkey = key;
        break;
      }
    }
    if (foundkey != -1) {
      list.removeWhere((map) => map['id'] == foundkey);
    }
    list.add({'id': key, 'value': value});
  }

  _memberNameSave(int k, String v) => _saveField(_memberName, k, v);
  _memberIdnumSave(int k, String v) => _saveField(_memberIdnum, k, v);
  _memberEmailSave(int k, String v) => _saveField(_memberEmail, k, v);
  _memberSizeSave(int k, String v) => _saveField(_memberSize, k, v);
  _memberDietSave(int k, String v) => _saveField(_memberDiet, k, v);
  _memberDietRemarkSave(int k, String v) => _saveField(_memberDietRemark, k, v);
  _memberHealthSave(int k, String v) => _saveField(_memberHealth, k, v);
  _memberHealthRemarkSave(int k, String v) => _saveField(_memberHealthRemark, k, v);

  String _getValue(List<Map<String, dynamic>>? list, int key, String defaultVal) {
    try {
      return list!.firstWhere((m) => m['id'] == key)['value'];
    } catch (e) {
      return defaultVal;
    }
  }

  // Helper method for leader info rows
  Widget _buildLeaderInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for section headers
  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper method for input decoration
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Color? iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: iconColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _book(int pax) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {});
    
    // Save Members Only (Leader is handled separately)
    for (var i = 0; i < pax; i++) {
      String dietType = _getValue(_memberDiet, i, 'None');
      String dietRemark = _getValue(_memberDietRemark, i, '');
      String finalDiet = dietType == 'Allergic' ? "Allergic: $dietRemark" : dietType;

      String healthType = _getValue(_memberHealth, i, 'No Health Issue');
      String healthRemark = _getValue(_memberHealthRemark, i, '');
      String finalHealth = healthType == 'Other' ? "Other: $healthRemark" : healthType;

      Provider.of<GroupMembersOut>(context, listen: false).addItem(
        '${_memberIdnum![i]['value']} - ${_memberName![i]['value']}',
        _memberName![i]['value'],
        _memberIdnum![i]['value'],
        _memberEmail![i]['value'],
        widget.eventid,
        widget.confirmnum,
        _memberSize![i]['value'],
        finalDiet,
        finalHealth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // --- LEADER CARD (Read-Only Info) ---
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.booktype == 2
                                ? 'Group Leader Information'
                                : 'Parent/Guardian Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLeaderInfoRow(Icons.badge, 'Name', '${widget.user.firstname} ${widget.user.lastname}'),
                    _buildLeaderInfoRow(Icons.credit_card, 'IC / Passport', widget.user.idnum),
                    _buildLeaderInfoRow(Icons.email, 'Email', widget.user.email),
                    _buildLeaderInfoRow(Icons.checkroom, 'T-Shirt Size', widget.shirtsize),
                    _buildLeaderInfoRow(Icons.restaurant, 'Diet', widget.diet),
                    _buildLeaderInfoRow(Icons.medical_services, 'Health', widget.health),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please input details for the other ${widget.pax - 1} member(s) below.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- MEMBER INPUT CARDS ---
            for (var i = 0; i < widget.pax - 1; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade400, Colors.purple.shade600],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.booktype == 2
                                  ? 'Volunteer ${i + 2}'
                                  : 'Team Member ${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Personal Information Section
                      _buildSectionHeader(Icons.person, 'Personal Information', Colors.blue),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          label: 'Full Name',
                          hint: 'Enter full name',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (val) => val!.trim().isEmpty ? 'Required' : null,
                        onSaved: (val) => _memberNameSave(i, val!),
                      ),
                      const SizedBox(height: 14),
                      
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          label: 'IC Number / Passport',
                          hint: 'Enter IC or passport number',
                          icon: Icons.credit_card,
                        ),
                        validator: (val) => val!.trim().isEmpty ? 'Required' : null,
                        onSaved: (val) => _memberIdnumSave(i, val!),
                      ),
                      const SizedBox(height: 14),
                      
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          label: 'Email Address',
                          hint: 'Enter email address',
                          icon: Icons.email_outlined,
                        ),
                        validator: (val) => val!.trim().isEmpty || !val.contains('@') ? 'Invalid Email' : null,
                        onSaved: (val) => _memberEmailSave(i, val!),
                      ),
                      const SizedBox(height: 14),
                      
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration(
                          label: 'T-Shirt Size',
                          hint: 'Select size',
                          icon: Icons.checkroom,
                        ),
                        items: size.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() => _memberSizeSave(i, v!)),
                        validator: (v) => v == null ? 'Required' : null,
                        onSaved: (v) => _memberSizeSave(i, v!),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader(Icons.restaurant_menu, 'Dietary Information', Colors.green),
                      const SizedBox(height: 12),
                      
                      DropdownButtonFormField<String>(
                        initialValue: 'None',
                        decoration: _buildInputDecoration(
                          label: 'Diet Restriction',
                          hint: 'Select option',
                          icon: Icons.no_food,
                        ),
                        items: _dietOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) {
                          setState(() { _memberDietSave(i, v!); });
                        },
                        onSaved: (v) => _memberDietSave(i, v!),
                      ),
                      
                      Builder(builder: (context) {
                        String currentDiet = _getValue(_memberDiet, i, 'None');
                        if (currentDiet == 'Allergic') {
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: TextFormField(
                              decoration: _buildInputDecoration(
                                label: 'Specify Allergy',
                                hint: 'What are you allergic to?',
                                icon: Icons.warning_amber,
                                iconColor: Colors.red,
                              ),
                              validator: (val) => val!.isEmpty ? 'Please specify allergy' : null,
                              onSaved: (val) => _memberDietRemarkSave(i, val!),
                            ),
                          );
                        }
                        if (currentDiet == 'Vegetarian/Vegan') {
                           return Container(
                             margin: const EdgeInsets.only(top: 12),
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.green.shade50,
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: Colors.green.shade200),
                             ),
                             child: Row(
                               children: const [
                                 Icon(Icons.info_outline, color: Colors.green, size: 18),
                                 SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     'Basic ingredients provided. Prepare your own meals or bring ready-to-eat food.',
                                     style: TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                                   ),
                                 ),
                               ],
                             ),
                           );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 24),
                      _buildSectionHeader(Icons.medical_services, 'Health Information', Colors.orange),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: 'No Health Issue',
                        decoration: _buildInputDecoration(
                          label: 'Health Condition',
                          hint: 'Select option',
                          icon: Icons.health_and_safety,
                        ),
                        items: _healthOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) {
                          setState(() { _memberHealthSave(i, v!); });
                        },
                        onSaved: (v) => _memberHealthSave(i, v!),
                      ),

                      Builder(builder: (context) {
                        String currentHealth = _getValue(_memberHealth, i, 'No Health Issue');
                        if (currentHealth == 'Other') {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: TextFormField(
                                  decoration: _buildInputDecoration(
                                    label: 'Specify Condition',
                                    hint: 'Describe the health condition',
                                    icon: Icons.medical_information,
                                    iconColor: Colors.orange,
                                  ),
                                  validator: (val) => val!.isEmpty ? 'Please specify condition' : null,
                                  onSaved: (val) => _memberHealthRemarkSave(i, val!),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Text(
                                  '*If you have selected any health condition above, you are required to bring your own prescribed medication and ensure it is sufficient for the entire duration of the program.\nYou are fully responsible for managing your medication and informing the program coordinator of any necessary precautions related to your condition.',
                                  style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          );
                        }
                        if (currentHealth != 'No Health Issue') {
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text(
                              '*If you have selected any health condition above, you are required to bring your own prescribed medication and ensure it is sufficient for the entire duration of the program.\nYou are fully responsible for managing your medication and informing the program coordinator of any necessary precautions related to your condition.',
                              style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.justify,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),

            // --- PROCEED BUTTON ---
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  // 1. Process Members (Leader skipped here)
                  _book(widget.booktype == 2 ? widget.pax : widget.pax - 1);

                  // 2. Navigate & Pass Leader's Info (from Widget params)
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => IndemnityScreen(
                      eventid: widget.eventid,
                      title: widget.title,
                      price: widget.price,
                      startdate: widget.startdate,
                      enddate: widget.enddate,
                      type: widget.booktype,
                      hostname: widget.hostname,
                      confirmnum: widget.confirmnum,
                      user: widget.user,
                      answers: '',
                      pax: widget.pax,
                      shirtsize: widget.shirtsize,
                      staff: widget.staff,
                      volres: 1,
                      diet: widget.diet,     // Leader's Diet
                      health: widget.health, // Leader's Health
                    )));
                },
                icon: const Icon(Icons.arrow_forward, size: 22),
                label: const Text(
                  'Proceed to Indemnity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
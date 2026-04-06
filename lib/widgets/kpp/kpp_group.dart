// import 'package:charms/models/groupmembers.dart';
// import 'package:charms/models/user.dart';
// import 'package:charms/screens/indemnity_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class KPPGroup extends StatefulWidget {
//   const KPPGroup({
//     super.key,
//     required this.pax,
//     required this.user,
//     required this.title,
//     required this.price,
//     required this.confirmnum,
//     required this.startdate,
//     required this.enddate,
//     required this.hostname,
//   });

//   final int pax;
//   final User user;
//   final String title;
//   final int price;
//   final int confirmnum;
//   final String startdate;
//   final String enddate;
//   final String hostname;

//   @override
//   State<KPPGroup> createState() => _KPPGroupState();
// }

// class _KPPGroupState extends State<KPPGroup> {
//   List<Map<String, dynamic>>? _memberName;
//   List<Map<String, dynamic>>? _memberIdnum;
//   List<Map<String, dynamic>>? _memberEmail;

//   @override
//   void initState() {
//     super.initState();
//     _memberName = [];
//     _memberIdnum = [];
//     _memberEmail = [];
//   }

//   final GlobalKey<FormState> _formKey = GlobalKey();
//   _memberEmailSave(int key, String value) {
//     int foundkey = -1;
//     for (var map in _memberEmail!) {
//       if (map.containsKey('id')) {
//         foundkey = key;
//         break;
//       }
//     }

//     if (-1 != foundkey) {
//       _memberEmail!.removeWhere((map) {
//         return map['id'] == foundkey;
//       });
//     }

//     Map<String, dynamic> json = {'id': key, 'value': value};
//     _memberEmail!.add(json);
//   }

//   _memberIdnumSave(int key, String value) {
//     int foundkey = -1;
//     for (var map in _memberIdnum!) {
//       if (map.containsKey('id')) {
//         foundkey = key;
//         break;
//       }
//     }

//     if (-1 != foundkey) {
//       _memberIdnum!.removeWhere((map) {
//         return map['id'] == foundkey;
//       });
//     }

//     Map<String, dynamic> json = {'id': key, 'value': value};
//     _memberIdnum!.add(json);
//   }

//   _memberNameSave(int key, String value) {
//     int foundkey = -1;
//     for (var map in _memberName!) {
//       if (map.containsKey('id')) {
//         foundkey = key;
//         break;
//       }
//     }

//     if (-1 != foundkey) {
//       _memberName!.removeWhere((map) {
//         return map['id'] == foundkey;
//       });
//     }

//     Map<String, dynamic> json = {'id': key, 'value': value};
//     _memberName!.add(json);
//   }

//   Future<void> _book(int pax) async {
//     if (!_formKey.currentState!.validate()) {
//       // Invalid!
//       return;
//     }
//     _formKey.currentState!.save();

//     setState(() {});
//     for (var i = 0; i < pax; i++) {
//       // Provider.of<GroupMembersOut>(context, listen: false).addItem(
//       //     '${_memberIdnum![i]['value']} - ${_memberName![i]['value']}',
//       //     _memberName![i]['value'],
//       //     _memberIdnum![i]['value'],
//       //     _memberEmail![i]['value'],
//       //     widget.eventid,
//       //     widget.confirmnum,
//       //     '');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             Card(
//               margin: const EdgeInsets.all(10),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   children: [
//                     Text(widget.booktype == 2
//                         ? 'You are the person in charge of this group booking.'
//                         : 'Responsible parent details'),
//                     const SizedBox(height: 12),
//                     Text(
//                         'Name: ${widget.user.firstname} ${widget.user.lastname}'),
//                     Text('IC / Passport: ${widget.user.idnum}'),
//                     Text('Email: ${widget.user.email}'),
//                     const SizedBox(height: 12),
//                     Text(
//                         'As the person in charge of the booking, your information has been stored. Please input the information of the other ${widget.pax - 1} members of your booking'),
//                   ],
//                 ),
//               ),
//             ),
//             for (var i = 0; i < widget.pax - 1; i++)
//               Card(
//                 margin: const EdgeInsets.all(10),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     children: [
//                       Text(widget.booktype == 2
//                           ? 'Volunteer ${i + 2}'
//                           : widget.booktype == 3
//                               ? 'Child ${i + 1}'
//                               : 'Team Member ${i + 1}'),
//                       TextFormField(
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(labelText: 'Name'),
//                         validator: (value) {
//                           if (value!.trim().isEmpty) {
//                             return 'Please provide name';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) {
//                           _memberNameSave(i, value!);
//                         },
//                       ),
//                       TextFormField(
//                         textInputAction: TextInputAction.next,
//                         decoration: const InputDecoration(
//                             labelText: 'IC Number / Passport'),
//                         validator: (value) {
//                           if (value!.trim().isEmpty) {
//                             return 'Please provide IC / Passport number';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) {
//                           _memberIdnumSave(i, value!);
//                           // print(value);
//                         },
//                       ),
//                       TextFormField(
//                         textInputAction: TextInputAction.done,
//                         decoration: const InputDecoration(labelText: 'Email'),
//                         validator: (value) {
//                           if (value!.trim().isEmpty || !value.contains('@')) {
//                             return 'Please provide a valid email';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) {
//                           _memberEmailSave(i, value!);
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             // this elevated btn will create a new booking in db and directs user to indemnity
//             ElevatedButton.icon(
//               onPressed: () {
//                 // 26 Nov 2024 commented for modifications
//                 _book(widget.booktype == 2 ? widget.pax : widget.pax - 1);

//                 Navigator.of(context).push(MaterialPageRoute(
//                     builder: (ctx) => IndemnityScreen(
//                           eventid: widget.eventid,
//                           title: widget.title,
//                           price: widget.price,
//                           startdate: widget.startdate,
//                           enddate: widget.enddate,
//                           type: widget
//                               .booktype, // 1 & 2 =individual, group 3 = individual w child
//                           hostname: widget.hostname,
//                           confirmnum: widget.confirmnum,
//                           user: widget.user,
//                           answers: '',
//                           pax: widget.pax,
//                           staff: widget.staff,
//                           volres: 2,
//                         )));
//               },
//               icon: const Icon(Icons.book),
//               label: const Text('Proceed to Indemnity'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

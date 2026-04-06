class BookGroup {
  final int id;
  int userid;
  final String name;
  int eventId;
  final String idnum;
  final String email;
  final int confirmnum;
  final String shirtsize;

  BookGroup({
    required this.id,
    this.userid = 0,
    required this.name,
    this.eventId = 0,
    required this.idnum,
    required this.email,
    required this.confirmnum,
    this.shirtsize = '',
  });
}

// class GroupBookingModel with ChangeNotifier {
//   List<String> name;
//   List<String> email;
//   List<String> idnum;
//   int confirmnum;

//   GroupBookingModel({
//     required this.name,
//     required this.email,
//     required this.idnum,
//     required this.confirmnum,
//   });

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> bookingdata = <String, dynamic>{};

//     bookingdata['name'] = name;
//     bookingdata['email'] = email;
//     bookingdata['idnum'] = idnum;
//     bookingdata['confirmnum'] = confirmnum;

//     return bookingdata;
//   }
// }

// class GroupBookingModel with ChangeNotifier {
//   final Map<String, BookGroup> _groupMember = {};

//   Map<String, BookGroup> get groupMember {
//     return {..._groupMember};
//   }

//   void addMember(
//     confirmationno,
//     int userid,
//     String name,
//     int eventid,
//     String idnum,
//     String email,
//   ) {
//     if (!_groupMember.containsKey(confirmationno)) {
//       _groupMember.putIfAbsent(
//           confirmationno,
//           () => BookGroup(
//                 id: eventid,
//                 userid: userid,
//                 name: name,
//                 eventId: eventid,
//                 idnum: idnum,
//                 email: email,
//                 confirmnum: confirmationno,
//               ));
//     } else {
//       _groupMember.update(
//           confirmationno,
//           (existingmember) => BookGroup(
//                 id: existingmember.id,
//                 userid: existingmember.userid,
//                 name: existingmember.name,
//                 eventId: existingmember.eventId,
//                 idnum: existingmember.idnum,
//                 email: existingmember.email,
//                 confirmnum: existingmember.confirmnum,
//               ));
//     }
//     notifyListeners();
//   }
// }

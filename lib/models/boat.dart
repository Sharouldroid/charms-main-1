class Boat {
  final int id;
  final String name;
  final int companyId;
  final int capacity;
  final int status;

  Boat({
    required this.id,
    required this.name,
    required this.companyId,
    required this.capacity,
    this.status = 0,
  });
}

class BoatCompany {
  final int id;
  final String companyname;
  final String phone;
  final String email;
  final String address;
  final int ownerid;
  final String registrationno;
  final int boatcount;
  int status;

  BoatCompany({
    required this.id,
    required this.companyname,
    required this.phone,
    required this.email,
    required this.address,
    required this.ownerid,
    required this.registrationno,
    required this.boatcount,
    this.status = 2,
  });
}

class BoatDriver {
  final int id;
  final String fullname;
  final String ic;
  final String address;
  final String phone;
  final String licenseexpiry;
  final int companyid;

  BoatDriver({
    required this.id,
    required this.fullname,
    required this.ic,
    required this.address,
    required this.phone,
    this.licenseexpiry = '',
    required this.companyid,
  });
}

// class BoatTrip {
//   final int id;
//   // final int eventid;
//   final String event;
//   // final int companyid;
//   final String company;
//   final String boat;
//   // final DateTime estimateddeparture;
//   // final DateTime departedat;
//   final String assignedby;

//   BoatTrip({
//     required this.id,
//     // required this.eventid,
//     required this.event,
//     // required this.companyid,
//     required this.company,
//     this.boat = '',
//     // this.estimateddeparture = DateTime.now(),
//     required this.assignedby,
//   });
// }

// import './usertype.dart';

// enum Usertype {
//   1)superID,
//   2)volunteer,
//   3)researcher,
//   4)boatowner,
//   5)boatdriver,
//   6)staffadmin,
//   7)staff
//   8)manager,
//   9)officer
//  10)trainee,
// }

class User {
  final String id;  // Keep as String for auth compatibility
  final String firstname;
  final String lastname;
  final String phone;
  final String dob;
  final String address1;
  final String? address2;
  final String city;
  final int postcode;
  final String state;
  final String country;
  final String occupation;
  final String username;
  final String email;
  final String password;  // Keep for registration
  final int usertype;
  final int gender;
  final String? idnum;
  final int? staff_id;
  final int? category;
  final String? nationality;
  final String? religion;
  final int? marital_status;
  final String? office_phone;
  final String? emergency_name;
  final String? emergency_ic;
  final String? emergency_relation;
  final int? emergency_gender;
  final String? emergency_phone;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.dob,
    required this.address1,
    this.address2,
    required this.city,
    required this.postcode,
    required this.state,
    required this.country,
    required this.occupation,
    required this.username,
    required this.email,
    required this.password,
    required this.usertype,
    required this.gender,
    this.idnum,
    this.staff_id,
    this.category,
    this.nationality,
    this.religion,
    this.marital_status,
    this.office_phone,
    this.emergency_name,
    this.emergency_ic,
    this.emergency_relation,
    this.emergency_gender,
    this.emergency_phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      address1: json['address1'] ?? '',
      address2: json['address2'],
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? 0,
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      occupation: json['occupation'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['passkey'] ?? '',
      usertype: json['usertype'] ?? 0,
      gender: json['gender'] ?? 1,
      idnum: json['idnum'],
      staff_id: json['staff_id'],
      category: json['category'],
      nationality: json['nationality'],
      religion: json['religion'],
      marital_status: json['marital_status'],
      office_phone: json['office_phone'],
      emergency_name: json['emergency_name'],
      emergency_ic: json['emergency_ic'],
      emergency_relation: json['emergency_relation'],
      emergency_gender: json['emergency_gender'],
      emergency_phone: json['emergency_phone'],
    );
  }
}

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
      phone: json['phone']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      address1: json['address1']?.toString() ?? '',
      address2: json['address2']?.toString(),
      city: json['city']?.toString() ?? '',
      postcode: int.tryParse(json['postcode']?.toString() ?? '') ?? 0,
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['passkey']?.toString() ?? '',
      usertype: int.tryParse(json['usertype']?.toString() ?? '') ?? 0,
      gender: int.tryParse(json['gender']?.toString() ?? '') ?? 1,
      idnum: json['idnum']?.toString(),
      staff_id: int.tryParse(json['staff_id']?.toString() ?? ''),
      category: int.tryParse(json['category']?.toString() ?? ''),
      nationality: json['nationality']?.toString(),
      religion: json['religion']?.toString(),
      marital_status: int.tryParse(json['marital_status']?.toString() ?? ''),
      office_phone: json['office_phone']?.toString(),
      emergency_name: json['emergency_name']?.toString(),
      emergency_ic: json['emergency_ic']?.toString(),
      emergency_relation: json['emergency_relation']?.toString(),
      emergency_gender: int.tryParse(json['emergency_gender']?.toString() ?? ''),
      emergency_phone: json['emergency_phone']?.toString(),
    );
  }
}

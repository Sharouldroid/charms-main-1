// import './usertype.dart';

// enum Usertype {
//   superID,
//   volunteer,
//   researcher,
//   boatowner,
//   boatdriver,
//   staffadmin,
//   manager,
//   officer,
// }

class User {
  final String id;
  String firstname;
  String lastname;
  String phone;
  String dob;
  String address1;
  String? address2;
  String city;
  int postcode;
  String state;
  String country;
  String occupation;
  String username;
  String email;
  String password;
  int usertype;
  int? status;
  int gender;
  String idnum;
  // final String urlId;

  

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
    this.status,
    required this.gender,
    required this.idnum,
  });

  User copyWith({
    String? id,
    String? firstname,
    String? lastname,
    String? phone,
    String? dob,
    String? address1,
    String? address2,
    String? city,
    int? postcode,
    String? state,
    String? country,
    String? occupation,
    String? username,
    String? email,
    String? password,
    int? usertype,
    int? status,
    int? gender,
    String? idnum,
  }) {
    return User(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      state: state ?? this.state,
      country: country ?? this.country,
      occupation: occupation ?? this.occupation,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      usertype: usertype ?? this.usertype,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      idnum: idnum ?? this.idnum,
    );
  }
}

class UserLogin {
  final int id;
  final String username;
  final String password;

  const UserLogin({
    required this.id,
    required this.username,
    required this.password,
  });
}

class Staff {
  final int staffId;
  final int userId;
  final String username;
  final String email;
  final int usertype;
  final String firstname;
  final String lastname;
  final String occupation;  // Added occupation field
  final String phone;
  final int category;// 1 for SEATRU, 2 for CMS, 3 for Intern
  final String nationality;
  final String religion;
  final int maritalStatus;// 1 for Single, 2 for Married
  final String? officePhone;
  final String emergencyName;
  final String emergencyIc;
  final String emergencyRelation;
  final int emergencyGender;
  final String emergencyPhone;
  final String idNum;
  final String dob;
  final String address1;
  final String address2;
  final String city;
  final int postcode;
  final String state;
  final String country;

  Staff({
    required this.staffId,
    required this.userId,
    required this.username,
    required this.email,
    required this.usertype,
    required this.firstname,
    required this.lastname,
    required this.occupation,
    required this.phone,
    required this.category,
    required this.nationality,
    required this.religion,
    required this.maritalStatus,
    this.officePhone,
    required this.emergencyName,
    required this.emergencyIc,
    required this.emergencyRelation,
    required this.emergencyGender,
    required this.emergencyPhone, 
    required this.idNum,
    required this.dob,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.state,
    required this.country,
  });
}
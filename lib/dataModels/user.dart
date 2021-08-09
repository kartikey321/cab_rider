import 'package:firebase_database/firebase_database.dart';

class UserData {
  String? fullname;
  String? email;
  String? phone;
  String? id;

  UserData({
    this.email,
    this.fullname,
    this.id,
    this.phone,
  });

  UserData.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    phone = snapshot.value['phone'];
    email = snapshot.value['email'];
    fullname = snapshot.value['fullName'];
  }
}

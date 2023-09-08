import 'dart:convert';
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

    final data = snapshot.value as Map<dynamic, dynamic>?;

    phone = data?['phone'] ?? '';
    email = data?['email'] ?? '';
    fullname = data?['fullname'] ?? '';
  }
}

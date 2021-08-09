import 'dart:convert';
import 'dart:math';

import 'package:cab_rider/dataModels/directionDetails.dart';
import 'package:cab_rider/dataModels/user.dart';
import 'package:cab_rider/dataproviders/appdata.dart';
import 'package:cab_rider/helpers/requestHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cab_rider/globalVariable.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class HelperMethods {
  static void getCurrentUserInfo() async {
    currentFirebaseUser = FirebaseAuth.instance.currentUser!;
    String userid = currentFirebaseUser!.uid;
    DatabaseReference userRef =
        FirebaseDatabase.instance.reference().child('users/$userid');

    userRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        currentUserInfo = UserData.fromSnapshot(snapshot);
        print('My name is ${currentUserInfo!.fullname}');
      }
    });
  }

  findCoordinateaddress() {}

  static Future<DirectionDetails?> getDirectionDetails(
      LatLng startPosition, LatLng endPosition) async {
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=driving&key=$mapKey';
    var response = await RequestHelper.getRequest(url);
    if (response == 'failed') {
      return null;
    }
    DirectionDetails directionDetails = DirectionDetails();
    directionDetails.distanceText =
        response['routes'][0]['legs'][0]['distance']['text'];
    directionDetails.distanceValue =
        response['routes'][0]['legs'][0]['distance']['value'];

    directionDetails.durationText =
        response['routes'][0]['legs'][0]['duration']['text'];
    directionDetails.durationValue =
        response['routes'][0]['legs'][0]['duration']['value'];

    directionDetails.encodedPoints =
        response['routes'][0]['overview_polyline']['points'];

    return directionDetails;
  }

  static int estimateFares(DirectionDetails details) {
    //base fare = 40₹
    //per km = 15₹
    //per min = 10₹

    double baseFare = 40;
    double distanceFare = (details.distanceValue! / 1000) * 15;
    double durationFare = (details.durationValue! / 60) * 10;

    double totalFare = baseFare + distanceFare + durationFare;

    return totalFare.truncate();
  }

  static double generateRandomNumber(int max) {
    var randomGenerator = Random();
    int randInt = randomGenerator.nextInt(max);

    return randInt.toDouble();
  }

  static sendNotification(String token, context, String ride_id) async {
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverKey,
    };

    Map notificationMap = {
      'title': 'NEW TRIP REQUEST',
      'body': 'Destination, ${destination!.placeName}'
    };

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_id': ride_id,
    };

    Map bodyMap = {
      'notification': notificationMap,
      'data': dataMap,
      'priority': 'high',
      'to': token,
    };

    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerMap,
      body: jsonEncode(bodyMap),
    );

    print(response.body);
  }
}

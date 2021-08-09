import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dataModels/user.dart';

String serverKey =
    'key=AAAApUvmFiE:APA91bFrsltKof0XWxd3woa7RnL33ECaXROqkAacxfhMopjUx5NnT_qOg-a4BffGOpWEMewrESawLFEykPPcSMRXOA9Ug2YOXRxMNcmUm-ktOiu75fpOMZyDfo6SoMco6IfP90DVDF5s';

String mapKey = 'AIzaSyCHeaBTio-AeysW6em7vfoiMR6qWBTJOBY';

final CameraPosition googlePlex = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);

User? currentFirebaseUser;

UserData? currentUserInfo;

StreamSubscription<Position>? ridePositionStream;

import 'dart:convert';

import 'package:cab_rider/dataModels/address.dart';
import 'package:cab_rider/dataproviders/appdata.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class RequestHelper {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(Uri.parse(url));

    try {
      if (response.statusCode == 200) {
        String data = response.body;
        var decodedData = jsonDecode(data);
        return decodedData;
      } else {
        return 'failed';
      }
    } catch (e) {
      return 'failed';
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  static getAddress(context) async {
    Position position = await _determinePosition();

    var data = await getRequest(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyCHeaBTio-AeysW6em7vfoiMR6qWBTJOBY')
        as Map<String, dynamic>;

    //print(place);
    var currentAddress = data['results'][0]['formatted_address'];
    // var currentAddress =
    //     " ${place.street}, ${place.administrativeArea},${place.postalCode}";
    // print(currentAddress);
    Address pickupAddress = Address();
    pickupAddress.latitude = position.latitude;
    pickupAddress.longitude = position.longitude;
    pickupAddress.placeName = currentAddress;
    Provider.of<AppData>(context, listen: false)
        .updatePickupAddress(pickupAddress);
    return currentAddress;
  }
}

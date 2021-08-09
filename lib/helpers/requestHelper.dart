import 'dart:convert';

import 'package:cab_rider/dataModels/address.dart';
import 'package:cab_rider/dataproviders/appdata.dart';
import 'package:geocoding/geocoding.dart';
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

  static getAddress(context) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark place = placemarks[0];
    //print(place);
    var currentAddress =
        " ${place.street},${place.locality},${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
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

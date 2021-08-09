import 'package:cab_rider/dataModels/nearbydriver.dart';

class FireHelper {
  static List<NearbyDriver> nearbydriverlist = [];

  static void removeFromList(String key) {
    int index = nearbydriverlist.indexWhere((element) => element.key == key);
    nearbydriverlist.removeAt(index);
  }

  static void updateNearbyLocation(NearbyDriver driver) {
    int index =
        nearbydriverlist.indexWhere((element) => element.key == driver.key);

    nearbydriverlist[index].longitude = driver.longitude;
    nearbydriverlist[index].latitude = driver.latitude;
  }
}

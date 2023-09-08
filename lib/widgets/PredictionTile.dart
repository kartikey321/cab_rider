import 'package:cab_rider/brand_colors.dart';
import 'package:cab_rider/dataModels/address.dart';
import 'package:cab_rider/dataModels/prediction.dart';
import 'package:cab_rider/dataproviders/appdata.dart';
import 'package:cab_rider/globalVariable.dart';
import 'package:cab_rider/helpers/requestHelper.dart';
import 'package:cab_rider/widgets/ProgressDialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PredictionTile extends StatelessWidget {
  final Prediction? prediction;
  PredictionTile({this.prediction});

  void getPlaceDetails(String placeId, context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        status: 'Please wait... ',
      ),
    );

    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$mapKey';
    var response = await RequestHelper.getRequest(url);

    Navigator.pop(context);

    if (response == 'failed') {
      return;
    }
    if (response['status'] == 'OK') {
      Address thisPlace = Address();
      thisPlace.placeName = response['result']['name'];
      thisPlace.placeId = placeId;
      thisPlace.latitude = response['result']['geometry']['location']['lat'];
      thisPlace.longitude = response['result']['geometry']['location']['lng'];
      Provider.of<AppData>(context, listen: false)
          .updateDestinationAddress(thisPlace);
      print(thisPlace.placeName);

      Navigator.pop(context, 'getDirection');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return TextButton(
      onPressed: () {
        getPlaceDetails(prediction!.placeId!, context);
      },
      child: Container(
        width: width,
        child: Column(
          children: [
            SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: BrandColors.colorDimText),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction!.mainText ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          prediction!.secondaryText ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: BrandColors.colorDimText,
                          ),
                        )
                      ]),
                ),
              ],
            ),
            SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}

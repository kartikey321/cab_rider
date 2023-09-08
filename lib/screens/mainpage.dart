import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cab_rider/brand_colors.dart';
import 'package:cab_rider/dataModels/directionDetails.dart';
import 'package:cab_rider/dataModels/nearbydriver.dart';
import 'package:cab_rider/dataproviders/appdata.dart';
import 'package:cab_rider/globalVariable.dart';
import 'package:cab_rider/helpers/firehelper.dart';
import 'package:cab_rider/helpers/helperMethods.dart';
import 'package:cab_rider/helpers/mapkithelper.dart';
import 'package:cab_rider/helpers/requestHelper.dart';
import 'package:cab_rider/screens/searchPage.dart';
import 'package:cab_rider/styles/styles.dart';
import 'package:cab_rider/widgets/BrandDivider.dart';
import 'package:cab_rider/widgets/CollectPaymentDialog.dart';
import 'package:cab_rider/widgets/NoDriverDialog.dart';
import 'package:cab_rider/widgets/ProgressDialog.dart';
import 'package:cab_rider/widgets/rideVariables.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  static String id = 'Main_page';
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();

  GoogleMapController? mapController;

  double mapBottomPadding = 0.0;
  double searchSheetHeight = Platform.isIOS ? 300 : 275;
  double rideDetailsSheetHeight = 0;
  double requestSheetHeight = 0;
  double tripSheetHeight = 0;

  List<LatLng> polyLineCoordinates = [];
  Set<Polyline> _polyLines = {};
  Set<Marker> _Markers = {};
  Set<Circle> _Circles = {};

  BitmapDescriptor? nearbyIcon;

  bool drawerCanOpen = true;

  String appState = 'NORMAL';

  var geolocator = Geolocator();
  Position? currentPosition;

  Position? myPosition;

  DirectionDetails? tripDirectionDetails;

  DatabaseReference? rideRef;

  StreamSubscription? rideSubscrption;

  List<NearbyDriver>? availableDrivers;

  bool nearbyDriversKeysLoaded = false;

  bool isRequestingLocationDetails = false;

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/images/car_android.png')
          .then((icon) {
        nearbyIcon = icon;
        print(nearbyIcon);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HelperMethods.getCurrentUserInfo();

    RequestHelper.getAddress(context).then((value) {
      print(value);
    });
  }

  void setUpPositionLocator() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    currentPosition = position;
    myPosition = position;

    LatLng pos = LatLng(position.latitude, position.longitude);
    CameraPosition cp = CameraPosition(
      target: pos,
      zoom: 15,
    );
    mapController!.animateCamera(CameraUpdate.newCameraPosition(cp));

    startGeofireListener();
  }

  void getLocationUpdates(status) {
    if (status != 'ontrip') {
      return;
    }
    LatLng oldPosition = LatLng(0, 0);
    ridePositionStream = Geolocator.getPositionStream(
            locationSettings:
                LocationSettings(accuracy: LocationAccuracy.bestForNavigation))
        .listen((Position position) {
      currentPosition = position;
      myPosition = position;

      LatLng pos = LatLng(myPosition!.latitude, myPosition!.longitude);

      var rotation = MapKitHelper.getMarkerRotation(oldPosition.latitude,
          oldPosition.longitude, pos.latitude, pos.longitude);

      Marker movingMarker = Marker(
          markerId: MarkerId('moving'),
          position: pos,
          icon: nearbyIcon!,
          rotation: rotation,
          infoWindow: InfoWindow(title: 'Current Location'));

      setState(() {
        CameraPosition cp = CameraPosition(target: pos, zoom: 17);

        mapController!.animateCamera(CameraUpdate.newCameraPosition(cp));

        _Markers.remove((marker) => marker.markerId.value == 'moving');

        _Markers.add(movingMarker);
      });

      oldPosition = pos;

      //updateTripDetails();

      Map locationMap = {
        'latitude': myPosition!.latitude.toString(),
        'longitude': myPosition!.latitude.toString(),
      };
      rideRef!.child('user_location').set(locationMap);
    });
  }

  void showDetailSheet() async {
    await getDirection();
    setState(() {
      searchSheetHeight = 0;
      rideDetailsSheetHeight = 235;

      mapBottomPadding = 240;
      drawerCanOpen = false;
    });
  }

  void showTripSheet() {
    setState(() {
      requestSheetHeight = 0;
      rideDetailsSheetHeight = 0;
      tripSheetHeight = 275;
      mapBottomPadding = 280;
    });
  }

  void showRequestingSheet() {
    setState(() {
      rideDetailsSheetHeight = 0;
      requestSheetHeight = 195;
      mapBottomPadding = 200;
      drawerCanOpen = true;
    });
    createRideRequest();
  }

  @override
  Widget build(BuildContext context) {
    createMarker();
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0.0),
            children: [
              Container(
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/user_icon.png',
                        height: 60,
                        width: 60,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Kartikey',
                            style: TextStyle(
                                fontSize: 20, fontFamily: 'Brand-Bold'),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text('View Profile'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              BrandDivider(),
              SizedBox(
                height: 10,
              ),
              ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text(
                  'Free Rides',
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text(
                  'Payments',
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  'Ride History',
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text(
                  'About',
                  style: kDrawerItemStyle,
                ),
              )
            ],
          ),
        ),
      ),
      // appBar: AppBar(
      //   title: Text(
      //     'Main Page',
      //   ),
      //   centerTitle: true,
      // ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapBottomPadding),
            mapType: MapType.normal,
            polylines: _polyLines,
            markers: _Markers,
            circles: _Circles,
            myLocationButtonEnabled: true,
            initialCameraPosition: googlePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;
              setState(() {
                mapBottomPadding = 280;
              });
              setUpPositionLocator();
            },
          ),

          ///MenuButton
          Positioned(
            top: 44,
            left: 20,
            child: GestureDetector(
              onTap: () {
                (drawerCanOpen)
                    ? scaffoldKey.currentState!.openDrawer()
                    : resetApp();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    (drawerCanOpen) ? Icons.menu : Icons.arrow_back,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          ////Search Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              duration: Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                height: searchSheetHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Nice to see you',
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Where are you going?',
                        style:
                            TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchPage()));
                          if (response == 'getDirection') {
                            showDetailSheet();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(7.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                )
                              ]),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text('Search Destination')
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Home'),
                              SizedBox(
                                width: 3,
                              ),
                              Text(
                                'Your residential address',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrandColors.colorDimText,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline_outlined,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Work'),
                              SizedBox(
                                width: 3,
                              ),
                              Text(
                                'Your office address',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrandColors.colorDimText,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          ////Ride Details Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              duration: Duration(
                milliseconds: 150,
              ),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                height: rideDetailsSheetHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: BrandColors.colorAccent1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/taxi.png',
                                height: 70,
                                width: 70,
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taxi',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Brand-Bold'),
                                  ),
                                  Text(
                                    tripDirectionDetails != null
                                        ? tripDirectionDetails!.distanceText!
                                        : '',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: BrandColors.colorTextLight),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                ((tripDirectionDetails != null)
                                    ? '\u{20B9} ${HelperMethods.estimateFares(tripDirectionDetails!)}'
                                    : ''),
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Brand-Bold'),
                              )
                              // Text(
                              //   '\u{20B9}200',
                              //   style: TextStyle(
                              //       fontSize: 18, fontFamily: 'Brand-Bold'),
                              // )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.moneyBillAlt,
                              size: 18,
                              color: BrandColors.colorTextLight,
                            ),
                            SizedBox(width: 16),
                            Text('Cash'),
                            SizedBox(width: 5),
                            Icon(Icons.keyboard_arrow_down,
                                color: BrandColors.colorTextLight, size: 16),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: MaterialButton(
                          onPressed: () {
                            setState(() {
                              appState = 'REQUESTING';
                            });

                            showRequestingSheet();

                            availableDrivers = FireHelper.nearbydriverlist;

                            findDriver();
                          },
                          color: BrandColors.colorGreen,
                          textColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Container(
                            height: 50,
                            child: Center(
                              child: Text(
                                'REQUEST CAB',
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Brand-Bold'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// request sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              duration: Duration(
                milliseconds: 150,
              ),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                height: requestSheetHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextLiquidFill(
                          text: 'Requesting a Ride...',
                          waveColor: BrandColors.colorTextSemiLight,
                          boxBackgroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 22.0,
                            fontFamily: 'Brand-Bold',
                            fontWeight: FontWeight.bold,
                          ),
                          boxHeight: 40.0,
                        ),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          cancelRequest();
                          resetApp();
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                width: 1.0,
                                color: BrandColors.colorLightGrayFair),
                          ),
                          child: Icon(Icons.close),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Cancel ride',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Trip sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              duration: new Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0, // soften the shadow
                      spreadRadius: 0.5, //extend the shadow
                      offset: Offset(
                        0.7, // Move to right 10  horizontally
                        0.7, // Move to bottom 10 Vertically
                      ),
                    )
                  ],
                ),
                height: tripSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tripStatusDisplay,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontFamily: 'Brand-Bold'),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        driverCarDetails,
                        style: TextStyle(color: BrandColors.colorTextLight),
                      ),
                      Text(
                        driverFullName,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular((25))),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.call),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Call'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular((25))),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.list),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Details'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular((25))),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.clear),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Cancel'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //My location button
          Positioned(
            bottom: mapBottomPadding + 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                LatLng pos = LatLng(
                    currentPosition!.latitude, currentPosition!.longitude);
                mapController!.animateCamera(
                  CameraUpdate.newLatLng(pos),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 29,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Colors.black54,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    var pickLatLng = LatLng(pickup!.latitude!, pickup.longitude!);
    var destinationLatLng =
        LatLng(destination!.latitude!, destination.longitude!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        status: 'Please wait... ',
      ),
    );

    var thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetails = thisDetails;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails!.encodedPoints!);

    polyLineCoordinates.clear();
    //print(thisDetails!.encodedPoints);

    if (results.isNotEmpty) {
      results.forEach((PointLatLng points) {
        polyLineCoordinates.add(LatLng(points.latitude, points.longitude));
      });
    }

    _polyLines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyId'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polyLineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      _polyLines.add(polyline);
    });

    //make polyline fit in the bounds

    LatLngBounds bounds;

    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(northeast: pickLatLng, southwest: destinationLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
      );
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
        northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
        markerId: MarkerId('pickup'),
        position: pickLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: pickup.placeName, snippet: 'My Location'));

    Marker destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: destination.placeName, snippet: 'Destination'));

    setState(() {
      _Markers.add(pickupMarker);
      _Markers.add(destinationMarker);
    });

    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId('destination'),
      strokeColor: BrandColors.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: destinationLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    setState(() {
      _Circles.add(pickupCircle);
      _Circles.add(destinationCircle);
    });
  }

  void startGeofireListener() {
    Geofire.initialize('driversAvailable');
    Geofire.queryAtLocation(
            currentPosition!.latitude, currentPosition!.longitude, 20)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.nearbydriverlist.add(nearbyDriver);

            if (nearbyDriversKeysLoaded) {
              updateDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];
            FireHelper.updateNearbyLocation(nearbyDriver);
            updateDriversOnMap();
            // Update your key's location
            break;

          case Geofire.onGeoQueryReady:
            nearbyDriversKeysLoaded = true;
            updateDriversOnMap();
            break;
        }
      }
    });
  }

  void updateDriversOnMap() {
    setState(() {
      _Markers.clear();
    });
    Set<Marker> tempMarkers = Set<Marker>();
    for (NearbyDriver driver in FireHelper.nearbydriverlist) {
      LatLng driverPosition = LatLng(driver.latitude!, driver.longitude!);

      Marker thisMarker = Marker(
        markerId: MarkerId('driver/${driver.key}'),
        position: driverPosition,
        icon: nearbyIcon!,
        rotation: HelperMethods.generateRandomNumber(360),
      );

      tempMarkers.add(thisMarker);
    }

    setState(() {
      _Markers = tempMarkers;
    });
  }

  void createRideRequest() {
    rideRef = FirebaseDatabase.instance.reference().child('rideRequest').push();

    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map pickupMap = {
      'latitude': pickup!.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };
    Map destinationMap = {
      'latitude': destination!.latitude.toString(),
      'longitude': destination.longitude.toString(),
    };

    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_name': currentUserInfo!.fullname,
      'rider_phone': currentUserInfo!.phone,
      'pickup_address': pickup.placeName,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment_method': 'card',
      'driver_id': 'waiting',
    };
    rideRef!.set(rideMap);

    rideSubscrption = rideRef!.onValue.listen((event) async {
      //check for null request
      var data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (event.snapshot.value == null) {
        return;
      }

      //get car details
      if (data!['car_details'] != null) {
        setState(() {
          driverCarDetails = data['car_details'].toString();
        });
      }

      //get driver name
      if (data['driver_name'] != null) {
        setState(() {
          driverFullName = data['driver_name'].toString();
        });
      }

      //get driver phone number
      if (data['driver_phone'] != null) {
        setState(() {
          driverPhoneNumber = data['driver_phone'].toString();
        });
      }

      //get and use driver's location updates
      if (data['driver_location'] != null) {
        double driverLat =
            double.parse(data['driver_location']['latitude'].toString());
        double driverLng =
            double.parse(data['driver_location']['longitude'].toString());

        LatLng driverLocation = LatLng(driverLat, driverLng);

        if (status == 'accepted') {
          updateToPickup(driverLocation);
        } else if (status == 'ontrip') {
          updateToDestination(driverLocation);
          getLocationUpdates(status);
        } else if (status == 'arrived') {
          setState(() {
            tripStatusDisplay = 'Driver has arrived';
          });
        }
      }

      if (data['status'] != null) {
        status = data['status'].toString();
      }

      if (status == 'accepted') {
        showTripSheet();
        Geofire.stopListener();
        removeGeofireMarkers();
      }

      if (status == 'ended') {
        if (data['fares'] != null) {
          int fares = int.parse(data['fares'].toString());

          var response = await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => CollectPayment(
              paymentMethod: 'cash',
              fares: fares,
            ),
          );

          if (response == 'close') {
            rideRef!.onDisconnect();
            rideRef = null;
            rideSubscrption!.cancel();
            rideSubscrption = null;
            resetApp();
          }
        }
      }
    });
  }

  void removeGeofireMarkers() {
    setState(() {
      _Markers.removeWhere((m) => m.markerId.value.contains('driver'));
    });
  }

  void updateToPickup(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var positionLatLng =
          LatLng(currentPosition!.latitude, currentPosition!.longitude);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, positionLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        tripStatusDisplay = 'Driver is Arriving - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }

  void updateToDestination(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;

      var destination =
          Provider.of<AppData>(context, listen: false).destinationAddress;

      var destinationLatLng =
          LatLng(destination!.latitude!, destination.longitude!);

      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, destinationLatLng);
      print(thisDetails!.durationText);

      if (thisDetails.durationText == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            'Driving to Destination - ${thisDetails.durationText}';
      });

      isRequestingLocationDetails = false;
    }
  }

  void cancelRequest() {
    rideRef!.remove();

    setState(() {
      appState = 'NORMAL';
    });
  }

  resetApp() {
    setState(() {
      polyLineCoordinates.clear();
      _polyLines.clear();
      _Markers.clear();
      _Circles.clear();
      requestSheetHeight = 0;
      rideDetailsSheetHeight = 0;
      tripSheetHeight = 0;

      searchSheetHeight = 275;
      mapBottomPadding = 280;
      drawerCanOpen = true;

      status = '';
      driverFullName = '';
      driverPhoneNumber = '';
      driverCarDetails = '';
      tripStatusDisplay = 'Driver is Arriving';
    });
    setUpPositionLocator();
  }

  void noDriverFound() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => NoDriverDialog(),
    );
  }

  void findDriver() {
    if (availableDrivers!.length == 0) {
      noDriverFound();
      cancelRequest();
      resetApp();
      //no driver

      return;
    }
    var driver = availableDrivers![0];

    notifyDriver(driver);

    availableDrivers!.removeAt(0);

    print(driver.key);
  }

  void notifyDriver(NearbyDriver driver) {
    DatabaseReference driverTripRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${driver.key}/newtrip');

    driverTripRef.set(rideRef!.key);

    //Get and notify driver using token
    DatabaseReference tokenRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${driver.key}/token');

    tokenRef.once().then((data) {
      var snapshot = data.snapshot;
      if (snapshot.value != null) {
        String token = snapshot.value.toString();

        //send notification to the selected driver
        HelperMethods.sendNotification(token, context, rideRef!.key!);
      } else {
        return;
      }

      const oneSecTik = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecTik, (timer) {
        //stop timer when ride request is cancelled
        if (appState != 'REQUESTING') {
          driverTripRef.set('cancelled');
          driverTripRef.onDisconnect();
          timer.cancel();
          driverRequestTimeout = 30;
        }

        driverRequestTimeout--;

        driverTripRef.onValue.listen((event) {
          // confirms that driver has clicked accepted for the new trip request
          if (event.snapshot.value.toString() == 'accepted') {
            driverTripRef.onDisconnect();
            timer.cancel();
            driverRequestTimeout = 30;
          }
        });

        if (driverRequestTimeout == 0) {
          //informs driver that trip has been timed out
          driverTripRef.set('timeout');
          driverTripRef.onDisconnect();
          driverRequestTimeout = 30;
          timer.cancel();

          //select the next closest driver
          findDriver();
        }
      });
    });
  }
}

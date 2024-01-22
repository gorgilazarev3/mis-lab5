import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mis_lab3/config_maps.dart';
import 'package:mis_lab3/models/app_data.dart';
import 'package:mis_lab3/models/direction_details.dart';
import 'package:mis_lab3/models/location_based_event.dart';
import 'package:provider/provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late GoogleMapController _gMapsController;

  LatLng clickedLocation = facultyLocation.target;
  late Position currentPosition;
  late LatLng directionPosition;

  TextEditingController newEventController = TextEditingController();

  final List<LocationBasedEvent> locationBasedEvents = [];

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  static const CameraPosition facultyLocation = CameraPosition(
    target: LatLng(42.004486, 21.4072295),
    zoom: 14.4746,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadMarkers();
  }

  Future<void> locatePosition() async {
        LocationPermission permission;
        permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location Not Available');
      }
    }
        Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true);
    currentPosition = position;
  }

  void loadMarkers() {
    for (LocationBasedEvent event
        in Provider.of<AppData>(context, listen: false).locationBasedEvents) {
      final marker = Marker(
        markerId: MarkerId(event.name!),
        position: event.location!,
        // icon: BitmapDescriptor.,
        infoWindow: InfoWindow(
          title: event.name,
          snippet: 'Имате потсетник на оваа локација за настанот ${event.name}',
        ),
      );
      markers[marker.markerId] = marker;
    }
  }

    void showNewEventDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            content: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: TextFormField(
                        controller: newEventController,
                        // style: TextStyle(color: Colors.lightBlue),
                        decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Внесете го името на настанот',
                            hintStyle: TextStyle(color: Colors.teal)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(50),
                      child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              LocationBasedEvent newEvent = LocationBasedEvent(location: clickedLocation, name: newEventController.text, date: DateTime.now());
                              //this.locationBasedEvents.add(newEvent);
                              Provider.of<AppData>(context, listen: false).addEvent(newEvent);
                              final marker = Marker(
                                markerId: MarkerId(newEvent.name!),
                                position: newEvent.location!,
                                // icon: BitmapDescriptor.,
                                infoWindow: InfoWindow(
                                  title: newEvent.name,
                                  snippet: 'Имате потсетник на оваа локација за настанот ${newEvent.name} кој ќе се случи на ${newEvent.date.toString()}',
                                ),
                                onTap: () {
                                  setState(() {
                                    directionPosition = newEvent.location!;
                                  });
                                  getDirectionToLocation();
                                },
                              );
                              markers[marker.markerId] = marker;
                              Navigator.pop(context);
                            });
                          },
                          child: Text(
                            'Додади',
                            style: TextStyle(color: Colors.teal),
                          )),
                    )
                  ],
                ))));
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: Text("Мапа со локации со настани",style: TextStyle(color: Colors.white, fontSize: 18),),),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: facultyLocation,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: true,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        polylines: polylineSet,
        markers: markers.values.toSet(),
        onMapCreated: (GoogleMapController controller) async {
          _controller.complete(controller);
          _gMapsController = controller;
          await locatePosition();
        },
        onTap: (location) {
          this.setState(() {
            clickedLocation = location;
          });
          showNewEventDialog();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text('Врати се назад', style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.arrow_back_outlined, color: Colors.white,),
        
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  static Future<DirectionDetails> obtainDirectionDetails(
      LatLng initialPosition, LatLng destinationPosition) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=${ConfigMaps.GOOGLE_MAPS_API_KEY}";

    final response = await http.get(
        Uri.parse("https://corsproxy.io/?" + Uri.encodeComponent(url)),
        headers: {"x-requested-with": "XMLHttpRequest"});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var jsonObj = jsonDecode(response.body);
      if (jsonObj["status"] == "OK") {
        DirectionDetails directionDetails = DirectionDetails.fromJson(jsonObj);

        return directionDetails;
      } else {
        throw Exception('Failed to load directions');
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load directions');
    }
  }
  
  Future<void> getDirectionToLocation() async {
    var details = await obtainDirectionDetails(
        LatLng(currentPosition.latitude, currentPosition.longitude), directionPosition);

            PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodePolylinePointsResult.isNotEmpty) {
      decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(
           LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.teal,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);

      LatLngBounds latlngBounds;
      if (currentPosition.latitude > directionPosition.latitude &&
          currentPosition.longitude > directionPosition.longitude) {
        latlngBounds =
            LatLngBounds(southwest: directionPosition, northeast: LatLng(currentPosition.latitude, currentPosition.longitude));
      } else if (currentPosition.longitude > directionPosition.longitude) {
        latlngBounds = LatLngBounds(
            southwest: LatLng(
                currentPosition.latitude, directionPosition.longitude),
            northeast: LatLng(
                directionPosition.latitude, currentPosition.longitude));
      } else if (currentPosition.latitude > directionPosition.latitude) {
        latlngBounds = LatLngBounds(
            southwest: LatLng(
                directionPosition.latitude, currentPosition.longitude),
            northeast: LatLng(
                currentPosition.latitude, directionPosition.longitude));
      } else {
        latlngBounds =
            LatLngBounds(southwest: LatLng(currentPosition.latitude, currentPosition.longitude), northeast: directionPosition);
      }

          _gMapsController
          .animateCamera(CameraUpdate.newLatLngBounds(latlngBounds, 70));
  });
  }
}
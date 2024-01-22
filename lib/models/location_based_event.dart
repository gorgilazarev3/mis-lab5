import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationBasedEvent {
  LatLng? location;
  String? name;
  DateTime? date;

  LocationBasedEvent({this.location, this.name, this.date});
}
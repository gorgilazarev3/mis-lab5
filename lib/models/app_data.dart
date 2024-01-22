import 'package:flutter/material.dart';
import 'package:mis_lab3/models/location_based_event.dart';

class AppData extends ChangeNotifier {
  List<LocationBasedEvent> locationBasedEvents = [];

  void addEvent(LocationBasedEvent event) {
    locationBasedEvents.add(event);
    notifyListeners();
  }

  void removeEvent(LocationBasedEvent event) {
    locationBasedEvents.remove(event);
    notifyListeners();
  }
}
import 'dart:async';

import 'package:aisleaide/Grid_and_Navigation/grid.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BeaconService {
  static final BeaconService _instance = BeaconService._internal();
  static const Map<String, String> beaconUUIDs = {
    'beacon1': 'F7EA68EF-4477-418C-9447-07C6C5D07B0C',
    'beacon2': 'E63227F8-F830-4DCC-BEAB-B94C4A5FAA62',
    'beacon3': 'A5C2D3F6-EEDC-4973-AFAE-EB2A6304085B',
  };

  factory BeaconService() {
    return _instance;
  }

  BeaconService._internal();

  StreamSubscription<Map<String, bool>>? _beaconSubscription;

  Stream<Map<String, bool>> startBeaconTrackingStream() {
    return FlutterBluePlus.scanResults.asyncMap((scanResultList) {
      Map<String, bool> beaconStatus = {
        'beacon1': false,
        'beacon2': false,
        'beacon3': false,
      };

      beaconStatus.forEach((key, value) {
        beaconStatus[key] = false;
      });

      for (ScanResult scanResult in scanResultList) {
        for (String key in beaconUUIDs.keys) {
          if (scanResult.device.remoteId.toString() == beaconUUIDs[key]) {
            beaconStatus[key] = true;
          }
        }
      }
      return beaconStatus;
    });
  }

  void startBeaconTracking() async {
    _beaconSubscription = startBeaconTrackingStream().listen((beaconStatus) {
      gridMapKey.currentState?.updateUserLocationFromBeacon(beaconStatus);
    });
  }

  void stopBeaconTracking() {
    _beaconSubscription?.cancel();
  }
}

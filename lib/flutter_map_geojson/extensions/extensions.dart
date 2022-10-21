import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_jts/dart_jts.dart' as dart_jts;
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polyline/properties.dart';

extension StringX on String {
  Uri toUri() {
    return Uri.parse(this);
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString, Color fallColor) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } else {
      return fallColor;
    }
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension LantLngX<T> on List<List<double>> {
  List<LatLng> toLatLng() {
    return map((e) {
      var x = e[1];
      var y = e[0];
      return LatLng(x, y);
    }).toList();
  }
}

extension LantLngCoordinate<T> on List<dart_jts.Coordinate> {
  List<LatLng> toLatLng() {
    return map((e) {
      var x = e.x;
      var y = e.y;
      return LatLng(x, y);
    }).toList();
  }
}

extension Coordinatex on List<LatLng> {
  List<dart_jts.Coordinate> toCoordinates() {
    return map((e) => dart_jts.Coordinate(e.latitude, e.longitude)).toList();
  }

  List<dart_jts.Coordinate> toCoordinatesProjted() {
    return map((e) => dart_jts.Coordinate(e.latitude * 6371e3, e.longitude * 6371e3)).toList();
  }
}

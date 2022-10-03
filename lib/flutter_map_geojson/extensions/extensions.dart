import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:dart_jts/dart_jts.dart' as dart_jts;
import 'package:point_in_polygon/point_in_polygon.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:template_skeleton/flutter_map_geojson/utils.dart';

extension StringX on String {
  Uri toUri() {
    return Uri.parse(this);
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } else {
      return const Color(0xFFF2F2F2).withOpacity(0.3);
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
  List<latlong2.LatLng> toLatLng() {
    return map((e) {
      var x = e[1];
      var y = e[0];
      return latlong2.LatLng(x, y);
    }).toList();
  }
}

extension LantLngCoordinate<T> on List<dart_jts.Coordinate> {
  List<latlong2.LatLng> toLatLng() {
    return map((e) {
      var x = e.x;
      var y = e.y;
      return latlong2.LatLng(x, y);
    }).toList();
  }
}

extension PolygonsXX on List<List<List<double>>> {
  Polygon toPolygon({PolygonProperties polygonProperties = const PolygonProperties()}) {
    var holes = sublist(1).map((f) => f.toLatLng()).toList();
    var polygon = Polygon(
      points: first.toLatLng(),
      holePointsList: holes,
      color: polygonProperties.fillColor,
      isFilled: polygonProperties.isFilled,
      borderColor: polygonProperties.borderColor,
      borderStrokeWidth: polygonProperties.borderStokeWidth,
      disableHolesBorder: polygonProperties.disableHolesBorder,
      label: polygonProperties.label,
      isDotted: polygonProperties.extraLayerPolygonProperties.isDotted,
      labelPlacement: polygonProperties.extraLayerPolygonProperties.labelPlacement,
      labelStyle: polygonProperties.extraLayerPolygonProperties.labelStyle,
      rotateLabel: polygonProperties.extraLayerPolygonProperties.rotateLabel,
      strokeCap: polygonProperties.extraLayerPolygonProperties.strokeCap,
      strokeJoin: polygonProperties.extraLayerPolygonProperties.strokeJoin,
    );
    // consoleLog(polygon.area(), color: 35);
    return polygon;
  }
}

extension Coordinatex on List<latlong2.LatLng> {
  List<dart_jts.Coordinate> toCoordinates() {
    return map((e) => dart_jts.Coordinate(e.latitude, e.longitude)).toList();
  }

  List<dart_jts.Coordinate> toCoordinatesProjted() {
    return map((e) => dart_jts.Coordinate(e.latitude * 6371e3, e.longitude * 6371e3)).toList();
  }
}

extension PolygonsX on List<Polygon> {
  List<Polygon> toBuffers(double radius) {
    return map((e) => e.buffer(radius)).toList();
  }

  List<Polygon> toBuffersWithOriginals(double radius) {
    return map((e) => e.toBuffer(radius)).expand((e) => e).toList();
  }
}

extension PolygonX on Polygon {
  static bool fromRange() {
    return true;
  }

  List<Polygon> toBuffer(double radius) {
    return [this, buffer(radius)];
  }

  double area() {
    return dart_jts.Area.ofRing(
      points.toCoordinatesProjted(),
    );
  }

  Polygon buffer(double radius) {
    var precesion = dart_jts.PrecisionModel.fixedPrecision(0);
    //
    var listCoordinate = points.toCoordinates();
    var listLinearRing = dart_jts.LinearRing(listCoordinate, precesion, 10);
    //
    List<dart_jts.LinearRing>? holesLineString = holePointsList!.map((pts) {
      var listCoordinates = pts.toCoordinates();
      return dart_jts.LinearRing(listCoordinates, precesion, 10);
    }).toList();
    // consoleLog(holesLineString.length);
//
    final geometryFactory = dart_jts.GeometryFactory.defaultPrecision();
    final polygons = geometryFactory.createPolygon(listLinearRing, holesLineString);
    var distanceDMS = dmFromMeters(radius);
    final buffer = dart_jts.BufferOp.bufferOp3(polygons, distanceDMS, 10);
    var bufferBolygon = buffer as dart_jts.Polygon;
    var listPointsPolygon = bufferBolygon.shell!.points.toCoordinateArray().toLatLng();
    var polygon = Polygon(
      points: listPointsPolygon,
      isFilled: isFilled,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      disableHolesBorder: disableHolesBorder,
      holePointsList: holePointsList,
      isDotted: isDotted,
      label: label,
      labelPlacement: labelPlacement,
      labelStyle: labelStyle,
      rotateLabel: rotateLabel,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
    );
    return polygon;
  }

  bool isGeoPointInPolygon(latlong2.LatLng latlng) {
    var isInPolygon = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      if ((((points[i].latitude <= latlng.latitude) && (latlng.latitude < points[j].latitude)) ||
              ((points[j].latitude <= latlng.latitude) &&
                  (latlng.latitude < points[i].latitude))) &&
          (latlng.longitude <
              (points[j].longitude - points[i].longitude) *
                      (latlng.latitude - points[i].latitude) /
                      (points[j].latitude - points[i].latitude) +
                  points[i].longitude)) isInPolygon = !isInPolygon;
    }
    return isInPolygon;
  }

  bool isIntersectedWithPoint(latlong2.LatLng latlng) {
    var currPoint = Point(
      x: latlng.latitude,
      y: latlng.longitude,
    );
    var pInP = Poly.isPointInPolygon(
      currPoint,
      points.map((e) {
        return Point(
          x: e.latitude,
          y: e.longitude,
        );
      }).toList(),
    );
    return pInP;
  }
}

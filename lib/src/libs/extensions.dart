import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:dart_jts/dart_jts.dart' as dart_jts;
import 'package:point_in_polygon/point_in_polygon.dart';
import 'package:template_skeleton/src/libs/utils.dart';

extension LantLngX<T> on List<T> {
  List<latlong2.LatLng> toLatLng() {
    return map((e) {
      var x = e is dart_jts.Coordinate
          ? e.x
          : e is List<double>
              ? e[1]
              : 0.0;
      var y = e is dart_jts.Coordinate
          ? e.y
          : e is List<double>
              ? e[0]
              : 0.0;
      return latlong2.LatLng(x, y);
    }).toList();
  }
}

extension PolygonsXX on List<List<List<double>>> {
  Polygon toPolygon({
    bool isFilled = true,
    Color color = Colors.blue,
    Color borderColor = Colors.black,
    double borderStrokeWidth = 0,
    bool disableHolesBorder = false,
    List<List<latlong2.LatLng>>? holePointsList,
    bool isDotted = false,
    String? label,
    PolygonLabelPlacement labelPlacement = PolygonLabelPlacement.centroid,
    TextStyle labelStyle = const TextStyle(),
    bool rotateLabel = false,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
  }) {
    var holes = sublist(1).map((f) => f.toLatLng()).toList();
    var polygon = Polygon(
      isFilled: isFilled,
      color: color.withOpacity(0.5),
      points: first.toLatLng(),
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      disableHolesBorder: disableHolesBorder,
      holePointsList: holes,
      isDotted: isDotted,
      label: label,
      labelPlacement: labelPlacement,
      labelStyle: labelStyle,
      rotateLabel: rotateLabel,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
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

  bool isGeoPointInPolygon(latlong2.LatLng position) {
    var isInPolygon = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      if ((((points[i].latitude <= position.latitude) &&
                  (position.latitude < points[j].latitude)) ||
              ((points[j].latitude <= position.latitude) &&
                  (position.latitude < points[i].latitude))) &&
          (position.longitude <
              (points[j].longitude - points[i].longitude) *
                      (position.latitude - points[i].latitude) /
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

import 'package:dart_jts/dart_jts.dart' as dart_jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:template_skeleton/flutter_map_geojson/extensions/extensions.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polyline/properties.dart';
import 'package:template_skeleton/flutter_map_geojson/utils.dart';

extension PolylinesX on List<Polyline> {
  List<Polygon> toBuffers(double radius) {
    return map((e) => e.buffer(radius)).toList();
  }

  List<Polygon> toBuffersWithOriginals(double radius) {
    return map((e) => e.toBuffer(radius)).toList();
  }
}

extension PolylineX on Polyline {
  static bool fromRange() {
    return true;
  }

  Polygon toBuffer(double radius) {
    return buffer(radius);
  }

  double area() {
    return dart_jts.Area.ofRing(
      points.toCoordinatesProjted(),
    );
  }

  Polygon buffer(double radius) {
    // var precesion = dart_jts.PrecisionModel.fixedPrecision(0);
    //
    var listCoordinate = points.toCoordinates();
    // var listLinearRing = dart_jts.LinearRing(listCoordinate, precesion, 10);
    //

    // consoleLog(holesLineString.length);
//
    final geometryFactory = dart_jts.GeometryFactory.defaultPrecision();
    final polylines = geometryFactory.createLineString(listCoordinate);
    var distanceDMS = dmFromMeters(radius);
    final buffer = dart_jts.BufferOp.bufferOp3(polylines, distanceDMS, 10);
    var bufferBolygon = buffer as dart_jts.Polygon;
    var listPointsPolyline = bufferBolygon.shell!.points.toCoordinateArray().toLatLng();
    var polygon = Polygon(
      points: listPointsPolyline,
      isFilled: true,
      color: color,
      borderColor: borderColor ?? const Color(0xFF002CA3),
      borderStrokeWidth: borderStrokeWidth,
      isDotted: isDotted,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
    );
    return polygon;
  }
}

extension PolylineXX on List<List<double>> {
  Polyline toPolyline({PolylineProperties polylineProperties = const PolylineProperties()}) {
    var polyline = Polyline(
      colorsStop: polylineProperties.colorsStop,
      gradientColors: polylineProperties.gradientColors,
      strokeWidth: polylineProperties.strokeWidth,
      points: toLatLng(),
      color: polylineProperties.fillColor,
      borderColor: polylineProperties.borderColor,
      borderStrokeWidth: polylineProperties.borderStokeWidth,
      isDotted: polylineProperties.isDotted,
      strokeCap: polylineProperties.strokeCap,
      strokeJoin: polylineProperties.strokeJoin,
    );
    // consoleLog(polyline.area(), color: 35);
    return polyline;
  }
}

import 'package:dart_jts/dart_jts.dart' as dart_jts;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geoflutter/flutter_map_geojson/extensions/extensions.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/markers/properties.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:geoflutter/flutter_map_geojson/utils.dart';

extension MarkersX on List<Marker> {
  List<Polygon> toBuffers(double radius) {
    return map((e) => e.buffer(radius)).toList();
  }
}

extension MarkerX on Marker {
  Polygon buffer(double radius) {
    var precesion = dart_jts.PrecisionModel.fixedPrecision(0);
    // final geometryFactory = dart_jts.GeometryFactory.defaultPrecision();
    var distanceDMS = dmFromMeters(radius);
    ////
    // var listCoordinate = [point].toCoordinates();
    // var listLinearRing = dart_jts.LinearRing(listCoordinate, precesion, 10);
    // final markers = geometryFactory.createPolygon(listLinearRing, []);
    final buffer = dart_jts.BufferOp.bufferOp(
      dart_jts.Point(point.toCoordinate(), precesion, 0),
      distanceDMS,
    );
    var bufferBolygon = buffer as dart_jts.Polygon;
    var listPointsMarker = bufferBolygon.shell!.points.toCoordinateArray().toLatLng();
    var polygon = Polygon(
      isFilled: true,
      holePointsList: [],
      points: listPointsMarker,
      label: PolygonProperties.defLabel,
      color: PolygonProperties.defFillColor,
      isDotted: PolygonProperties.defIsDotted,
      strokeCap: PolygonProperties.defStrokeCap,
      labelStyle: PolygonProperties.defLabelStyle,
      strokeJoin: PolygonProperties.defStrokeJoin,
      rotateLabel: PolygonProperties.defRotateLabel,
      borderColor: PolygonProperties.defBorderColor,
      labelPlacement: PolygonProperties.defLabelPlacement,
      borderStrokeWidth: PolygonProperties.defBorderStokeWidth,
      disableHolesBorder: PolygonProperties.defDisableHolesBorder,
    );
    return polygon;
  }
}

extension MarkerXX on List<double> {
  Marker toMarker({required MarkerProperties markerProperties}) {
    var marker = Marker(
      height: markerProperties.height,
      width: markerProperties.width,
      rotate: markerProperties.rotate,
      builder: markerProperties.builder,
      rotateAlignment: markerProperties.rotateAlignment,
      anchorPos: markerProperties.anchorPos,
      key: markerProperties.key,
      rotateOrigin: markerProperties.rotateOrigin,
      point: LatLng(this[1], this[0]),
    );
    return marker;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

typedef ClusterWidgetBuilder = Widget Function(BuildContext context, List<Marker> markers);

class PolygonEsri extends Polygon {
  final List<LatLng> markers;
  final List<Offset> offseets = [];
  final Color coleur;
  final double borderStrokeSize;
  final Color borderColeur;
  final bool isdotted;
  final bool isfilled;
  final dynamic attributes;
  late final LatLngBounds boundingbox;

  PolygonEsri({
    required this.markers,
    this.coleur = const Color(0xFF00FF00),
    this.borderStrokeSize = 0.0,
    this.borderColeur = const Color(0xFFFFFF00),
    this.isdotted = false,
    this.isfilled = false,
    this.attributes,
  }) : super(points: markers) {
    boundingbox = LatLngBounds.fromPoints(points);
  }
}

class PolyLineEsri extends Polyline {
  final List<LatLng> markers;
  final List<Offset> offseets = [];
  final Color coleur;
  final double borderStrokeSize;
  final Color borderColeur;
  final bool isdotted;
  final dynamic attributes;
  late final LatLngBounds boundingbox;

  PolyLineEsri({
    required this.markers,
    this.coleur = const Color(0xFF00FF00),
    this.borderStrokeSize = 0.0,
    this.borderColeur = const Color(0xFFFFFF00),
    this.isdotted = false,
    this.attributes,
  }) : super(points: markers) {
    boundingBox = LatLngBounds.fromPoints(points);
  }
}

class PolygonOptions {
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;
  final bool isFilled;

  const PolygonOptions({
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
    this.isFilled = false,
  });
}

class PolygonLineOptions {
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isDotted;

  const PolygonLineOptions({
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.isDotted = false,
  });
}

class PointOptions {
  final double width;
  final double height;
  final Widget builder;
  const PointOptions({
    this.width = 30.0,
    this.height = 30.0,
    this.builder = const Icon(Icons.pin_drop),
  });
}

class AnimationsOptions {
  final Duration zoom;
  final Duration fitBound;
  final Curve fitBoundCurves;
  final Duration centerMarker;
  final Curve centerMarkerCurves;
  final Duration spiderfy;

  const AnimationsOptions({
    this.zoom = const Duration(milliseconds: 500),
    this.fitBound = const Duration(milliseconds: 500),
    this.centerMarker = const Duration(milliseconds: 500),
    this.spiderfy = const Duration(milliseconds: 500),
    this.fitBoundCurves = Curves.fastOutSlowIn,
    this.centerMarkerCurves = Curves.fastOutSlowIn,
  });
}

class FeatureLayerOptions extends TileLayer {
  final Size size;

  final Size Function(List<Marker>)? computeSize;

  final AnchorPos? anchor;

  final int maxClusterRadius;

  final String url;

  final String geometryType;

  final FitBoundsOptions fitBoundsOptions;

  final bool zoomToBoundsOnClick;

  final AnimationsOptions animationsOptions;

  final bool centerMarkerOnClick;

  final int spiderfyCircleRadius;

  final int spiderfySpiralDistanceMultiplier;

  final int circleSpiralSwitchover;

  final List<Point> Function(int, Point)? spiderfyShapePositions;

  final dynamic Function(dynamic attributes)? render;

  final void Function(dynamic attributes, LatLng location)? onTap;

  FeatureLayerOptions(
    this.url,
    this.geometryType, {
    super.key,
    this.size = const Size(30, 30),
    this.computeSize,
    this.anchor,
    this.maxClusterRadius = 80,
    this.animationsOptions = const AnimationsOptions(),
    this.fitBoundsOptions = const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
    this.zoomToBoundsOnClick = true,
    this.centerMarkerOnClick = true,
    this.spiderfyCircleRadius = 40,
    this.spiderfySpiralDistanceMultiplier = 1,
    this.circleSpiralSwitchover = 9,
    this.spiderfyShapePositions,
    this.onTap,
    this.render,
  });
}

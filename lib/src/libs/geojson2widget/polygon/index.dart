import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:template_skeleton/src/libs/extensions.dart';
import 'package:http/http.dart';
import 'package:template_skeleton/src/libs/geojson2widget/polygon/properties.dart';
import 'package:latlong2/latlong.dart' as latlong2;

Future<List<Polygon>> _networkPolygons(
  Uri urlString, {
  Client? client,
  Map<String, String>? headers,
  Map<LayerPolygonProperties, String>? layerProperties,
  required ExtraLayerPolygonProperties extraLayerPolygonProperties,
  MapController? mapController,
}) async {
  var method = client == null ? get : client.get;
  var response = await method(urlString, headers: headers);
  final geojson = GeoJSONFeatureCollection.fromMap(jsonDecode(response.body));
  List<List<Polygon>> polygons = geojson.features.map((elm) {
    if (elm != null) {
      var geometry = elm.geometry;
      var properties = elm.properties;
      var polygonProperties = PolygonProperties.fromMap(
        properties,
        layerProperties,
        extraLayerPolygonProperties: extraLayerPolygonProperties,
      );
      if (geometry is GeoJSONPolygon) {
        return [geometry.coordinates.toPolygon(polygonProperties: polygonProperties)];
      } else if (geometry is GeoJSONMultiPolygon) {
        var coordinates = geometry.coordinates;
        return coordinates.map((e) {
          return e.toPolygon(polygonProperties: polygonProperties);
        }).toList();
      }
      var bbox = elm.bbox;
      if (bbox != null && mapController != null) {
        var latLngBounds = LatLngBounds(
          latlong2.LatLng(bbox[1], bbox[0]),
          latlong2.LatLng(bbox[3], bbox[2]),
        );
        mapController.fitBounds(latLngBounds);
      }
    }
    return [Polygon(points: [])];
  }).toList();
  return polygons.expand((element) => element).toList();
}

class GeoJSONPolygons {
  static Widget network(
    String url, {
    Client? client,
    Map<String, String>? headers,
    Map<LayerPolygonProperties, String>? layerProperties,
    ExtraLayerPolygonProperties extraLayerPolygonProperties = const ExtraLayerPolygonProperties(),
    MapController? mapController,
  }) {
    var uriString = url.toUri();
    return FutureBuilder(
      future: _networkPolygons(
        uriString,
        headers: headers,
        client: client,
        layerProperties: layerProperties,
        extraLayerPolygonProperties: extraLayerPolygonProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            return PolygonLayer(polygons: snap.data ?? []);
          }
        } else if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }
}

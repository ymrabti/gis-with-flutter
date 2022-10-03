import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_skeleton/flutter_map_geojson/console.dart';
import 'package:template_skeleton/flutter_map_geojson/extensions/extensions.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';

Future<Directory> getDocumentsDir() async => await path_provider.getApplicationDocumentsDirectory();

Future<List<Directory>?> getExternalDir() async {
  var externalStorageDirectories = await path_provider.getExternalStorageDirectories();
  return externalStorageDirectories;
}

Future<void> generateCsv(String data) async {
  var instance = await SharedPreferences.getInstance();
  /* var pathShared = instance.getString('geojson'); */
  var list = await getExternalDir();
  var directory = ((list == null) ? Directory('path') : list[0]).path;
  final path = "$directory/geojson.json";
  Console.log(
    directory,
    color: ConsoleColors.violet,
    consoleStyle: ConsoleStyles.italic,
  );
  final File file = File(path);
  var exists = await file.exists();
  if (!exists) {
    var savedFile = await file.writeAsString(data.toString());
    Console.log(
      savedFile,
      color: ConsoleColors.violet,
      consoleStyle: ConsoleStyles.italic,
    );
    instance.setString('geojson', savedFile.path);
  }
}

Future<List<Polygon>> _filePolygons(
  String path, {
  Map<LayerPolygonProperties, String>? layerProperties,
  required ExtraLayerPolygonProperties extraLayerPolygonProperties,
  MapController? mapController,
}) async {
  final file = File(path);
  var exists = await file.exists();
  Console.log(
    exists,
    color: ConsoleColors.green,
    consoleStyle: ConsoleStyles.bold,
  );
  if (exists) {
    var string = await file.readAsString();
    return _string(
      string,
      layerProperties: layerProperties,
      extraLayerPolygonProperties: extraLayerPolygonProperties,
      mapController: mapController,
    );
  } else {
    return [];
  }
}

Future<List<Polygon>> _assetPolygons(
  String path, {
  Map<LayerPolygonProperties, String>? layerProperties,
  required ExtraLayerPolygonProperties extraLayerPolygonProperties,
  MapController? mapController,
}) async {
  final string = await rootBundle.loadString(path);
  return _string(
    string,
    layerProperties: layerProperties,
    extraLayerPolygonProperties: extraLayerPolygonProperties,
    mapController: mapController,
  );
}

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
  var string = response.body;
  await generateCsv(string);
  return _string(
    string,
    layerProperties: layerProperties,
    extraLayerPolygonProperties: extraLayerPolygonProperties,
    mapController: mapController,
  );
}

List<Polygon> _string(
  String string, {
  Map<LayerPolygonProperties, String>? layerProperties,
  required ExtraLayerPolygonProperties extraLayerPolygonProperties,
  MapController? mapController,
}) {
  final geojson = GeoJSONFeatureCollection.fromMap(jsonDecode(string));
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
    Key? key,
    bool polygonCulling = false,
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
            return PolygonLayer(
              polygons: snap.data ?? [],
              key: key,
              polygonCulling: polygonCulling,
            );
          }
        } else if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }

  static Widget asset(
    String url, {
    Map<LayerPolygonProperties, String>? layerProperties,
    ExtraLayerPolygonProperties extraLayerPolygonProperties = const ExtraLayerPolygonProperties(),
    MapController? mapController,
    Key? key,
    bool polygonCulling = false,
  }) {
    return FutureBuilder(
      future: _assetPolygons(
        url,
        layerProperties: layerProperties,
        extraLayerPolygonProperties: extraLayerPolygonProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            return PolygonLayer(
              polygons: snap.data ?? [],
              key: key,
              polygonCulling: polygonCulling,
            );
          }
        } else if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }

  static Widget file(
    String path, {
    Map<LayerPolygonProperties, String>? layerProperties,
    ExtraLayerPolygonProperties extraLayerPolygonProperties = const ExtraLayerPolygonProperties(),
    MapController? mapController,
    Key? key,
    bool polygonCulling = false,
  }) {
    return FutureBuilder(
      future: _filePolygons(
        path,
        layerProperties: layerProperties,
        extraLayerPolygonProperties: extraLayerPolygonProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            return PolygonLayer(
              polygons: snap.data ?? [],
              key: key,
              polygonCulling: polygonCulling,
            );
          }
        } else if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }

  static Widget string(
    String data, {
    Map<LayerPolygonProperties, String>? layerProperties,
    ExtraLayerPolygonProperties extraLayerPolygonProperties = const ExtraLayerPolygonProperties(),
    MapController? mapController,
    Key? key,
    bool polygonCulling = false,
  }) {
    return PolygonLayer(
      polygons: _string(
        data,
        extraLayerPolygonProperties: extraLayerPolygonProperties,
      ),
      key: key,
      polygonCulling: polygonCulling,
    );
  }
}

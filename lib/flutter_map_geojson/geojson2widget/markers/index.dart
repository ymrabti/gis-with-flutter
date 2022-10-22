import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geoflutter/flutter_map_geojson/extensions/marker.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/markers/properties.dart';
import 'package:geoflutter/flutter_map_geojson/utils.dart';
import 'package:geoflutter/flutter_map_geojson/extensions/extensions.dart';
import 'package:geoflutter/utils/lists.dart';

Future<File> _createFile() async {
  var instance = await SharedPreferences.getInstance();
  /* var pathShared = instance.getString('geojson'); */
  var list = await getExternalDir();
  var directory = ((list == null || list.isEmpty) ? Directory('path') : list[0]).path;
  final path = "$directory/geojson.json";
  final File file = File(path);
  var exists = await file.exists();
  if (!exists) {
    var savedFile = await file.writeAsString(geojsonfile);
    await instance.setString('geojson', savedFile.path);
    return savedFile;
  }
  return file;
}

Future<List<Marker>> _fileMarkers(
  String path, {
  Map<LayerMarkerIndexes, String>? layerProperties,
  required MarkerProperties markerLayerProperties,
  MapController? mapController,
}) async {
  final file = File(path);
  var exists = await file.exists();
  if (exists) {
    var readasstring = await file.readAsString();
    return _string(
      readasstring,
      layerMap: layerProperties,
      markerPropertie: markerLayerProperties,
      mapController: mapController,
    );
  } else {
    return [];
  }
}

Future<List<Marker>> _memoryMarkers(
  Uint8List list, {
  Map<LayerMarkerIndexes, String>? layerProperties,
  required MarkerProperties markerLayerProperties,
  MapController? mapController,
}) async {
  File file = File.fromRawPath(list);
  var string = await file.readAsString();
  return _string(
    string,
    layerMap: layerProperties,
    markerPropertie: markerLayerProperties,
    mapController: mapController,
  );
}

Future<List<Marker>> _assetMarkers(
  String path, {
  Map<LayerMarkerIndexes, String>? layerProperties,
  required MarkerProperties markerProperties,
  MapController? mapController,
}) async {
  final string = await rootBundle.loadString(path);
  await _createFile();
  return _string(
    string,
    layerMap: layerProperties,
    markerPropertie: markerProperties,
    mapController: mapController,
  );
}

Future<List<Marker>> _networkMarkers(
  Uri urlString, {
  Client? client,
  Map<String, String>? headers,
  Map<LayerMarkerIndexes, String>? layerProperties,
  required MarkerProperties markerLayerProperties,
  MapController? mapController,
}) async {
  var method = client == null ? get : client.get;
  var response = await method(urlString, headers: headers);
  var string = response.body;
  return _string(
    string,
    layerMap: layerProperties,
    markerPropertie: markerLayerProperties,
    mapController: mapController,
  );
}

List<Marker> _string(
  String string, {
  Map<LayerMarkerIndexes, String>? layerMap,
  required MarkerProperties markerPropertie,
  MapController? mapController,
}) {
  final geojson = GeoJSONFeatureCollection.fromMap(jsonDecode(string));

  List<List<Marker>> markers = geojson.features.map((elm) {
    if (elm != null) {
      var geometry = elm.geometry;
      var properties = elm.properties;
      var markerProperties = MarkerProperties.fromMap(
        properties,
        layerMap,
        markerLayerProperties: markerPropertie,
      );
      if (geometry is GeoJSONPoint) {
        return [geometry.coordinates.toMarker(markerProperties: markerProperties)];
      } else if (geometry is GeoJSONMultiPoint) {
        var coordinates = geometry.coordinates;
        return coordinates.map((e) {
          return e.toMarker(markerProperties: markerProperties);
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
    return [
      Marker(
        point: latlong2.LatLng(0, 0),
        builder: (BuildContext context) {
          return const SizedBox();
        },
      )
    ];
  }).toList();
  return markers.expand((element) => element).toList();
}

class GeoJSONMarkers {
  static Widget network(
    String url, {
    Client? client,
    Map<String, String>? headers,
    Map<LayerMarkerIndexes, String>? layerProperties,
    required MarkerProperties markerLayerProperties,
    MapController? mapController,
    Key? key,
    bool markerCulling = false,
    bool rotate = false,
    AlignmentGeometry? rotateAlignment = Alignment.center,
    Offset? rotateOrigin,
  }) {
    var uriString = url.toUri();
    return FutureBuilder(
      future: _networkMarkers(
        uriString,
        headers: headers,
        client: client,
        layerProperties: layerProperties,
        markerLayerProperties: markerLayerProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            return MarkerLayer(
              rotate: rotate,
              rotateAlignment: rotateAlignment,
              rotateOrigin: rotateOrigin,
              markers: snap.data ?? [],
              key: key,
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
    Map<LayerMarkerIndexes, String>? layerBufferProperties,
    required MarkerProperties markerProperties,
    MapController? mapController,
    BufferOptions? bufferOptions,
    Key? key,
    bool rotate = false,
    AlignmentGeometry? rotateAlignment = Alignment.center,
    Offset? rotateOrigin,
  }) {
    return FutureBuilder(
      future: _assetMarkers(
        url,
        layerProperties: layerBufferProperties,
        markerProperties: markerProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            var markers2 = snap.data ?? [];
            return bufferOptions == null
                ? MarkerLayer(
                    rotate: rotate,
                    rotateAlignment: rotateAlignment,
                    rotateOrigin: rotateOrigin,
                    markers: markers2,
                    key: key,
                  )
                : PolygonLayer(
                    polygons: markers2.toBuffers(bufferOptions.buffer),
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
    Map<LayerMarkerIndexes, String>? layerProperties,
    required MarkerProperties markerLayerProperties,
    MapController? mapController,
    Key? key,
    bool markerCulling = false,
    bool rotate = false,
    AlignmentGeometry? rotateAlignment = Alignment.center,
    Offset? rotateOrigin,
  }) {
    return FutureBuilder(
      future: _fileMarkers(
        path,
        layerProperties: layerProperties,
        markerLayerProperties: markerLayerProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            var data = snap.data ?? [];
            return MarkerLayer(
              rotate: rotate,
              rotateAlignment: rotateAlignment,
              rotateOrigin: rotateOrigin,
              markers: data,
              key: key,
            );
          }
        } else if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }

  static Widget memory(
    Uint8List bytes, {
    Map<LayerMarkerIndexes, String>? layerProperties,
    required MarkerProperties markerLayerProperties,
    MapController? mapController,
    Key? key,
    bool markerCulling = false,
    bool rotate = false,
    AlignmentGeometry? rotateAlignment = Alignment.center,
    Offset? rotateOrigin,
  }) {
    return FutureBuilder(
      future: _memoryMarkers(
        bytes,
        layerProperties: layerProperties,
        markerLayerProperties: markerLayerProperties,
        mapController: mapController,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            return MarkerLayer(
              rotate: rotate,
              rotateAlignment: rotateAlignment,
              rotateOrigin: rotateOrigin,
              markers: snap.data ?? [],
              key: key,
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
    Map<LayerMarkerIndexes, String>? layerProperties,
    required MarkerProperties markerLayerProperties,
    MapController? mapController,
    Key? key,
    bool markerCulling = false,
    bool rotate = false,
    AlignmentGeometry? rotateAlignment = Alignment.center,
    Offset? rotateOrigin,
  }) {
    return MarkerLayer(
      rotate: rotate,
      rotateAlignment: rotateAlignment,
      rotateOrigin: rotateOrigin,
      markers: _string(
        data,
        markerPropertie: markerLayerProperties,
      ),
      key: key,
    );
  }
}

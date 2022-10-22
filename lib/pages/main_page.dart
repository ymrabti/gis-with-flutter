import 'package:console_tools/console_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/markers/index.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/markers/properties.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:geoflutter/flutter_map_geojson/extensions/extensions.dart';
import 'package:geoflutter/flutter_map_geojson/extensions/polygon.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polyline/index.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polyline/properties.dart';
import 'package:geoflutter/pages/markers/index.dart';
import 'package:geoflutter/pages/polygons/asset.dart';
import 'package:geoflutter/pages/polygons/file.dart';
import 'package:geoflutter/pages/polygons/network.dart';
import 'package:geoflutter/pages/polygons/string.dart';
import 'package:geoflutter/utils/lists.dart';
import 'package:geoflutter/models/class.dart';
import '../settings/settings_view.dart';

/// Displays a list of SampleItems.
class GeojsonTestsPage extends StatefulWidget {
  const GeojsonTestsPage({
    super.key,
  });

  static const routeName = '/';

  @override
  State<GeojsonTestsPage> createState() => _GeojsonTestsPageState();
}

class _GeojsonTestsPageState extends State<GeojsonTestsPage> {
  var latLng = latlong2.LatLng(34.92849168609999, -2.3225879568537056);
  final MapController _mapController = MapController();
  final FlutterMapState mapState = FlutterMapState();
  bool start = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var interactiveFlags2 = InteractiveFlag.doubleTapZoom |
        InteractiveFlag.drag |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.pinchMove;
    var center = latlong2.LatLng(34.926447747065936, -2.3228343908943998);
    // double distanceMETERS = 10;
    // var distanceDMS = dmFromMeters(distanceMETERS);
    var baseUrl = "https://server.arcgisonline.com/ArcGIS/rest/services";
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: center,
          zoom: 11,
          interactiveFlags: interactiveFlags2,
          onMapReady: () async {
            await Future.delayed(const Duration(seconds: 1));
            _mapController.state = mapState;
            start = true;
          },
        ),
        children: [
          TileLayer(urlTemplate: '$baseUrl/World_Street_Map/MapServer/tile/{z}/{y}/{x}'),

          /* FeatureLayer(
            options: FeatureLayerOptions(
              "https://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/Landscape_Trees/FeatureServer/0",
              "point",
            ),
            map: mapState,
            stream: esri(),
          ), */

          NetworkGeoJSONPolygon(mapController: _mapController),
          AssetGeoJSONPolygon(mapController: _mapController),
          StringGeoJSONPolygon(mapController: _mapController),
          FileGeoJSONPolygon(mapController: _mapController),

          GeoJSONPolylines.asset(
            'assets/lignesassets.geojson',
            bufferOptions: BufferOptions(
              buffer: 50,
              polygonBufferProperties: const PolygonProperties(
                borderStokeWidth: 0,
                fillColor: Color(0x8DF436AB),
              ),
            ),
            polylineProperties: const PolylineProperties(
              isDotted: false,
              borderStrokeWidth: 0,
              borderColor: Colors.red,
              strokeWidth: 3,
              color: Colors.transparent,
              gradientColors: Colors.primaries,
            ),
          ),
          GeoJSONMarkers.asset(
            'assets/points-assets.geojson',
            // bufferOptions: BufferOptions(buffer: 20),
            markerProperties: MarkerProperties(
              builder: (p0) {
                return const Icon(Icons.location_on, color: Colors.red);
              },
            ),
          ),
          GeoJSONMarkers.asset(
            'assets/multipoints-assets.geojson',
            layerBufferProperties: {},
            markerProperties: MarkerProperties(
              builder: (p0) {
                return const Icon(Icons.location_off, color: Colors.blue);
              },
            ),
          ),
          //   MarkerLayer(markers: getMarkers()),
          CircleLayer(circles: [
            CircleMarker(
              point: latLng,
              radius: 500,
              color: Colors.indigo.withOpacity(0.6),
              borderColor: Colors.black,
              borderStrokeWidth: 5,
              useRadiusInMeter: true,
            ),
          ]),
          const ClustersMarkers(),
        ],
      ),
    );
  }

  double recalc(DestinationDS distanceDMS) {
    const latlong2.Distance distanc = latlong2.Distance();
    final double m = distanc.as(
      latlong2.LengthUnit.Meter,
      latlong2.LatLng(0, 0),
      latlong2.LatLng(0, distanceDMS.dm),
    );
    return m;
  }

  Polygon getPolygon() {
    var polygon = ringsHoled.toPolygon(
      polygonProperties: PolygonProperties(
        fillColor: const Color(0xFF5E0365).withOpacity(0.5),
      ),
    );
    Console.log(polygon.isGeoPointInPolygon(latLng));
    Console.log(polygon.isIntersectedWithPoint(latLng), color: ConsoleColors.teal);
    return polygon;
  }

  Stream<void> esri() async* {
    await Future.delayed(const Duration(seconds: 1));
    yield 1;
  }
}

import 'package:flutter/material.dart';
import 'package:proj4dart/proj4dart.dart' as proj4dart;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart' as cluster;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:template_skeleton/flutter_map_arcgis/flutter_map_arcgis.dart';
import 'package:template_skeleton/flutter_map_geojson/extensions/extensions.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/index.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:template_skeleton/pages/polygons/asset.dart';
import 'package:template_skeleton/pages/polygons/file.dart';
import 'package:template_skeleton/pages/polygons/network.dart';
import 'package:template_skeleton/pages/polygons/string.dart';
import 'package:template_skeleton/utils/console.dart';
import 'package:template_skeleton/utils/lists.dart';
import 'package:template_skeleton/models/class.dart';
import '../settings/settings_view.dart';

/// Displays a list of SampleItems.
class SampleItemListView extends StatefulWidget {
  const SampleItemListView({
    super.key,
  });

  static const routeName = '/';

  @override
  State<SampleItemListView> createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  var latLng = latlong2.LatLng(34.92849168609999, -2.3225879568537056);
  final MapController _mapController = MapController();
  final FlutterMapState mapState = FlutterMapState();
  @override
  Widget build(BuildContext context) {
    var interactiveFlags2 = InteractiveFlag.doubleTapZoom |
        InteractiveFlag.drag |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.pinchMove;
    var center = latlong2.LatLng(34.926447747065936, -2.3228343908943998);
    // double distanceMETERS = 10;
    // var distanceDMS = dmFromMeters(distanceMETERS);
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
          onMapReady: () {},
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          // fLO(),

          NetworkGeoJSONPolygon(mapController: _mapController),
          FileGeoJSONPolygon(mapController: _mapController),
          AssetGeoJSONPolygon(mapController: _mapController),
          StringGeoJSONPolygon(mapController: _mapController),

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
          clusters(),
        ],
      ),
    );
  }

  FeatureLayerOptions fLO() {
    return FeatureLayerOptions(
      "https://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/Landscape_Trees/FeatureServer/0",
      "point",
    );
  }

  cluster.MarkerClusterLayerWidget clusters() {
    // CupertinoLocalizationAr();
    var markerClusterLayerWidget = cluster.MarkerClusterLayerWidget(
        options: cluster.MarkerClusterLayerOptions(
      maxClusterRadius: 45,
      polygonOptions: const cluster.PolygonOptions(),
      size: const Size(40, 40),
      anchor: AnchorPos.align(AnchorAlign.center),
      fitBoundsOptions: const FitBoundsOptions(
        padding: EdgeInsets.all(50),
        maxZoom: 15,
      ),
      markers: getMarkers(),
      builder: (context, markers) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF361EA1),
          ),
          child: Center(
            child: Text(
              markers.length.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    ));
    /* var popupMarkerLayerWidget = PopupMarkerLayerWidget(
      options: PopupMarkerLayerOptions(
        popupSnap: PopupSnap.markerBottom,
        markers: getMarkers(),
        markerRotate: false,
        onPopupEvent: (event, selectedMarkers) {
          Console.log(selectedMarkers, color: ConsoleColors.red);
        },
        popupBuilder: (context, marker) {
          return Container(
            width: 200,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0x88361EA1),
            ),
            child: Center(
              child: Text(
                marker.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    ); */
    return markerClusterLayerWidget;
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

  List<Marker> getMarkers() {
    var map = pointsWifi.map((e) {
      var geometry = e["geometry"];
      var latitude = geometry!["y"] ?? 0;
      var longitude = geometry["x"] ?? 0;
      return Marker(
        point: latlong2.LatLng(latitude, longitude),
        rotate: true,
        builder: ((context) {
          var indexOf = pointsWifi.indexOf(e);
          return Icon(
            Icons.wifi,
            color: indexOf == 20 ? Colors.red : Colors.black,
          );
        }),
      );
    }).toList();
    return map;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:template_skeleton/src/libs/extensions.dart';
import 'package:template_skeleton/src/libs/lists.dart';
import 'package:template_skeleton/src/libs/utils.dart';
import 'package:template_skeleton/src/models/class.dart';
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
  @override
  Widget build(BuildContext context) {
    var interactiveFlags2 = InteractiveFlag.doubleTapZoom |
        InteractiveFlag.drag |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.rotate;
    var center = latlong2.LatLng(34.926447747065936, -2.3228343908943998);
    double distanceMETERS = 10;
    var distanceDMS = dmFromMeters(distanceMETERS);
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
        options: MapOptions(
          center: center,
          zoom: 16,
          interactiveFlags: interactiveFlags2,
          onMapReady: () {},
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          PolygonLayer(
            polygons: getPolygon().toBuffer(20),
          ),
          //   MarkerLayer(markers: getMarkers()),
          CircleLayer(circles: [
            CircleMarker(
              point: center,
              radius: 5,
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

  MarkerClusterLayerWidget clusters() {
    // CupertinoLocalizationAr();
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 45,
        polygonOptions: const PolygonOptions(),
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
    return ringsHoled.toPolygon(
      color: const Color(0xFF5E0365).withOpacity(0.5),
    );
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

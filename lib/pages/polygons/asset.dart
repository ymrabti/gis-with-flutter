import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/index.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';

class AssetGeoJSONPolygon extends StatelessWidget {
  const AssetGeoJSONPolygon({
    Key? key,
    required MapController mapController,
  })  : _mapController = mapController,
        super(key: key);

  final MapController _mapController;

  @override
  Widget build(BuildContext context) {
    return GeoJSONPolygons.asset(
      "assets/geojson.json",
      polygonProperties: const PolygonProperties(
        isDotted: false,
        label: 'Asset',
        fillColor: Color(0xFFA29A0A),
        rotateLabel: true,
        labelStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black,
          shadows: [
            Shadow(blurRadius: 10, color: Colors.white),
          ],
          decoration: TextDecoration.underline,
        ),
        labeled: true,
      ),
      mapController: _mapController,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/index.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:template_skeleton/utils/lists.dart';

class StringGeoJSONPolygon extends StatelessWidget {
  const StringGeoJSONPolygon({
    Key? key,
    required MapController mapController,
  })  : _mapController = mapController,
        super(key: key);

  final MapController _mapController;

  @override
  Widget build(BuildContext context) {
    return GeoJSONPolygons.string(
      geojsonstring,
      polygonLayerProperties: const PolygonProperties(
        isDotted: false,
        fillColor: Color(0xFFA2210A),
        rotateLabel: true,
        label: 'String',
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

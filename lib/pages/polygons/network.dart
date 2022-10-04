import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/index.dart';
import 'package:template_skeleton/flutter_map_geojson/geojson2widget/polygon/properties.dart';

class NetworkGeoJSONPolygon extends StatelessWidget {
  const NetworkGeoJSONPolygon({
    Key? key,
    required MapController mapController,
  })  : _mapController = mapController,
        super(key: key);

  final MapController _mapController;

  @override
  Widget build(BuildContext context) {
    return GeoJSONPolygons.network(
      "https://ymrabti.github.io/undisclosed-tools/assets/geojson/polygons.json",
      layerProperties: {
        LayerPolygonIndexes.fillColor: 'COLOOR',
        LayerPolygonIndexes.label: 'ECO_NAME',
      },
      polygonLayerProperties: const PolygonProperties(
        isDotted: false,
        rotateLabel: true,
        fillColor: Color(0xFF17CD11),
        labelStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF830202),
          shadows: [
            Shadow(blurRadius: 10, color: Colors.white),
          ],
        ),
        labeled: true,
      ),
      mapController: _mapController,
    );
  }
}

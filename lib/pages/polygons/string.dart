import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/markers/properties.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polygon/index.dart';
import 'package:geoflutter/flutter_map_geojson/geojson2widget/polygon/properties.dart';
import 'package:geoflutter/utils/lists.dart';

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
      bufferOptions: BufferOptions(
        buffer: 700,
        // buffersOnly: true,
        polygonBufferProperties: PolygonProperties(
          fillColor: const Color(0xFF54A805).withOpacity(0.5),
          borderStokeWidth: 0.3,
          label: 'Buffer',
          isDotted: false,
          borderColor: Colors.green,
        ),
      ),
      polygonProperties: const PolygonProperties(
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

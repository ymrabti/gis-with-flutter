import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:template_skeleton/flutter_map_geojson/extensions/extensions.dart';

enum LayerPolylineIndexes {
  fillColor,
  label,
  borderStokeWidth,
  borderColor,
}

class PolylineProperties {
  static const defFillColor = Color(0x9C2195F3);
  static const bool defDisableHolesBorder = true;
  static const bool defIsFilled = true;
  static const String defLabel = '';
  static const double defBorderStokeWidth = 2;
  static const Color defBorderColor = Color(0xFF1E00FD);
  final Color fillColor;
  final String label;
  final double borderStokeWidth;
  final Color borderColor;
  final bool isFilled;
  final bool disableHolesBorder;
  static const bool defLabeled = false;
  static const bool defIsDotted = false;
  static const TextStyle defLabelStyle = TextStyle();
  static const bool defRotateLabel = false;
  static const StrokeCap defStrokeCap = StrokeCap.round;
  static const StrokeJoin defStrokeJoin = StrokeJoin.round;
  final bool labeled;
  final bool isDotted;
  final TextStyle labelStyle;
  final bool rotateLabel;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  static const List<double> defColorsStop = [];
  final List<double> colorsStop;

  static const List<Color> defGradientColors = [];
  final List<Color> gradientColors;

  static const double defStrokeWidth = 1;
  final double strokeWidth;

  const PolylineProperties({
    this.colorsStop = PolylineProperties.defColorsStop,
    this.gradientColors = PolylineProperties.defGradientColors,
    this.strokeWidth = PolylineProperties.defStrokeWidth,
    this.labeled = PolylineProperties.defLabeled,
    this.isDotted = PolylineProperties.defIsDotted,
    this.labelStyle = PolylineProperties.defLabelStyle,
    this.rotateLabel = PolylineProperties.defRotateLabel,
    this.strokeCap = PolylineProperties.defStrokeCap,
    this.strokeJoin = PolylineProperties.defStrokeJoin,
    this.fillColor = PolylineProperties.defFillColor,
    this.label = PolylineProperties.defLabel,
    this.borderStokeWidth = PolylineProperties.defBorderStokeWidth,
    this.borderColor = PolylineProperties.defBorderColor,
    this.disableHolesBorder = PolylineProperties.defDisableHolesBorder,
    this.isFilled = PolylineProperties.defIsFilled,
  });
  static PolylineProperties fromMap(
    Map<String, dynamic>? properties,
    Map<LayerPolylineIndexes, String>? layerProperties, {
    PolylineProperties polylineLayerProperties = const PolylineProperties(),
  }) {
    if (properties != null && layerProperties != null) {
      // fill
      final String? layerPropertieFillColor = layerProperties[LayerPolylineIndexes.fillColor];
      var isFilledMap = layerPropertieFillColor != null;
      String hexString = '${properties[layerPropertieFillColor]}';
      final Color fillColor = HexColor.fromHex(hexString, polylineLayerProperties.fillColor);
      // border color
      final String? layerPropertieBorderColor = layerProperties[LayerPolylineIndexes.borderColor];
      String hexString2 = '${properties[layerPropertieBorderColor]}';
      var fall = polylineLayerProperties.borderColor;
      final Color borderColor = HexColor.fromHex(hexString2, fall);
      // border width
      var layerPropertieBWidth = layerProperties[LayerPolylineIndexes.borderStokeWidth];
      var defBorderStokeWidth = polylineLayerProperties.borderStokeWidth;
      var source = '$layerPropertieBWidth';
      final double borderWidth = double.tryParse(source) ?? defBorderStokeWidth;
      // label
      final String? label = layerProperties[LayerPolylineIndexes.label];
      final bool labeled = properties[label] != null;
      var isLabelled = labeled && polylineLayerProperties.labeled;
      String label2 = labeled ? '${properties[label]}' : polylineLayerProperties.label;
      return PolylineProperties(
        isFilled: isFilledMap && polylineLayerProperties.isFilled,
        fillColor: fillColor,
        borderColor: borderColor,
        colorsStop: polylineLayerProperties.colorsStop,
        gradientColors: polylineLayerProperties.gradientColors,
        strokeWidth: borderWidth,
        borderStokeWidth: polylineLayerProperties.borderStokeWidth,
        label: label2,
        labeled: isLabelled,
        disableHolesBorder: polylineLayerProperties.disableHolesBorder,
        isDotted: polylineLayerProperties.isDotted,
        labelStyle: polylineLayerProperties.labelStyle,
        rotateLabel: polylineLayerProperties.rotateLabel,
        strokeCap: polylineLayerProperties.strokeCap,
        strokeJoin: polylineLayerProperties.strokeJoin,
      );
    } else {
      return polylineLayerProperties;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:template_skeleton/src/libs/extensions.dart';

enum LayerPolygonProperties {
  fillColor,
  label,
  borderStokeWidth,
  borderColor,
}

class ExtraLayerPolygonProperties {
  static const bool defLabeled = false;

  static const bool defIsDotted = false;
  static const PolygonLabelPlacement defLabelPlacement = PolygonLabelPlacement.polylabel;
  static const TextStyle defLabelStyle = TextStyle();
  static const bool defRotateLabel = false;
  static const StrokeCap defStrokeCap = StrokeCap.round;
  static const StrokeJoin defStrokeJoin = StrokeJoin.round;
  final bool labeled;
  final bool isDotted;
  final PolygonLabelPlacement labelPlacement;
  final TextStyle labelStyle;
  final bool rotateLabel;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  const ExtraLayerPolygonProperties({
    this.labeled = ExtraLayerPolygonProperties.defLabeled,
    this.isDotted = ExtraLayerPolygonProperties.defIsDotted,
    this.labelPlacement = ExtraLayerPolygonProperties.defLabelPlacement,
    this.labelStyle = ExtraLayerPolygonProperties.defLabelStyle,
    this.rotateLabel = ExtraLayerPolygonProperties.defRotateLabel,
    this.strokeCap = ExtraLayerPolygonProperties.defStrokeCap,
    this.strokeJoin = ExtraLayerPolygonProperties.defStrokeJoin,
  });
}

class PolygonProperties {
  static const defFillColor = Color(0x9C2195F3);
  static const bool defDisableHolesBorder = true;
  static const bool defIsFilled = true;
  static const String defLabel = '';
  static const double defBorderStokeWidth = 2;
  static const Color defBorderColor = Color(0xFF1E00FD);
  static const ExtraLayerPolygonProperties defExtraLayerPolygonProperties =
      ExtraLayerPolygonProperties();
  final Color fillColor;
  final String label;
  final double borderStokeWidth;
  final Color borderColor;
  final bool isFilled;
  final bool disableHolesBorder;
  final ExtraLayerPolygonProperties extraLayerPolygonProperties;

  const PolygonProperties({
    this.fillColor = PolygonProperties.defFillColor,
    this.label = PolygonProperties.defLabel,
    this.borderStokeWidth = PolygonProperties.defBorderStokeWidth,
    this.borderColor = PolygonProperties.defBorderColor,
    this.disableHolesBorder = PolygonProperties.defDisableHolesBorder,
    this.isFilled = PolygonProperties.defIsFilled,
    this.extraLayerPolygonProperties = PolygonProperties.defExtraLayerPolygonProperties,
  });
  static PolygonProperties fromMap(
    Map<String, dynamic>? properties,
    Map<LayerPolygonProperties, String>? layerProperties, {
    ExtraLayerPolygonProperties extraLayerPolygonProperties = const ExtraLayerPolygonProperties(),
  }) {
    if (properties != null && layerProperties != null) {
      // fill
      final String? layerPropertieFillColor = layerProperties[LayerPolygonProperties.fillColor];
      var isFilled = layerPropertieFillColor != null;
      String hexString = '${properties[layerPropertieFillColor]}';
      final Color fillColor =
          isFilled ? HexColor.fromHex(hexString) : PolygonProperties.defFillColor;
      // border
      final String? layerPropertieBorderColor = layerProperties[LayerPolygonProperties.borderColor];
      var border = layerPropertieBorderColor == null;
      var layerPropertieBWidth = layerProperties[LayerPolygonProperties.borderStokeWidth];
      var defBorderStokeWidth = PolygonProperties.defBorderStokeWidth;
      var source = '$layerPropertieBWidth';
      final double layerPropertieBorderWidth = double.tryParse(source) ?? defBorderStokeWidth;
      String hexString2 = '${properties[layerPropertieBorderColor]}';
      var defBorderColor = PolygonProperties.defBorderColor;
      final Color borderColor = border ? defBorderColor : HexColor.fromHex(hexString2);
      // label
      final String? label = layerProperties[LayerPolygonProperties.label];
      final bool labeled = label != null;
      String? label2 = labeled && extraLayerPolygonProperties.labeled ? properties[label] : '';
      return PolygonProperties(
        isFilled: isFilled,
        fillColor: fillColor,
        borderColor: borderColor,
        borderStokeWidth: layerPropertieBorderWidth,
        label: label2 ?? '',
        extraLayerPolygonProperties: extraLayerPolygonProperties,
      );
    } else {
      return const PolygonProperties();
    }
  }
}

// Map<String, String> getProperties(Map<EnumPolygonProperties, String> layerProperties) {}

//   static const bool defLabeled = false;
//   static const bool defIsDotted = false;
//   static const PolygonLabelPlacement defLabelPlacement = PolygonLabelPlacement.polylabel;
//   static const TextStyle defLabelStyle = TextStyle();
//   static const bool defRotateLabel = false;
//   static const StrokeCap defStrokeCap = StrokeCap.round;
//   static const StrokeJoin defStrokeJoin = StrokeJoin.round;
//   final bool labeled;
//   final bool isDotted;
//   final PolygonLabelPlacement labelPlacement;
//   final TextStyle labelStyle;
//   final bool rotateLabel;
//   final StrokeCap strokeCap;
//   final StrokeJoin strokeJoin;
    // this.labeled = PolygonProperties.defLabeled,
    // this.isDotted = PolygonProperties.defIsDotted,
    // this.labelPlacement = PolygonProperties.defLabelPlacement,
    // this.labelStyle = PolygonProperties.defLabelStyle,
    // this.rotateLabel = PolygonProperties.defRotateLabel,
    // this.strokeCap = PolygonProperties.defStrokeCap,
    // this.strokeJoin = PolygonProperties.defStrokeJoin,
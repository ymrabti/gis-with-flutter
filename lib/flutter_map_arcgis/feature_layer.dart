import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:template_skeleton/flutter_map_arcgis/util.dart';
import 'package:template_skeleton/flutter_map_geojson/extensions/extensions.dart';
import 'package:template_skeleton/utils/console.dart';
import 'feature_layer_options.dart';
import 'package:tuple/tuple.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:async';

class FeatureLayer extends StatefulWidget {
  final FeatureLayerOptions options;
  final FlutterMapState map;
  final Stream stream;

  const FeatureLayer(this.options, this.map, this.stream, {super.key});

  @override
  State<StatefulWidget> createState() => _FeatureLayerState();
}

class _FeatureLayerState extends State<FeatureLayer> {
  List<dynamic> featuresPre = <dynamic>[];
  List<dynamic> features = <dynamic>[];

  StreamSubscription? _moveSub;

  var timer = Timer(const Duration(milliseconds: 100), () => {});

  bool isMoving = false;

  final Map<String, Tile> _tiles = {};
  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;
  double? _tileZoom;

  Bounds? _globalTileRange;
  LatLngBounds? currentBounds;
  int activeRequests = 0;
  int targetRequests = 0;

  @override
  initState() {
    super.initState();
    _resetView();
    _moveSub = widget.stream.listen((_) => _handleMove());
  }

  @override
  void dispose() {
    super.dispose();
    featuresPre = <dynamic>[];
    features = <dynamic>[];
    _moveSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.geometryType == "point") {
      return StreamBuilder<void>(
        stream: widget.stream,
        builder: (BuildContext context, _) {
          return _buildMarkers(context);
        },
      );
    } else if (widget.options.geometryType == "polyline") {
      return StreamBuilder<void>(
        stream: widget.stream,
        builder: (BuildContext context, _) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints bc) {
              final size = Size(bc.maxWidth, bc.maxHeight);
              return _buildPoygonLines(context, size);
            },
          );
        },
      );
    } else {
      return StreamBuilder<void>(
        stream: widget.stream,
        builder: (BuildContext context, _) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints bc) {
              final size = Size(bc.maxWidth, bc.maxHeight);
              return _buildPoygons(context, size);
            },
          );
        },
      );
    }
  }

  void _handleMove() {
    setState(() {
      if (isMoving) {
        timer.cancel();
      }

      isMoving = true;
      timer = Timer(const Duration(milliseconds: 200), () {
        isMoving = false;
        _resetView();
      });
    });
  }

  void _resetView() async {
    LatLngBounds? mapBounds = widget.map.bounds;
    if (currentBounds == null) {
      await doResetView(mapBounds);
    } else {
      if (currentBounds!.southEast != mapBounds.southEast ||
          currentBounds!.southWest != mapBounds.southWest ||
          currentBounds!.northEast != mapBounds.northEast ||
          currentBounds!.northWest != mapBounds.northWest) {
        await doResetView(mapBounds);
      }
    }
  }

  void _setView(LatLng center, double zoom) {
    var tileZoom = _clampZoom(zoom.round().toDouble());
    if (_tileZoom != tileZoom) {
      _tileZoom = tileZoom;
    }
  }

  void _resetGrid() {
    var map = widget.map;
    var crs = map.options.crs;
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first =
          (map.project(LatLng(0.0, crs.wrapLng!.item1), tileZoom).x / 256.0).floor().toDouble();
      var second =
          (map.project(LatLng(0.0, crs.wrapLng!.item2), tileZoom).x / 256.0).ceil().toDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first =
          (map.project(LatLng(crs.wrapLat!.item1, 0.0), tileZoom).y / 256.0).floor().toDouble();
      var second =
          (map.project(LatLng(crs.wrapLat!.item2, 0.0), tileZoom).y / 256.0).ceil().toDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _findTapedPolygon(LatLng position) {
    for (var polygon in features) {
      var polygonx = polygon as PolygonEsri;
      var isInclude = polygonx.isGeoPointInsidePolygon(position);
      if (isInclude) {
        widget.options.onTap!(polygonx.attributes, position);
      } else {
        widget.options.onTap!(null, position);
      }
    }
  }

  Future genrateVirtualGrids() async {
    if (widget.options.geometryType == "point") {
      if (_tileZoom! <= 14) {
        var pixelBounds = _getTiledPixelBounds(widget.map.center);
        var tileRange = _pxBoundsToTileRange(pixelBounds);

        var queue = <Coords>[];

        for (var key in _tiles.keys) {
          var c = _tiles[key]!.coords;
          if (c.z != _tileZoom) {
            _tiles[key]!.current = false;
          }
        }

        for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
          for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
            var coords = Coords(i.toDouble(), j.toDouble());
            coords.z = _tileZoom!;

            if (!_isValidTile(coords)) {
              continue;
            }

            queue.add(coords);
          }
        }
        if (queue.isNotEmpty) {
          targetRequests = queue.length;
          activeRequests = 0;
          for (var i = 0; i < queue.length; i++) {
            var coordsNew = _wrapCoords(queue[i]);

            var bounds = coordsToBounds(coordsNew);
            await requestFeatures(bounds);
          }
        }
      } else {
        targetRequests = 1;
        activeRequests = 1;
        await requestFeatures(widget.map.bounds);
      }
    } else {
      targetRequests = 1;
      activeRequests = 1;
      await requestFeatures(widget.map.bounds);
    }
  }

  Future doResetView(LatLngBounds mapBounds) async {
    setState(() {
      featuresPre = <dynamic>[];
      currentBounds = mapBounds;
    });
    _setView(widget.map.center, widget.map.zoom);
    _resetGrid();
    await genrateVirtualGrids();
  }

  Future requestFeatures(LatLngBounds bounds) async {
    try {
      String bounds_ =
          '"xmin":${bounds.southWest!.longitude},"ymin":${bounds.southWest!.latitude},"xmax":${bounds.northEast!.longitude},"ymax":${bounds.northEast?.latitude}';

      String url =
          '${widget.options.url}/query?f=json&geometry={"spatialReference":{"wkid":4326},$bounds_}&maxRecordCountFactor=30&outFields=*&outSR=4326&returnExceededLimitFeatures=true&spatialRel=esriSpatialRelIntersects&where=1=1&geometryType=esriGeometryEnvelope';

      Response response = await get(Uri.parse(url));

      Console.log(response);

      var features_ = <dynamic>[];

      var body = response.body;

      var jsonData = jsonDecode(body) as Map<String, dynamic>;

      if (jsonData["features"] != null) {
        for (var feature in jsonData["features"]) {
          if (widget.options.geometryType == "point") {
            var render = widget.options.render!(feature["attributes"]);

            if (render != null) {
              var latLng =
                  LatLng(feature["geometry"]["y"].toDouble(), feature["geometry"]["x"].toDouble());

              features_.add(Marker(
                width: render.width,
                height: render.height,
                point: latLng,
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    widget.options.onTap!(feature["attributes"], latLng);
                  },
                  child: render.builder,
                ),
              ));
            }
          } else if (widget.options.geometryType == "polygon") {
            for (var ring in feature["geometry"]["rings"]) {
              var points = <LatLng>[];

              for (var point_ in ring) {
                points.add(LatLng(point_[1].toDouble(), point_[0].toDouble()));
              }

              var render = widget.options.render!(feature["attributes"]);

              if (render != null) {
                features_.add(PolygonEsri(
                  markers: points,
                  borderStrokeSize: render.borderStrokeWidth,
                  coleur: render.coleur,
                  borderColeur: render.borderColor,
                  isdotted: render.isDotted,
                  isfilled: render.isfilled,
                  attributes: feature["attributes"],
                ));
              }
            }
          } else if (widget.options.geometryType == "polyline") {
            for (var ring in feature["geometry"]["paths"]) {
              var points = <LatLng>[];

              for (var point_ in ring) {
                points.add(LatLng(point_[1].toDouble(), point_[0].toDouble()));
              }

              var render = widget.options.render!(feature["attributes"]);

              if (render != null) {
                features_.add(PolyLineEsri(
                  markers: points,
                  coleur: render.borderStrokeWidth,
                  borderStrokeSize: render.coleur,
                  borderColeur: render.borderColor,
                  isdotted: render.isDotted,
                  attributes: feature["attributes"],
                ));
              }
            }
          }
        }

        activeRequests++;

        if (activeRequests >= targetRequests) {
          setState(() {
            features = [...featuresPre, ...features_];
            featuresPre = <Marker>[];
          });
        } else {
          setState(() {
            features = [...features, ...features_];
            featuresPre = [...featuresPre, ...features_];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = const CustomPoint(256.0, 256.0);
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    return widget.map.getPixelBounds(_tileZoom!);
  }

  LatLngBounds coordsToBounds(Coords coords) {
    var map = widget.map;
    var cellSize = 256.0;
    var nwPoint = coords.multiplyBy(cellSize);
    var sePoint = CustomPoint(nwPoint.x + cellSize, nwPoint.y + cellSize);
    var nw = map.unproject(nwPoint, coords.z.toDouble());
    var se = map.unproject(sePoint, coords.z.toDouble());
    return LatLngBounds(nw, se);
  }

  double _clampZoom(double zoom) {
    return zoom;
  }

  bool _boundsContainsMarker(Marker marker) {
    var pixelPoint = widget.map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  bool _isValidTile(Coords coords) {
    var crs = widget.map.options.crs;
    if (!crs.infinite) {
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null && (coords.x < bounds!.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null && (coords.y < bounds!.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }
    return true;
  }

  LatLng _offsetToCrs(Offset offset) {
    var renderObject = context.findRenderObject() as RenderBox;
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = widget.map.project(widget.map.center);
    var point = mapCenter - localPointCenterDistance;
    return widget.map.unproject(point);
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null ? wrapNum(coords.x.toDouble(), _wrapX!) : coords.x.toDouble(),
      _wrapY != null ? wrapNum(coords.y.toDouble(), _wrapY!) : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  CustomPoint _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  Widget _buildMarkers(BuildContext context) {
    var elements = <Widget>[];
    if (features.isNotEmpty) {
      for (var markerOpt in features) {
        if (markerOpt is! PolygonEsri) {
          var pos = widget.map.project(markerOpt.point);
          pos = pos.multiplyBy(widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
              widget.map.pixelOrigin;

          var pixelPosX = (pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();
          var pixelPosY = (pos.y - (markerOpt.height - markerOpt.anchor.top)).toDouble();

          if (!_boundsContainsMarker(markerOpt)) {
            continue;
          }

          elements.add(
            Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: pixelPosX,
              top: pixelPosY,
              child: markerOpt.builder(context),
            ),
          );
        }
      }
    }

    return Stack(
      children: elements,
    );
  }

  Widget _buildPoygons(BuildContext context, Size size) {
    var elements = <Widget>[];
    if (features.isNotEmpty) {
      for (var polygon in features) {
        if (polygon is PolygonEsri) {
          polygon.offseets.clear();
          var i = 0;

          for (var point in polygon.points) {
            var pos = widget.map.project(point);
            pos = pos.multiplyBy(widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
                widget.map.pixelOrigin;
            polygon.offseets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            if (i > 0 && i < polygon.points.length) {
              polygon.offseets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            }
            i++;
          }

          elements.add(
            GestureDetector(
              onTapUp: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                final offset = box.globalToLocal(details.globalPosition);

                var latLng = _offsetToCrs(offset);
                _findTapedPolygon(latLng);
              },
              child: CustomPaint(
                painter: PolygonPainter(polygon, 0),
                size: size,
              ),
            ),
          );
        }
      }
    }

    return Stack(
      children: elements,
    );
  }

  Widget _buildPoygonLines(BuildContext context, Size size) {
    var elements = <Widget>[];

    if (features.isNotEmpty) {
      for (var polyLine in features) {
        if (polyLine is PolyLineEsri) {
          polyLine.offsets.clear();
          var i = 0;

          for (var point in polyLine.points) {
            var pos = widget.map.project(point);
            pos = pos.multiplyBy(widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
                widget.map.pixelOrigin;
            polyLine.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            if (i > 0 && i < polyLine.points.length) {
              polyLine.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            }
            i++;
          }

          elements.add(
            GestureDetector(
                onTapUp: (details) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  final offset = box.globalToLocal(details.globalPosition);

                  var latLng = _offsetToCrs(offset);
                  _findTapedPolygon(latLng);
                },
                child: CustomPaint(
                  painter: PolylinePainter(polyLine, false),
                  size: size,
                )),
          );
        }
      }
    }

    return Stack(
      children: elements,
    );
  }
}

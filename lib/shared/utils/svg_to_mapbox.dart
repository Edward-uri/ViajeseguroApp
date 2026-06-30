import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector_graphics/vector_graphics.dart' as vg;

/// Carga un SVG como imagen de estilo en el mapa Mapbox.
///
/// Renderiza el SVG a bytes RGBA y lo registra con [imageId] en el estilo del mapa.
/// Después se puede usar en `PointAnnotationOptions(iconImage: imageId)`.
Future<void> addSvgPinToMap(
  MapboxMap map,
  String imageId,
  String svgAssetPath, {
  int width = 30,
  int height = 36,
}) async {
  try {
    final svgString = await rootBundle.loadString(svgAssetPath);

    // Parse SVG → PictureInfo usando vg.loadPicture (vector_graphics)
    final loader = SvgStringLoader(svgString);
    final pictureInfo = await vg.vg.loadPicture(loader, null);

    // Renderizar Picture → ui.Image → RGBA bytes
    final image = await pictureInfo.picture.toImage(width, height);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      debugPrint('[SvgToMapbox] toByteData returned null for $imageId');
      return;
    }

    final rgbaBytes = byteData.buffer.asUint8List();

    // Registrar como imagen de estilo en Mapbox
    await map.style.addStyleImage(
      imageId,
      1.0,
      MbxImage(width: width, height: height, data: rgbaBytes),
      false,
      const <ImageStretches?>[],
      const <ImageStretches?>[],
      null,
    );
  } catch (e) {
    debugPrint('[SvgToMapbox] Error cargando $imageId: $e');
  }
}

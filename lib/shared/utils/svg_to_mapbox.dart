import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
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
      if (kDebugMode) debugPrint('[SvgToMapbox] toByteData returned null for $imageId');
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
    if (kDebugMode) debugPrint('[SvgToMapbox] Error cargando $imageId: $e');
  }
}

/// Factor de nitidez de los pines PNG: se registran a width*height lógicos
/// por [_pinScale] píxeles reales y con ese mismo `scale` en addStyleImage,
/// así Mapbox los dibuja al tamaño declarado pero nítidos en pantallas 2x-3x
/// (en iOS es el scale de UIImage; en Android el pixelRatio del core).
const int _pinScale = 2;

/// Carga un PNG como imagen de estilo en el mapa Mapbox.
///
/// Lee el PNG desde assets, lo redimensiona a [width]x[height] lógicos y lo
/// registra con [imageId] en el estilo del mapa. Después se puede usar en
/// `PointAnnotationOptions(iconImage: imageId)`.
///
/// Devuelve `true` si la imagen quedó registrada; `false` si falló (en ese
/// caso el caller NO debe marcar su flag de pines cargados).
Future<bool> addPngPinToMap(
  MapboxMap map,
  String imageId,
  String pngAssetPath, {
  int width = 30,
  int height = 36,
}) async {
  try {
    final data = await rootBundle.load(pngAssetPath);
    final bytes = data.buffer.asUint8List();

    // Decodificar y redimensionar ANTES de registrar: Android decodifica el
    // PNG a su tamaño real pero construye la imagen nativa con el
    // width/height declarados; si no coinciden, addStyleImage falla y el
    // marcador queda invisible.
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width * _pinScale,
      targetHeight: height * _pinScale,
    );
    final frame = await codec.getNextFrame();
    final resized =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (resized == null) {
      if (kDebugMode) debugPrint('[PngToMapbox] toByteData null para $imageId');
      return false;
    }

    await map.style.addStyleImage(
      imageId,
      _pinScale.toDouble(),
      MbxImage(
        width: width * _pinScale,
        height: height * _pinScale,
        data: resized.buffer.asUint8List(),
      ),
      false,
      const <ImageStretches?>[],
      const <ImageStretches?>[],
      null,
    );
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[PngToMapbox] Error cargando $imageId: $e');
    return false;
  }
}

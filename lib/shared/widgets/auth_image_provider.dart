import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/http/api_client.dart';
import '../../core/routes/api_routes.dart';

class AuthImageProvider extends ImageProvider<AuthImageProvider> {
  AuthImageProvider({
    required this.userId,
    required this.apiClient,
  });

  final int userId;
  final ApiClient apiClient;

  @override
  Future<AuthImageProvider> obtainKey(ImageConfiguration configuration) async {
    return this;
  }

  @override
  ImageStreamCompleter loadImage(
    AuthImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      scale: 1.0,
      // Reintenta ante fallos transitorios (red intermitente o token aún no
      // disponible en el primer frame). Sin esto, un fallo puntual quedaba
      // cacheado por el Image y la foto "a veces no se mostraba" todo el viaje.
      // El 404 (usuario sin foto) es definitivo: cae al fallback sin reintentar.
      codec: () async {
        final url = '${apiClient.baseUrl}${ApiRoutes.usersPhoto(userId)}';
        for (var intento = 0; ; intento++) {
          final ultimo = intento >= 2;
          int? status;
          try {
            final token = apiClient.currentToken;
            final request = http.Request('GET', Uri.parse(url));
            request.headers['Accept'] = 'image/*';
            if (token != null) {
              request.headers['Authorization'] = 'Bearer $token';
            }
            final response = await http.Client().send(request);
            status = response.statusCode;
            if (status == 200) {
              final bytes = await response.stream.toBytes();
              return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
            }
          } catch (_) {
            if (ultimo) rethrow;
          }
          if (status == 404 || ultimo) {
            throw Exception('No se pudo cargar imagen (status: $status)');
          }
          await Future.delayed(Duration(milliseconds: 250 * (intento + 1)));
        }
      }(),
      informationCollector: () => [
        ErrorDescription('Image provider for user $userId'),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthImageProvider &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

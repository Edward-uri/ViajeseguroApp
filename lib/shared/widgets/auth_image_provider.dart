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
      codec: () async {
        final url = '${apiClient.baseUrl}${ApiRoutes.usersPhoto(userId)}';

        Future<http.StreamedResponse> fetch(String? token) {
          final request = http.Request('GET', Uri.parse(url));
          request.headers['Accept'] = 'image/*';
          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          return http.Client().send(request);
        }

        // En arranque en frio `currentToken` es null hasta la primera peticion
        // autenticada; leerlo del storage garantiza que la (unica) resolucion
        // de esta imagen salga siempre autenticada. Si el token expiro, se
        // refresca una vez y se reintenta.
        var response = await fetch(await apiClient.ensureToken());
        if (response.statusCode == 401 && await apiClient.refreshSession()) {
          response = await fetch(apiClient.currentToken);
        }
        if (response.statusCode != 200) {
          throw Exception('Error ${response.statusCode} al cargar imagen');
        }

        final bytes = await response.stream.toBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
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

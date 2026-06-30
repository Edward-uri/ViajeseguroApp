import 'dart:async';

import '../http/api_exception.dart';

sealed class AppError {
  const AppError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class NetworkAppError extends AppError {
  const NetworkAppError({
    super.message = 'Sin conexion. Revisa tu internet e intenta de nuevo.',
  });
}

class TimeoutAppError extends AppError {
  const TimeoutAppError({
    super.message = 'La solicitud tardo demasiado. Intenta de nuevo.',
  });
}

class UnauthorizedAppError extends AppError {
  const UnauthorizedAppError({
    super.message = 'Tu sesion expiro. Inicia sesion de nuevo.',
  });
}

class ValidationAppError extends AppError {
  const ValidationAppError({
    required super.message,
    this.details,
  });

  final Object? details;
}

class ServerAppError extends AppError {
  const ServerAppError({
    super.message = 'Error del servidor. Intenta mas tarde.',
    super.statusCode,
  });
}

class NotFoundAppError extends AppError {
  const NotFoundAppError({
    super.message = 'No se encontro el recurso solicitado.',
  });
}

class ConflictAppError extends AppError {
  const ConflictAppError({
    super.message = 'Ya existe un registro con esos datos.',
  });
}

class UnknownAppError extends AppError {
  const UnknownAppError({
    super.message = 'Ocurrio un error inesperado. Intenta de nuevo.',
  });
}

class ErrorHandler {
  const ErrorHandler._();

  static AppError handle(Object error) {
    if (error is AppError) return error;
    if (error is ApiException) return _fromApiException(error);
    if (error is TimeoutException) return const TimeoutAppError();
    if (error is FormatException) {
      return const UnknownAppError(
        message: 'Error al procesar la respuesta del servidor.',
      );
    }
    return const UnknownAppError();
  }

  static AppError _fromApiException(ApiException e) {
    return switch (e) {
      UnauthorizedException() => const UnauthorizedAppError(),
      ValidationException() => ValidationAppError(
        message: e.message,
        details: e.details,
      ),
      NetworkException() => NetworkAppError(message: e.message),
      ApiException() => _fromStatusCode(e.statusCode, e.message),
    };
  }

  static AppError _fromStatusCode(int? statusCode, String message) {
    if (message.isEmpty) {
      return switch (statusCode) {
        400 => const ValidationAppError(
          message: 'Datos invalidos. Revisa la informacion ingresada.',
        ),
        401 => const UnauthorizedAppError(),
        403 => const ServerAppError(
          message: 'No tienes permiso para realizar esta accion.',
        ),
        404 => const NotFoundAppError(),
        409 => const ConflictAppError(),
        500 => const ServerAppError(),
        _ => ServerAppError(
          message: 'Error del servidor ($statusCode).',
          statusCode: statusCode,
        ),
      };
    }
    return ServerAppError(message: message, statusCode: statusCode);
  }
}

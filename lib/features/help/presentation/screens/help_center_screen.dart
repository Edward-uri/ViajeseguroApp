import 'package:flutter/material.dart';

import '../../../../theme/jala_theme.dart';

/// Centro de ayuda: preguntas frecuentes sobre el uso de la app del pasajero.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  // (pregunta, respuesta). Contenido basado en el flujo real del pasajero.
  static const List<(String, String)> _faqs = [
    (
      '¿Como pido un viaje?',
      'En la pantalla principal toca la barra "A donde vas?", elige tu origen y '
          'destino (buscandolos, tocando "Usar mi ubicacion actual" o marcandolos '
          'en el mapa) e indica el numero de pasajeros. Toca "Estimar viaje", '
          'revisa la tarifa y confirma para solicitar un conductor.',
    ),
    (
      '¿Puedo enviar un paquete?',
      'Si. Al crear un viaje, en la parte superior del panel elige "Paquete" en '
          'lugar de "Viaje". Luego indica de donde se recoge y a donde se entrega, '
          'igual que en un viaje normal.',
    ),
    (
      '¿Como uso mi ubicacion actual?',
      'Al elegir el origen, toca "Usar mi ubicacion actual". La app detecta tu '
          'posicion y coloca automaticamente la direccion real del lugar donde '
          'estas.',
    ),
    (
      '¿Como se calcula la tarifa?',
      'La tarifa se estima segun la zona de destino y el numero de pasajeros '
          'antes de confirmar. Veras el monto en la tarjeta de estimacion y solo '
          'se solicita el viaje si aceptas ese precio.',
    ),
    (
      '¿Como pago el viaje?',
      'El pago es en efectivo, directamente con el conductor al finalizar el '
          'viaje.',
    ),
    (
      '¿Como sigo a mi conductor?',
      'Cuando un conductor acepta tu solicitud, veras su ubicacion en tiempo '
          'real en el mapa, junto con su nombre, su vehiculo y su placa.',
    ),
    (
      '¿Puedo cancelar un viaje?',
      'Si. Mientras buscas conductor o esperas a que llegue, puedes cancelar '
          'desde el boton de cancelar e indicar el motivo.',
    ),
    (
      '¿Como califico al conductor?',
      'Al completarse el viaje, la app te pedira calificar al conductor con '
          'estrellas y, si quieres, dejar un comentario.',
    ),
    (
      '¿Donde veo mis viajes anteriores?',
      'En la pestaña "Mis viajes" encontraras tu historial de viajes y envios, '
          'con la fecha, el estado y el monto de cada uno. Puedes filtrar por '
          '"Viajes" o "Paquetes".',
    ),
    (
      'No carga mi foto de perfil',
      'Verifica que tengas conexion a internet. Puedes ver o actualizar tu foto '
          'desde "Mi perfil". Si aun no aparece, cierra y vuelve a abrir la app.',
    ),
    (
      '¿Como administro las notificaciones?',
      'Desde el menu toca "Notificaciones" para abrir la configuracion del '
          'sistema, donde puedes activar o desactivar los avisos de la app.',
    ),
    (
      '¿Como cambio el tema o cierro sesion?',
      'En el menu puedes cambiar el tema (Claro, Oscuro o Sistema) en la opcion '
          '"Tema", y cerrar sesion con el boton "Cerrar sesion" al final.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Centro de ayuda'),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomPad),
        itemCount: _faqs.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
              child: Text(
                'Preguntas frecuentes sobre como usar la app.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.brand.greyDark,
                ),
              ),
            );
          }
          final faq = _faqs[index - 1];
          return _FaqTile(question: faq.$1, answer: faq.$2);
        },
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brand.divider),
      ),
      clipBehavior: Clip.antiAlias,
      // Quita las lineas divisorias que ExpansionTile dibuja arriba/abajo.
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: JalaBrand.amber,
          collapsedIconColor: context.brand.greyDark,
          title: Text(
            question,
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: context.text.bodyMedium?.copyWith(
                  color: context.brand.greyDark,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

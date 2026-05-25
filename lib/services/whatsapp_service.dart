import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class WhatsAppService {
  static Future<void> openForSingleTrade(
    BuildContext context, {
    required String phone,
    required String userName,
    required String neededNumber,
    required String offeredNumber,
  }) async {
    final message =
        "¡Hola $userName! Vi en 'La Repe' que tienes la lámina #$neededNumber que me falta "
        "y a ti te sirve mi repetida #$offeredNumber. ¿Te queda bien que nos veamos en el "
        "Cambiatón de Multicentro este domingo para cambiarlas? ⚽";
    await _launch(context, phone, message);
  }

  static Future<void> openForMultipleTrades(
    BuildContext context, {
    required String phone,
    required String userName,
    required List<String> neededIds,
    required List<String> offeredIds,
  }) async {
    String message = "¡Hola $userName! Vi en 'La Repe' que tenemos coincidencia de láminas. ";
    if (neededIds.isNotEmpty && offeredIds.isNotEmpty) {
      message += "Me sirven de tus repetidas: [${neededIds.join(', ')}] "
          "y a ti te sirven de las mías: [${offeredIds.join(', ')}]. ";
    } else if (neededIds.isNotEmpty) {
      message += "Me sirven de tus repetidas: [${neededIds.join(', ')}]. ";
    } else if (offeredIds.isNotEmpty) {
      message += "Te sirven de mis repetidas: [${offeredIds.join(', ')}]. ";
    }
    message += "¿Te queda bien que nos veamos en el Cambiatón de Multicentro este fin de semana? ⚽";
    await _launch(context, phone, message);
  }

  static Future<void> _launch(BuildContext context, String phone, String message) async {
    final url = "https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showError(context);
      }
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir WhatsApp')),
    );
  }
}

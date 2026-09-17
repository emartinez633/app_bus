import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  late IO.Socket _socket;

  // ¡IMPORTANTE!: Pon aquí la IP local de tu computadora con Nyarch Linux
  final String _serverUrl = 'http://192.168.1.24:3000';

  void connect() {
    // Configuramos el cliente
    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Evita fallos forzando WebSockets puros
        .disableAutoConnect() // Para controlar cuándo nos conectamos (útil para el Login)
        .build());

    // Iniciamos la conexión
    _socket.connect();

    // Escuchadores de estado
    _socket.onConnect((_) {
      debugPrint('✅ Conectado al backend de Node.js');
    });

    _socket.onDisconnect((_) {
      debugPrint('❌ Desconectado del backend');
    });

    _socket.onError((error) {
      debugPrint('⚠️ Error de WebSocket: $error');
    });
  }

  // Método de ejemplo para que el Chofer registre un cobro
  void emitirCobro(String tagId, String perfil) {
    _socket.emit('cobro_pasaje', {
      'nfc_id': tagId,
      'perfil': perfil, // ej. 'estudiante', 'tercera_edad', 'general'
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Método para cerrar la conexión al cerrar sesión
  void disconnect() {
    _socket.disconnect();
  }
}
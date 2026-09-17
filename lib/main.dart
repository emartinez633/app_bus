import 'package:flutter/material.dart';

// Importamos nuestras pantallas y servicios
import 'screens/chofer_screen.dart';
import 'screens/login_screen.dart';
import 'services/sync_worker_service.dart';
import 'services/socket_service.dart';

void main() async {
  // Es obligatorio llamar a esto si vamos a ejecutar código asíncrono
  // o inicializar plugins nativos antes de que arranque la interfaz gráfica.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializamos el monitor de red (Sincronización Offline -> Online)
  SyncWorkerService().iniciarMonitorDeRed();

  // 2. Conectamos los WebSockets para rastreo en tiempo real
  SocketService().connect();

  // Arrancamos la aplicación
  runApp(const MiAppFusionada());
}

class MiAppFusionada extends StatelessWidget {
  const MiAppFusionada({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Transport',
      theme: ThemeData(
        // Utilizamos un azul oscuro basado en el diseño original
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF09155B)),
        useMaterial3: true,
      ),
      // Definimos la pantalla del operador como la pantalla principal
      home: const LoginScreen(),
    );
  }
}
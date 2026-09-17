import 'package:flutter/material.dart';
import '../controllers/operador_controller.dart';

class ChoferScreen extends StatefulWidget {
  const ChoferScreen({super.key});

  @override
  State<ChoferScreen> createState() => _ChoferScreenState();
}

class _ChoferScreenState extends State<ChoferScreen> {
  // Instanciamos nuestro cerebro/controlador
  final OperadorController _controller = OperadorController();

  @override
  void initState() {
    super.initState();
    // Inicializamos el Text-to-Speech y otros recursos al abrir la pantalla
    _controller.init();
  }

  @override
  void dispose() {
    // Apagamos el lector NFC y limpiamos recursos si el chofer sale de la pantalla
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Operador'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      // ListenableBuilder conecta la UI con el OperadorController
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono visual que cambia de color si está escaneando
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _controller.isScanning 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.contactless_outlined, // Icono representativo de NFC/RFID
                      size: 100,
                      color: _controller.isScanning ? Colors.blue : Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Indicador de progreso circular girando si está activo
                  if (_controller.isScanning)
                    const CircularProgressIndicator(),
                  if (!_controller.isScanning)
                    const SizedBox(height: 36), // Mantiene el espacio visual
                  
                  const SizedBox(height: 30),
                  
                  // Mensaje de estado dinámico ("Procesando...", "Viaje cobrado", etc.)
                  Text(
                    _controller.statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Botones de acción para Iniciar y Detener el escáner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón Iniciar
                      ElevatedButton.icon(
                        // Si ya está escaneando, el botón se deshabilita (null)
                        onPressed: _controller.isScanning ? null : _controller.iniciarEscaneo,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Iniciar Lectura"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      
                      // Botón Detener
                      ElevatedButton.icon(
                        // Si NO está escaneando, el botón se deshabilita (null)
                        onPressed: _controller.isScanning ? _controller.detenerEscaneo : null,
                        icon: const Icon(Icons.stop),
                        label: const Text("Detener"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
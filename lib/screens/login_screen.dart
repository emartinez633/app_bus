import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chofer_screen.dart';
import 'usuario_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _esRegistro = false; // Alterna entre Login y Registro

  Future<void> _procesarFormulario() async {
    setState(() { _isLoading = true; });

    final correo = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor, ingresa correo y contraseña.', esError: true);
      setState(() { _isLoading = false; });
      return;
    }

    // Decidimos qué endpoint llamar según el modo
    final respuesta = _esRegistro 
        ? await _apiService.registro(correo, password)
        : await _apiService.login(correo, password);

    setState(() { _isLoading = false; });

    if (respuesta.containsKey('error')) {
      _mostrarMensaje(respuesta['error'], esError: true);
    } else {
      _mostrarMensaje(respuesta['mensaje'], esError: false);
      
      final usuario = respuesta['usuario'];
      if (usuario['rol'] == 'Chofer') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChoferScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UsuarioScreen(usuario: usuario)));
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: esError ? Colors.red : Colors.green),
    );
  }
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.directions_bus, size: 80, color: Color(0xFF09155B)),
              const SizedBox(height: 20),
              
              // ANIMACIÓN 1: Título
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _esRegistro ? 'Crear Cuenta' : 'Smart Transport',
                  key: ValueKey<bool>(_esRegistro), // La llave avisa que el valor cambió
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _esRegistro
                        ? const Color.fromARGB(255, 16, 91, 9)
                        : const Color(0xFF09155B),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              
              _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF09155B)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _esRegistro 
                      ? const Color.fromARGB(255, 16, 91, 9)
                      : const Color(0xFF09155B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _procesarFormulario,
                    // ANIMACIÓN 2: Texto del botón
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _esRegistro ? 'Registrarse' : 'Iniciar Sesión',
                        key: ValueKey<bool>(_esRegistro),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _esRegistro = !_esRegistro; 
                  });
                },
                // ANIMACIÓN 3: Texto de alternancia inferior
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _esRegistro ? '¿Ya tienes cuenta? Inicia sesión aquí' : '¿No tienes cuenta? Regístrate aquí',
                    key: ValueKey<bool>(_esRegistro),
                    style: const TextStyle(color: Color(0xFF09155B)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
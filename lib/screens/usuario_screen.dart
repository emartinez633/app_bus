import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';

class UsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario; 

  const UsuarioScreen({super.key, required this.usuario});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  late bool _lectorPantallaActivo;
  late bool _descuentoActivo;
  late double _saldoActual;

  final ApiService _apiService = ApiService();

  Future<void> _procesarRecarga(double monto) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Procesando recarga...'))
    );

    final respuesta = await _apiService.recargarSaldo(
      widget.usuario['correo'],
      monto,
    );

    if (respuesta.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['error']),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setState(() {
        _saldoActual = (respuesta['nuevoSaldo']).toDouble();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Recarga exitosa!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _mostrarFormularioEstudiante() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cargando catálogo de escuelas...'), duration: Duration(seconds: 1)),
    );
    
    final listaUniversidades = await _obtenerUniversidades();
    if (!mounted) return;

    final nombreCtrl = TextEditingController();
    final curpCtrl = TextEditingController();
    final matriculaCtrl = TextEditingController();
    String escuelaSeleccionada = ''; 
    String? errorValidacion; 

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Verificación de Estudiante'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorValidacion != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorValidacion!, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
                  TextField(
                    controller: curpCtrl, 
                    decoration: const InputDecoration(labelText: 'CURP', hintText: '18 caracteres'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textValue) {
                      if (textValue.text.isEmpty) return const Iterable<String>.empty();
                      return listaUniversidades.where((option) => 
                        option.toLowerCase().contains(textValue.text.toLowerCase())
                      );
                    },
                    onSelected: (String selection) { escuelaSeleccionada = selection; },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.addListener(() { escuelaSeleccionada = controller.text; });
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Institución Educativa'),
                      );
                    },
                  ),
                  
                  TextField(controller: matriculaCtrl, decoration: const InputDecoration(labelText: 'Número de Matrícula')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09155B)),
                onPressed: () {
                  if (nombreCtrl.text.isEmpty || escuelaSeleccionada.isEmpty || matriculaCtrl.text.isEmpty) {
                    setStateDialog(() => errorValidacion = 'Por favor, llena todos los campos.');
                    return;
                  }
                  if (!_esCurpValida(curpCtrl.text)) {
                    setStateDialog(() => errorValidacion = 'El formato de la CURP es incorrecto.');
                    return;
                  }
                  Navigator.pop(context, true); 
                },
                child: const Text('Enviar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );

    if (confirmar == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verificando datos...')));
      
      final respuesta = await _apiService.verificarEstudiante(
        widget.usuario['correo'], nombreCtrl.text, curpCtrl.text.toUpperCase(), escuelaSeleccionada, matriculaCtrl.text
      );

      if (respuesta.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(respuesta['error']), backgroundColor: Colors.red));
      } else {
        setState(() { _descuentoActivo = true; }); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Descuento activado con éxito!'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _iniciarEscaneoNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor enciende el NFC en los ajustes de tu teléfono'), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acerca tu celular a la etiqueta del autobús...', style: TextStyle(fontSize: 16)), backgroundColor: Color(0xFF09155B), duration: Duration(seconds: 5)),
    );

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693, NfcPollingOption.iso18092},
      onDiscovered: (NfcTag tag) async {
      NfcManager.instance.stopSession();
      
      final nfcData = tag.data;
      final tagId = nfcData.toString(); 
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando pago...')));

      final respuesta = await _apiService.registrarCobroNfc(widget.usuario['correo'], tagId);

      if (mounted) {
        if (respuesta.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(respuesta['error']), backgroundColor: Colors.red),
          );
        } else {
          setState(() { _saldoActual = (respuesta['nuevoSaldo']).toDouble(); });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Pago exitoso! Se descontaron \$${respuesta['tarifaCobrada']}'), backgroundColor: Colors.green),
          );
        }
      }
      },
    );
  }

  Future<List<String>> _obtenerUniversidades() async {
    try {
      final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=Mexico'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['name'].toString()).toSet().toList();
      }
    } catch (e) {
      debugPrint('Error API Universidades: $e');
    }
    return []; 
  }

  bool _esCurpValida(String curp) {
    RegExp regex = RegExp(
        r'^[A-Z]{1}[AEIOU]{1}[A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1])[HM]{1}(AS|BC|BS|CC|CS|CH|CL|CM|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z]{1}[0-9]{1}$');
    return regex.hasMatch(curp.toUpperCase());
  }

  @override
  void initState() {
    super.initState();
    _lectorPantallaActivo = true; 
    _descuentoActivo = widget.usuario['descuentoActivo'] ?? false;
    _saldoActual = (widget.usuario['saldo'] ?? 0).toDouble();
  }

  Future<void> _mostrarDialogoRecarga() async {
    final controlador = TextEditingController();

    final cantidad = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recargar saldo'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(
                controlador.text.trim().replaceAll(',', '.'),
              );
              if (valor != null && valor > 0) {
                Navigator.pop(context, valor);
              }
            },
            child: const Text('Recargar'),
          ),
        ],
      ),
    );

    controlador.dispose();
    if (cantidad != null && mounted) {
      _procesarRecarga(cantidad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.usuario['correo'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF09155B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Color(0xFF09155B)),
                  ),
                  content: const Text(
                    '¿Estás seguro de que deseas salir de tu cuenta?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false), 
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text(
                        'Salir',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmar == true && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Saldo y Recarga
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Saldo Disponible',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      '\$${_saldoActual.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09155B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                      label: const Text(
                        'Recargar Saldo',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        _mostrarDialogoRecarga();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // --- BOTÓN GIGANTE PARA PAGAR CON NFC ---
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi_tethering, size: 40, color: Colors.white),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('PAGAR PASAJE CON NFC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09155B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _iniciarEscaneoNFC,
            ),
            const SizedBox(height: 16),

            // Instrucciones
            const Text(
              'Acerca tu teléfono a una etiqueta NFC para:\n\n• Identificar tu parada actual\n• Abordar y ver info del autobús\n• Pagar tu pasaje',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const Spacer(),
            const Divider(),

            // Configuraciones de Perfil y Accesibilidad
            SwitchListTile(
              title: const Text('Lector de Pantalla (Voz)'),
              subtitle: const Text(
                'Asistencia para personas con debilidad visual',
              ),
              value: _lectorPantallaActivo,
              activeThumbColor: const Color(0xFF09155B),
              onChanged: (bool value) {
                setState(() {
                  _lectorPantallaActivo = value;
                });
              },
            ),
            _descuentoActivo
                ? SwitchListTile(
                    title: const Text('Perfil con Descuento'),
                    subtitle: const Text('Verificado: 50% de descuento activo'),
                    value: true,
                    activeColor: Colors.green,
                    onChanged: null, 
                  )
                : ListTile(
                    title: const Text('¿Eres estudiante?'),
                    subtitle: const Text(
                      'Toca aquí para validar tus datos y obtener 50% de descuento.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _mostrarFormularioEstudiante,
                  ),
          ],
        ),
      ),
    );
  }
}
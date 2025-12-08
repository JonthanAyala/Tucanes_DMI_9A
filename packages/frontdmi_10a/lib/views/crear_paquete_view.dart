import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/paquete_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/paquete_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';

// Vista de creación de paquete - Revamped
class CrearPaqueteView extends StatefulWidget {
  const CrearPaqueteView({super.key});

  @override
  State<CrearPaqueteView> createState() => _CrearPaqueteViewState();
}

class _CrearPaqueteViewState extends State<CrearPaqueteView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores Origen
  final _origenCalleController = TextEditingController();
  final _origenNumeroController = TextEditingController();
  final _origenCPController = TextEditingController();
  final _origenColoniaController = TextEditingController();
  final _origenMunicipioController = TextEditingController();
  final _origenEstadoController = TextEditingController();
  final _origenReferenciasController = TextEditingController();
  final _origenTelefonoController = TextEditingController();

  // Controladores Destino
  final _destinoCalleController = TextEditingController();
  final _destinoNumeroController = TextEditingController();
  final _destinoCPController = TextEditingController();
  final _destinoColoniaController = TextEditingController();
  final _destinoMunicipioController = TextEditingController();
  final _destinoEstadoController = TextEditingController();
  final _destinoReferenciasController = TextEditingController();
  final _destinoTelefonoController = TextEditingController();

  final _destinatarioController = TextEditingController();
  final _pesoController = TextEditingController();

  File? _foto;
  final ImagePicker _picker = ImagePicker();
  bool _obteniendoUbicacion = false;
  Position? _ubicacionActual;

  @override
  void dispose() {
    _origenCalleController.dispose();
    _origenNumeroController.dispose();
    _origenCPController.dispose();
    _origenColoniaController.dispose();
    _origenMunicipioController.dispose();
    _origenEstadoController.dispose();
    _origenReferenciasController.dispose();
    _origenTelefonoController.dispose();

    _destinoCalleController.dispose();
    _destinoNumeroController.dispose();
    _destinoCPController.dispose();
    _destinoColoniaController.dispose();
    _destinoMunicipioController.dispose();
    _destinoEstadoController.dispose();
    _destinoReferenciasController.dispose();
    _destinoTelefonoController.dispose();

    _destinatarioController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _foto = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar foto: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _usarUbicacionActual() async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      // Obtener ubicación
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _ubicacionActual = position;
        // Aquí podríamos usar geocoding inverso para llenar los campos de texto
        // si tuviéramos una API key de Google Maps o similar.
        // Por ahora solo guardamos las coordenadas y avisamos al usuario.
        _origenReferenciasController.text =
            "${_origenReferenciasController.text} [Ubicación GPS: ${position.latitude}, ${position.longitude}]"
                .trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación actual añadida'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }

  Future<void> _crearPaquete() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final paqueteViewModel = context.read<PaqueteViewModel>();
      final usuario = authViewModel.usuario;

      if (usuario == null) return;

      final origenMap = {
        'calle': _origenCalleController.text.trim(),
        'numero': _origenNumeroController.text.trim(),
        'cp': _origenCPController.text.trim(),
        'colonia': _origenColoniaController.text.trim(),
        'municipio': _origenMunicipioController.text.trim(),
        'estado': _origenEstadoController.text.trim(),
        'referencias': _origenReferenciasController.text.trim(),
        'telefono': _origenTelefonoController.text.trim(),
        'lat': _ubicacionActual?.latitude,
        'lng': _ubicacionActual?.longitude,
      };

      final destinoMap = {
        'calle': _destinoCalleController.text.trim(),
        'numero': _destinoNumeroController.text.trim(),
        'cp': _destinoCPController.text.trim(),
        'colonia': _destinoColoniaController.text.trim(),
        'municipio': _destinoMunicipioController.text.trim(),
        'estado': _destinoEstadoController.text.trim(),
        'referencias': _destinoReferenciasController.text.trim(),
        'telefono': _destinoTelefonoController.text.trim(),
      };

      final paquete = Paquete(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        destinatario: _destinatarioController.text.trim(),
        origen: origenMap,
        destino: destinoMap,
        peso: double.parse(_pesoController.text),
        estado: 'pendiente',
        fechaCreacion: DateTime.now(),
        clienteId: usuario.id,
      );

      final success = await paqueteViewModel.crearPaquete(paquete, _foto);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paquete creado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paqueteViewModel.errorMessage ?? 'Error al crear paquete',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nuevo Paquete'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto del paquete
              GestureDetector(
                onTap: () => _mostrarOpcionesFoto(),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _foto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_foto!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección Origen
              _buildSectionTitle('Origen (Recolección)'),
              const SizedBox(height: 16),

              CustomButton(
                text: 'Usar mi ubicación actual',
                onPressed: _usarUbicacionActual,
                icon: Icons.my_location,
                isLoading: _obteniendoUbicacion,
                backgroundColor: AppTheme.secondaryColor,
              ),
              const SizedBox(height: 16),

              _buildAddressFields(
                calleCtrl: _origenCalleController,
                numCtrl: _origenNumeroController,
                cpCtrl: _origenCPController,
                coloniaCtrl: _origenColoniaController,
                muniCtrl: _origenMunicipioController,
                edoCtrl: _origenEstadoController,
                refCtrl: _origenReferenciasController,
                telCtrl: _origenTelefonoController,
              ),

              const SizedBox(height: 24),

              // Sección Destino
              _buildSectionTitle('Destino (Entrega)'),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Nombre Destinatario',
                hint: 'Quién recibe',
                controller: _destinatarioController,
                validator: (value) =>
                    Validators.validateRequired(value, 'El destinatario'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),

              _buildAddressFields(
                calleCtrl: _destinoCalleController,
                numCtrl: _destinoNumeroController,
                cpCtrl: _destinoCPController,
                coloniaCtrl: _destinoColoniaController,
                muniCtrl: _destinoMunicipioController,
                edoCtrl: _destinoEstadoController,
                refCtrl: _destinoReferenciasController,
                telCtrl: _destinoTelefonoController,
              ),

              const SizedBox(height: 24),

              CustomTextField(
                label: 'Peso (kg)',
                hint: '0.0',
                controller: _pesoController,
                validator: Validators.validatePeso,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.scale,
              ),
              const SizedBox(height: 32),

              // Botón de crear
              Consumer<PaqueteViewModel>(
                builder: (context, viewModel, _) {
                  return CustomButton(
                    text: 'Crear Paquete',
                    onPressed: _crearPaquete,
                    isLoading: viewModel.isLoading,
                    icon: Icons.check,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Divider(color: AppTheme.primaryColor, thickness: 2),
      ],
    );
  }

  Widget _buildAddressFields({
    required TextEditingController calleCtrl,
    required TextEditingController numCtrl,
    required TextEditingController cpCtrl,
    required TextEditingController coloniaCtrl,
    required TextEditingController muniCtrl,
    required TextEditingController edoCtrl,
    required TextEditingController refCtrl,
    required TextEditingController telCtrl,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                label: 'Calle',
                hint: 'Av. Principal',
                controller: calleCtrl,
                validator: (v) => Validators.validateRequired(v, 'La calle'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: CustomTextField(
                label: 'Número',
                hint: '123',
                controller: numCtrl,
                validator: (v) => Validators.validateRequired(v, 'El número'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'C.P.',
                hint: '00000',
                controller: cpCtrl,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateRequired(v, 'El C.P.'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Colonia',
                hint: 'Centro',
                controller: coloniaCtrl,
                validator: (v) => Validators.validateRequired(v, 'La colonia'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Municipio',
                hint: 'Cuernavaca',
                controller: muniCtrl,
                validator: (v) =>
                    Validators.validateRequired(v, 'El municipio'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Estado',
                hint: 'Morelos',
                controller: edoCtrl,
                validator: (v) => Validators.validateRequired(v, 'El estado'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Teléfono Contacto',
          hint: '777 123 4567',
          controller: telCtrl,
          keyboardType: TextInputType.phone,
          validator: (v) => Validators.validateRequired(v, 'El teléfono'),
          prefixIcon: Icons.phone,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Referencias',
          hint: 'Fachada azul, portón negro...',
          controller: refCtrl,
          maxLines: 2,
        ),
      ],
    );
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.gallery);
                },
              ),
              if (_foto != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    setState(() {
                      _foto = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/paquete_model.dart';
import '../viewmodels/paquete_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

// Vista de edición de paquete - JonthanAyala
class EditarPaqueteView extends StatefulWidget {
  final Paquete paquete;

  const EditarPaqueteView({super.key, required this.paquete});

  @override
  State<EditarPaqueteView> createState() => _EditarPaqueteViewState();
}

class _EditarPaqueteViewState extends State<EditarPaqueteView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinatarioController;
  late TextEditingController _direccionController;
  late TextEditingController _pesoController;
  late String _estadoSeleccionado;
  File? _nuevaFoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _destinatarioController = TextEditingController(
      text: widget.paquete.destinatario,
    );
    _direccionController = TextEditingController(
      text:
          '${widget.paquete.destino['calle']} ${widget.paquete.destino['numero']}, ${widget.paquete.destino['colonia']}',
    );
    _pesoController = TextEditingController(
      text: widget.paquete.peso.toString(),
    );
    _estadoSeleccionado = widget.paquete.estado;
  }

  @override
  void dispose() {
    _destinatarioController.dispose();
    _direccionController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _nuevaFoto = File(image.path);
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

  Future<void> _actualizarPaquete() async {
    if (_formKey.currentState!.validate()) {
      final paqueteViewModel = context.read<PaqueteViewModel>();

      final nuevoDestino = Map<String, dynamic>.from(widget.paquete.destino);
      // Por ahora solo permitimos editar la calle principal desde este campo simple
      // Idealmente deberíamos tener todos los campos detallados aquí también
      nuevoDestino['calle'] = _direccionController.text.trim();

      final paqueteActualizado = widget.paquete.copyWith(
        destinatario: _destinatarioController.text.trim(),
        destino: nuevoDestino,
        estado: _estadoSeleccionado,
      );

      final success = await paqueteViewModel.actualizarPaquete(
        paqueteActualizado,
        _nuevaFoto,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paquete actualizado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paqueteViewModel.errorMessage ?? 'Error al actualizar',
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
        title: const Text('Editar Paquete'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto actual o nueva
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
                    ),
                  ),
                  child: _buildFotoPreview(),
                ),
              ),
              const SizedBox(height: 24),

              // Campos del formulario
              CustomTextField(
                label: 'Destinatario',
                hint: 'Nombre del destinatario',
                controller: _destinatarioController,
                validator: (value) =>
                    Validators.validateRequired(value, 'El destinatario'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Dirección',
                hint: 'Dirección de entrega',
                controller: _direccionController,
                validator: (value) =>
                    Validators.validateRequired(value, 'La dirección'),
                prefixIcon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Peso (kg)',
                hint: '0.0',
                controller: _pesoController,
                validator: Validators.validatePeso,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.scale,
              ),
              const SizedBox(height: 24),

              // Selector de estado
              const Text(
                'Estado del Paquete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildEstadoOption(
                AppConstants.estadoPendiente,
                'Pendiente',
                Icons.schedule,
              ),
              const SizedBox(height: 8),
              _buildEstadoOption(
                AppConstants.estadoEnTransito,
                'En Tránsito',
                Icons.local_shipping,
              ),
              const SizedBox(height: 8),
              _buildEstadoOption(
                AppConstants.estadoEntregado,
                'Entregado',
                Icons.check_circle,
              ),
              const SizedBox(height: 32),

              // Botón de actualizar
              Consumer<PaqueteViewModel>(
                builder: (context, viewModel, _) {
                  return CustomButton(
                    text: 'Actualizar Paquete',
                    onPressed: _actualizarPaquete,
                    isLoading: viewModel.isLoading,
                    icon: Icons.save,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para mostrar preview de foto (LOCAL o URL)
  Widget _buildFotoPreview() {
    if (_nuevaFoto != null) {
      // Nueva foto seleccionada
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_nuevaFoto!, fit: BoxFit.cover),
      );
    } else if (widget.paquete.fotoUrl != null) {
      // Foto existente (LOCAL o URL de Firebase)
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildImagen(widget.paquete.fotoUrl!),
      );
    } else {
      // Sin foto
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 8),
          Text(
            'Toca para cambiar foto',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      );
    }
  }

  // Método helper para mostrar imagen local o de red
  // NOTA: Actualmente muestra imágenes LOCALES (File)
  // Para URLs de Firebase Storage, descomentar Image.network
  Widget _buildImagen(String ruta) {
    // Si la ruta empieza con http, es una URL (Firebase Storage futuro)
    if (ruta.startsWith('http')) {
      // FIREBASE STORAGE (futuro)
      return Image.network(
        ruta,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          size: 48,
          color: AppTheme.textSecondary,
        ),
      );
    } else {
      // ALMACENAMIENTO LOCAL (actual)
      final file = File(ruta);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else {
        return const Icon(
          Icons.image_not_supported,
          size: 48,
          color: AppTheme.textSecondary,
        );
      }
    }
  }

  Widget _buildEstadoOption(String value, String label, IconData icon) {
    final isSelected = _estadoSeleccionado == value;

    return InkWell(
      onTap: () {
        setState(() {
          _estadoSeleccionado = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
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
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../models/usuario.dart';
import '../services/data_service.dart';
import '../widgets/avatar_widget.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  void _mostrarFormularioCrear(BuildContext context, DataService service) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _CrearPerfilSheet(service: service);
      },
    );
  }

  void _confirmarEliminar(
      BuildContext context, DataService service, Usuario usuario) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('¿Eliminar perfil?',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text(
              '¿Estás seguro de que quieres eliminar el perfil de ${usuario.nombre}? Se perderá todo su progreso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                service.eliminarUsuario(usuario.id);
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DataService>();
    final perfiles = service.usuarios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige tu perfil'),
        actions: [
          IconButton(
            tooltip: 'Panel de padres',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.parentPanel),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;

            if (perfiles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.supervised_user_circle_rounded,
                          size: 110,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¡Hola! Aún no hay perfiles',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Crea el primer perfil para guardar tus estrellas y cuentos leídos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _mostrarFormularioCrear(context, service),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Crear Perfil'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Quién va a leer hoy?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Elige tu perfil o crea uno nuevo para empezar a leer.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          itemCount: perfiles.length + 1,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 3 : 1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isTablet ? 1.35 : 2.2,
                          ),
                          itemBuilder: (context, index) {
                            if (index == perfiles.length) {
                              // Render modern dashed "+" Card to Create Profile
                              return InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () =>
                                    _mostrarFormularioCrear(context, service),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Nuevo perfil',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final usuario = perfiles[index];
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      service.seleccionarUsuario(usuario);
                                      Navigator.pushReplacementNamed(
                                          context, AppRoutes.home);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          AvatarWidget(
                                            avatar: usuario.avatar,
                                            nombre: usuario.nombre,
                                            size: isTablet ? 84 : 76,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  usuario.nombre,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${usuario.edad} años',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: 0.7),
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${usuario.cuentosLeidos} leídos · ${usuario.estrellasTotal} ★',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .amber.shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Mini Delete button on top right
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 20, color: Colors.red.shade300),
                                    onPressed: () => _confirmarEliminar(
                                        context, service, usuario),
                                    tooltip: 'Eliminar perfil',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CrearPerfilSheet extends StatefulWidget {
  final DataService service;

  const _CrearPerfilSheet({required this.service});

  @override
  State<_CrearPerfilSheet> createState() => _CrearPerfilSheetState();
}

class _CrearPerfilSheetState extends State<_CrearPerfilSheet> {
  final _nombreController = TextEditingController();
  double _edad = 6;
  String _avatarSeleccionado = '🦊';

  final List<String> _avatares = const [
    '🦊',
    '🐻',
    '🐼',
    '🦉',
    '🦁',
    '🐯',
    '🐸',
    '🐙',
    '🦄',
    '🦖',
    '🐨',
    '🦋'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _crear() {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre.')),
      );
      return;
    }
    widget.service.crearUsuario(
      nombre: nombre,
      edad: _edad.round(),
      avatar: _avatarSeleccionado,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Crear Nuevo Perfil',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Name Field
          TextField(
            controller: _nombreController,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del niño/a',
              hintText: 'Ej. Lucía',
              prefixIcon: Icon(Icons.face_rounded),
            ),
          ),
          const SizedBox(height: 16),
          // Age Selector
          Text(
            'Edad: ${_edad.round()} años',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            min: 3,
            max: 12,
            divisions: 9,
            value: _edad,
            label: '${_edad.round()} años',
            onChanged: (val) => setState(() => _edad = val),
          ),
          const SizedBox(height: 16),
          // Avatar Selector
          Text(
            'Elige un avatar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatares.map((emoji) {
              final seleccionado = emoji == _avatarSeleccionado;
              return InkWell(
                onTap: () => setState(() => _avatarSeleccionado = emoji),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.18)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seleccionado
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: seleccionado ? 2.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Submit Button
          ElevatedButton(
            onPressed: _crear,
            child: const Text('Crear Perfil'),
          ),
        ],
      ),
    );
  }
}

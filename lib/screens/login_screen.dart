import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../services/data_service.dart';
import '../widgets/app_chrome.dart';

enum _AuthMode { welcome, login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _AuthMode _mode = _AuthMode.welcome;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit(DataService service) {
    if (!_formKey.currentState!.validate()) return;
    final error = _mode == _AuthMode.register
        ? service.registrarTutor(
            nombre: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmController.text,
          )
        : service.iniciarSesionTutor(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DataService>();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final logoSize = compact ? 64.0 : 86.0;
            final heroHeight = compact ? 180.0 : 250.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    compact ? 10 : 18,
                    22,
                    24,
                  ),
                  child: Column(
                    children: [
                      LogoMark(size: logoSize),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                          children: [
                            TextSpan(
                              text: 'Lectura',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: 'Kids',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Lee hoy, imagina siempre.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.72),
                                ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/login_reader.png',
                          height: heroHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _mode == _AuthMode.welcome
                            ? _WelcomeActions(
                                key: const ValueKey('welcome'),
                                onParent: () {
                                  setState(() {
                                    _mode = service.cuentaTutor == null
                                        ? _AuthMode.register
                                        : _AuthMode.login;
                                  });
                                },
                                onChild: () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.profileSelection,
                                ),
                              )
                            : _AuthForm(
                                key: ValueKey(_mode),
                                mode: _mode,
                                formKey: _formKey,
                                nameController: _nameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                confirmController: _confirmController,
                                obscurePassword: _obscurePassword,
                                onTogglePassword: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onSubmit: () => _submit(service),
                                onSwitchMode: () {
                                  setState(() {
                                    _mode = _mode == _AuthMode.login
                                        ? _AuthMode.register
                                        : _AuthMode.login;
                                  });
                                },
                                onBack: () =>
                                    setState(() => _mode = _AuthMode.welcome),
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

class _WelcomeActions extends StatelessWidget {
  final VoidCallback onParent;
  final VoidCallback onChild;

  const _WelcomeActions({
    super.key,
    required this.onParent,
    required this.onChild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onParent,
          icon: const Icon(Icons.person_rounded),
          label: const Text('Soy padre, madre o tutor'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onChild,
          icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
          label: const Text('Soy niño o niña'),
        ),
        TextButton(
          onPressed: onParent,
          child: const Text('Registrarme'),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o continúa con',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundAuthIcon(
              icon: Icons.g_mobiledata_rounded,
              onTap: onParent,
              tooltip: 'Continuar con Google',
            ),
            const SizedBox(width: 18),
            _RoundAuthIcon(
              icon: Icons.mail_outline_rounded,
              onTap: onParent,
              tooltip: 'Continuar con correo',
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  final _AuthMode mode;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final VoidCallback onBack;

  const _AuthForm({
    super.key,
    required this.mode,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final registering = mode == _AuthMode.register;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Volver',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    registering ? 'Registrarme' : 'Iniciar sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (registering) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del tutor',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Nombre requerido'
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Correo válido requerido'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            if (registering) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmController,
                obscureText: obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Confirma contraseña'
                    : null,
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onSubmit,
              child: Text(registering ? 'Crear cuenta' : 'Entrar'),
            ),
            TextButton(
              onPressed: onSwitchMode,
              child: Text(
                registering
                    ? 'Ya tengo cuenta'
                    : 'No tengo cuenta, registrarme',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAuthIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _RoundAuthIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 32),
        ),
      ),
    );
  }
}

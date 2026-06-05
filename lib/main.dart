import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'models/cuento.dart';
import 'screens/activities_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parent_panel_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/reader_screen.dart';
import 'services/data_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LecturaKidsBootstrap());
}

class LecturaKidsBootstrap extends StatefulWidget {
  const LecturaKidsBootstrap({super.key});

  @override
  State<LecturaKidsBootstrap> createState() => _LecturaKidsBootstrapState();
}

class _LecturaKidsBootstrapState extends State<LecturaKidsBootstrap> {
  late final DataService _dataService;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _dataService = DataService();
    _initFuture = _dataService.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DataService>.value(
      value: _dataService,
      child: Consumer<DataService>(
        builder: (context, service, _) {
          return FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              final isReady =
                  snapshot.connectionState == ConnectionState.done &&
                      service.isReady;

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: _buildTheme(),
                darkTheme: _buildDarkTheme(),
                themeMode:
                    service.modoOscuro ? ThemeMode.dark : ThemeMode.light,
                home: isReady ? const LoginScreen() : const _BootScreen(),
                routes: {
                  AppRoutes.profileSelection: (_) =>
                      const ProfileSelectionScreen(),
                  AppRoutes.home: (_) => const HomeScreen(),
                  AppRoutes.library: (_) => const LibraryScreen(),
                  AppRoutes.parentPanel: (_) => const ParentPanelScreen(),
                },
                onGenerateRoute: (settings) {
                  if (settings.name == AppRoutes.reader) {
                    final arguments = settings.arguments;
                    if (arguments is! Cuento) {
                      return _fallbackRoute(settings);
                    }
                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => ReaderScreen(cuento: arguments),
                    );
                  }
                  if (settings.name == AppRoutes.activities) {
                    final arguments = settings.arguments;
                    if (arguments is! Cuento) {
                      return _fallbackRoute(settings);
                    }
                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => ActivitiesScreen(cuento: arguments),
                    );
                  }
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const LoginScreen(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  MaterialPageRoute<void> _fallbackRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const _RouteErrorScreen(),
    );
  }

  ThemeData _buildTheme() {
    const sky = Color(0xFF2EA8F2);
    const coral = Color(0xFFFF7A66);
    const mint = Color(0xFF4DBE8A);
    const page = Color(0xFFF7FBFF);
    const ink = Color(0xFF263238);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sky,
        primary: sky,
        secondary: coral,
        tertiary: mint,
        surface: Colors.white,
        brightness: Brightness.light,
      ).copyWith(
        surfaceContainerHighest: const Color(0xFFE9F5FD),
        outlineVariant: const Color(0xFFD9E8F2),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: page,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: sky.withValues(alpha: 0.18),
        disabledColor: const Color(0xFFE8EEF3),
        brightness: Brightness.light,
        labelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD9E8F2)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sky,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          textStyle: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFFD9E8F2)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink.withValues(alpha: 0.62),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sky, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9E8F2)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const sky = Color(0xFF54C7FF);
    const coral = Color(0xFFFF8A78);
    const mint = Color(0xFF7EE0B1);
    const darkBg = Color(0xFF14212A);
    const darkSurface = Color(0xFF1D2D37);
    const whiteText = Color(0xFFF5F5F5);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sky,
        primary: sky,
        secondary: coral,
        tertiary: mint,
        surface: darkSurface,
        brightness: Brightness.dark,
      ).copyWith(surfaceContainerHighest: const Color(0xFF3A3A3A)),
    );

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.nunito(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: whiteText,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteText,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: whiteText,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: sky.withValues(alpha: 0.24),
        disabledColor: Colors.grey.shade800,
        brightness: Brightness.dark,
        labelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        labelStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: whiteText,
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteText.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta no disponible')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                'No pudimos abrir ese cuento.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Vuelve a la biblioteca y elige una historia.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.library,
                  (route) => false,
                ),
                icon: const Icon(Icons.local_library_rounded),
                label: const Text('Ir a biblioteca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'LecturaKids',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

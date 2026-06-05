# LecturaKids

LecturaKids es una app móvil educativa hecha en Flutter para niños de 3 a 12 años. La experiencia combina cuentos interactivos, lectura guiada, comprensión lectora, recompensas y un panel para padres con estadísticas y control de uso.

## Slogan

**Leer, comprender y celebrar cada cuento.**

## Capturas de pantalla

Aquí se deben colocar imágenes reales de la app una vez ejecutada:

- `assets/capturas/login.png` - selección de perfil
- `assets/capturas/inicio.png` - pantalla principal del niño
- `assets/capturas/biblioteca.png` - catálogo de cuentos
- `assets/capturas/lector.png` - pantalla de lectura
- `assets/capturas/actividades.png` - preguntas post-lectura
- `assets/capturas/padres.png` - panel de padres

## Tecnologías utilizadas

- Flutter 3.x
- Dart 3.x
- Provider para estado global
- Shared Preferences para persistencia local
- fl_chart para gráficas
- google_fonts para tipografía Nunito
- lottie para animaciones opcionales
- audioplayers para soporte de audio

## Requisitos

- Android 8.0 o superior
- iOS 13 o superior
- Flutter SDK compatible con Flutter 3.x

## Instalación paso a paso

1. Clona o descarga el proyecto.
2. Abre una terminal en la carpeta raíz.
3. Ejecuta:

```bash
flutter pub get
```

4. Verifica que no haya errores con:

```bash
flutter analyze
```

5. Ejecuta la app:

```bash
flutter run
```

6. Si deseas probar en un dispositivo específico:

```bash
flutter devices
flutter run -d <id_del_dispositivo>
```

## Uso básico

1. Selecciona un perfil infantil o entra al panel de padres.
2. Desde la pantalla principal, abre la biblioteca.
3. Filtra cuentos por nivel o edad.
4. Abre un cuento, léelo y escucha la narración simulada.
5. Responde las preguntas de comprensión.
6. Revisa logros y estrellas ganadas.
7. En el panel de padres, revisa estadísticas, gráfica semanal y tiempo máximo de uso diario.

## Estructura del proyecto

```text
lecturaKids/
├── README.md
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app_routes.dart
│   ├── models/
│   │   ├── actividad.dart
│   │   ├── cuento.dart
│   │   ├── logro.dart
│   │   └── usuario.dart
│   ├── screens/
│   │   ├── activities_screen.dart
│   │   ├── home_screen.dart
│   │   ├── library_screen.dart
│   │   ├── parent_panel_screen.dart
│   │   ├── profile_selection_screen.dart
│   │   └── reader_screen.dart
│   ├── services/
│   │   └── data_service.dart
│   └── widgets/
│       ├── avatar_widget.dart
│       ├── cuento_card.dart
│       ├── progress_bar_widget.dart
│       └── star_widget.dart
├── assets/
└── test/
```

## Desarrollador

- Nombre: ______________________
- Materia: ______________________
- Semestre: _____________________
- Fecha: ________________________


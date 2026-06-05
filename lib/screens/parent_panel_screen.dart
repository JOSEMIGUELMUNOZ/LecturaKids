import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../widgets/app_chrome.dart';
import '../widgets/avatar_widget.dart';

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen> {
  final _pinController = TextEditingController();
  bool _accesoPermitido = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verificarPin(DataService service) {
    if (service.verificarPinPadres(_pinController.text)) {
      setState(() => _accesoPermitido = true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN incorrecto. Intenta nuevamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DataService>();
    if (!_accesoPermitido) {
      return _ParentGate(
        pinController: _pinController,
        onSubmit: () => _verificarPin(service),
      );
    }
    return _Dashboard(service: service);
  }
}

class _ParentGate extends StatelessWidget {
  final TextEditingController pinController;
  final VoidCallback onSubmit;

  const _ParentGate({
    required this.pinController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return PhoneShell(
      selectedTab: AppTab.parent,
      backgroundColor: const Color(0xFFFF705E),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Panel para padres',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el PIN para ver progreso y ajustes.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: 'PIN',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onSubmit,
                child: const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final DataService service;

  const _Dashboard({required this.service});

  @override
  Widget build(BuildContext context) {
    final usuario = service.usuarioActivo;
    return PhoneShell(
      selectedTab: AppTab.parent,
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                color: Color(0xFFFF705E),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Panel para padres',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatar: usuario.avatar,
                          nombre: usuario.nombre,
                          size: 62,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(usuario.nombre,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                '${usuario.cuentosLeidos} historias leídas',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F7EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Intermedio',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF1B8C4A),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Tabs(),
                  const SizedBox(height: 16),
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ReadingTimeCard(service: service),
                  const SizedBox(height: 12),
                  _ProgressCard(service: service),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          icon: Icons.menu_book_rounded,
                          value: '${usuario.cuentosLeidos}',
                          label: 'Historias leídas',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '${service.cuentosLeidosEstaSemana}',
                          label: 'Días seguidos',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PinSettings(service: service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final tabs = ['Resumen', 'Actividad', 'Logros', 'Intereses'];
    return Row(
      children: tabs.map((tab) {
        final active = tab == 'Resumen';
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? const Color(0xFFFF705E) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tab,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: active
                        ? const Color(0xFFFF705E)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReadingTimeCard extends StatelessWidget {
  final DataService service;

  const _ReadingTimeCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final entries = service.tiempoLecturaSemanal.entries.toList();
    final spots = entries
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiempo de lectura',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('3 h 45 min', style: Theme.of(context).textTheme.headlineMedium),
          Text(
            '+ 1 h 10 min vs. semana pasada',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF16A05D),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 4,
                    color: const Color(0xFFFF705E),
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF705E).withValues(alpha: 0.12),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          entries[index].key,
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final DataService service;

  const _ProgressCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final value =
        (service.porcentajeRespuestasCorrectas / 100).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 9,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progreso de lectura',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Comprensión lectora',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinSettings extends StatefulWidget {
  final DataService service;

  const _PinSettings({required this.service});

  @override
  State<_PinSettings> createState() => _PinSettingsState();
}

class _PinSettingsState extends State<_PinSettings> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    final pin = _controller.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener 4 números.')),
      );
      return;
    }
    widget.service.actualizarPinPadres(pin);
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN actualizado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('PIN de acceso', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Nuevo PIN',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

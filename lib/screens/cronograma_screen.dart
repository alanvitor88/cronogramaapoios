import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/apoio_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/area_section.dart';
import 'registrar_apoio_sheet.dart';

class CronogramaScreen extends StatefulWidget {
  const CronogramaScreen({super.key});

  @override
  State<CronogramaScreen> createState() => _CronogramaScreenState();
}

class _CronogramaScreenState extends State<CronogramaScreen> {
  DateTime _semanaAtual = DateTime.now();

  DateTime get _inicioSemana {
    final d = _semanaAtual;
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String get _labelSemana {
    final inicio = _inicioSemana;
    final fim = inicio.add(const Duration(days: 4));
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(inicio)} a ${fmt.format(fim)}';
  }

  void _semanaAnterior() {
    setState(() => _semanaAtual = _semanaAtual.subtract(const Duration(days: 7)));
  }

  void _semanaSeguinte() {
    setState(() => _semanaAtual = _semanaAtual.add(const Duration(days: 7)));
  }

  void _voltarHoje() {
    setState(() => _semanaAtual = DateTime.now());
  }

  String get _diaAtualSemana {
    final weekday = DateTime.now().weekday;
    const dias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX'];
    if (weekday >= 1 && weekday <= 5) return dias[weekday - 1];
    return 'SEG';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApoioProvider>();
    final total = provider.totalApoiosSemana(_semanaAtual);
    final semApoio = provider.professoresSemApoio(_semanaAtual);
    final bool isCurrentWeek = _inicioSemana.day == DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).day &&
        _inicioSemana.month == DateTime.now().month &&
        _inicioSemana.year == DateTime.now().year;

    return Scaffold(
      body: Column(
        children: [
          // ── Header da semana ──
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _semanaAnterior,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _voltarHoje,
                    child: Column(
                      children: [
                        Text(
                          'Semana: $_labelSemana',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!isCurrentWeek)
                          const Text(
                            'Toque para voltar à semana atual',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _semanaSeguinte,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
          ),

          // ── Barra de progresso da meta ──
          _MetaBar(total: total, semana: _semanaAtual),

          // ── Alerta de professores sem apoio ──
          if (semApoio.isNotEmpty && isCurrentWeek)
            _AlertaSemApoio(professores: semApoio),

          // ── Cabeçalho das colunas ──
          _HeaderColunas(),

          // ── Lista de professores por área ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<ApoioProvider>().recarregar(),
              child: ListView(
                children: [
                  for (final entry in kProfessoresPorArea.entries)
                    AreaSection(
                      area: entry.key,
                      professores: entry.value,
                      semana: _semanaAtual,
                      diaAtual: isCurrentWeek ? _diaAtualSemana : '',
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegistrarDialog(context, isCurrentWeek ? _diaAtualSemana : 'SEG'),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Apoio'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showRegistrarDialog(BuildContext context, String diaPreSelecionado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RegistrarApoioSheet(
        semana: _semanaAtual,
        diaPreSelecionado: diaPreSelecionado,
      ),
    );
  }
}

// Keep RegistrarApoioSheet placeholder removed - it's in registrar_apoio_sheet.dart

// ──────────────────────────────────────────────
// Widget: Barra de Meta
// ──────────────────────────────────────────────

class _MetaBar extends StatelessWidget {
  final int total;
  final DateTime semana;

  const _MetaBar({required this.total, required this.semana});

  @override
  Widget build(BuildContext context) {
    final pct = (total / kMetaSemanal).clamp(0.0, 1.0);
    final atingiu = total >= kMetaSemanal;

    return Container(
      color: AppTheme.primary.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meta semanal: $total / $kMetaSemanal apoios',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: atingiu ? AppTheme.accent : AppTheme.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  atingiu ? '✓ Meta atingida!' : '${kMetaSemanal - total} restantes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation(atingiu ? AppTheme.accent : Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widget: Alerta de professores sem apoio
// ──────────────────────────────────────────────

class _AlertaSemApoio extends StatefulWidget {
  final List<String> professores;
  const _AlertaSemApoio({required this.professores});

  @override
  State<_AlertaSemApoio> createState() => _AlertaSemApoioState();
}

class _AlertaSemApoioState extends State<_AlertaSemApoio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.professores.length} professor(es) sem apoio esta semana',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.professores
                      .map((p) => Chip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.warning.withValues(alpha: 0.15),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widget: Cabeçalho das colunas de dias
// ──────────────────────────────────────────────

class _HeaderColunas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 90, child: Text('ÁREA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary))),
          const SizedBox(width: 80, child: Text('PROFESSOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary))),
          ...kDiasSemana.map(
            (d) => Expanded(
              child: Center(
                child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

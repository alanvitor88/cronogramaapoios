import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../providers/apoio_provider.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _semana = DateTime.now();

  DateTime get _inicioSemana {
    return _semana.subtract(Duration(days: _semana.weekday - 1));
  }

  String get _labelSemana {
    final inicio = _inicioSemana;
    final fim = inicio.add(const Duration(days: 4));
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(inicio)} a ${fmt.format(fim)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApoioProvider>();
    final total = provider.totalApoiosSemana(_semana);
    final rankingProf = provider.rankingProfessores(_semana);
    final rankingGest = provider.rankingGestores(_semana);
    final porDia = provider.apoiosPorDia(_semana);
    final porArea = provider.apoiosPorArea(_semana);
    final historico = provider.historicoSemanal();
    final semApoio = provider.professoresSemApoio(_semana);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Navegação de semana
          _SemanaNav(
            label: _labelSemana,
            onAnterior: () => setState(() => _semana = _semana.subtract(const Duration(days: 7))),
            onSeguinte: () => setState(() => _semana = _semana.add(const Duration(days: 7))),
            onHoje: () => setState(() => _semana = DateTime.now()),
          ),
          const SizedBox(height: 12),

          // Cards resumo
          Row(
            children: [
              Expanded(child: _SummaryCard(
                label: 'Apoios na Semana',
                value: '$total',
                icon: Icons.event_available,
                color: AppTheme.primary,
                sub: total >= kMetaSemanal ? '✓ Meta atingida' : '${kMetaSemanal - total} p/ meta',
                subColor: total >= kMetaSemanal ? AppTheme.accent : AppTheme.warning,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(
                label: 'Sem Apoio',
                value: '${semApoio.length}',
                icon: Icons.person_off_outlined,
                color: semApoio.isEmpty ? AppTheme.accent : AppTheme.danger,
                sub: semApoio.isEmpty ? 'Todos apoiados!' : 'professor(es)',
                subColor: semApoio.isEmpty ? AppTheme.accent : AppTheme.danger,
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard(
                label: 'Professores Apoiados',
                value: '${rankingProf.length}',
                icon: Icons.people_alt_outlined,
                color: Colors.teal,
                sub: 'esta semana',
                subColor: Colors.teal,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(
                label: 'Meta Semanal',
                value: '$kMetaSemanal',
                icon: Icons.flag_outlined,
                color: Colors.purple,
                sub: '${((total / kMetaSemanal) * 100).toStringAsFixed(0)}% concluído',
                subColor: Colors.purple,
              )),
            ],
          ),

          const SizedBox(height: 16),

          // Gráfico: Apoios por dia
          _SectionTitle(title: 'Apoios por Dia da Semana', icon: Icons.bar_chart),
          _ApoiosPorDiaChart(porDia: porDia),

          const SizedBox(height: 16),

          // Gráfico: Histórico semanal
          _SectionTitle(title: 'Histórico das Últimas 6 Semanas', icon: Icons.trending_up),
          _HistoricoChart(historico: historico),

          const SizedBox(height: 16),

          // Gráfico: Por área (pizza)
          _SectionTitle(title: 'Apoios por Área', icon: Icons.pie_chart),
          _ApoiosPorAreaChart(porArea: porArea),

          const SizedBox(height: 16),

          // Ranking Gestores
          _SectionTitle(title: 'Ranking de Gestores', icon: Icons.leaderboard),
          _RankingGestores(ranking: rankingGest),

          const SizedBox(height: 16),

          // Ranking Professores Mais Apoiados
          if (rankingProf.isNotEmpty) ...[
            _SectionTitle(title: 'Professores Mais Apoiados', icon: Icons.star_outline),
            _RankingProfessores(ranking: rankingProf.take(10).toList(), tipo: 'mais'),
          ],

          const SizedBox(height: 16),

          // Professores Menos Apoiados (com alerta)
          if (semApoio.isNotEmpty) ...[
            _SectionTitle(title: 'Professores Sem Apoio Esta Semana', icon: Icons.warning_amber, titleColor: AppTheme.warning),
            _ProfessoresSemApoio(professores: semApoio),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Navegação de semana
// ──────────────────────────────────────────────

class _SemanaNav extends StatelessWidget {
  final String label;
  final VoidCallback onAnterior;
  final VoidCallback onSeguinte;
  final VoidCallback onHoje;

  const _SemanaNav({
    required this.label,
    required this.onAnterior,
    required this.onSeguinte,
    required this.onHoje,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(onPressed: onAnterior, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: GestureDetector(
                onTap: onHoje,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            IconButton(onPressed: onSeguinte, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Summary Card
// ──────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;
  final Color subColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            Text(sub, style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Section title
// ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? titleColor;

  const _SectionTitle({required this.title, required this.icon, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: titleColor ?? AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: titleColor ?? AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Gráfico: Apoios por Dia
// ──────────────────────────────────────────────

class _ApoiosPorDiaChart extends StatelessWidget {
  final Map<String, int> porDia;

  const _ApoiosPorDiaChart({required this.porDia});

  @override
  Widget build(BuildContext context) {
    final maxVal = porDia.values.fold(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal < 5 ? 5 : maxVal + 2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dia = kDiasSemana[groupIndex];
                    return BarTooltipItem(
                      '$dia\n${rod.toY.toInt()} apoio(s)',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= kDiasSemana.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(kDiasSemana[idx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(kDiasSemana.length, (i) {
                final val = porDia[kDiasSemana[i]] ?? 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val.toDouble(),
                      color: AppTheme.primary,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Gráfico: Histórico semanal
// ──────────────────────────────────────────────

class _HistoricoChart extends StatelessWidget {
  final List<MapEntry<String, int>> historico;

  const _HistoricoChart({required this.historico});

  @override
  Widget build(BuildContext context) {
    final maxVal = historico.fold(0, (a, b) => a > b.value ? a : b.value);
    final maxY = (maxVal < kMetaSemanal ? kMetaSemanal + 3 : maxVal + 3).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    '${historico[s.x.toInt()].key}: ${s.y.toInt()} apoios',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  )).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= historico.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(historico[idx].key, style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: kMetaSemanal.toDouble(),
                    color: AppTheme.accent.withValues(alpha: 0.6),
                    strokeWidth: 2,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Meta: $kMetaSemanal',
                      style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                      alignment: Alignment.topRight,
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: historico.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble())).toList(),
                  isCurved: true,
                  color: AppTheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppTheme.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Gráfico: Pizza por área
// ──────────────────────────────────────────────

class _ApoiosPorAreaChart extends StatelessWidget {
  final Map<String, int> porArea;

  const _ApoiosPorAreaChart({required this.porArea});

  @override
  Widget build(BuildContext context) {
    final total = porArea.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Nenhum apoio registrado', style: TextStyle(color: Colors.grey[500])),
          ),
        ),
      );
    }

    final areas = porArea.entries.where((e) => e.value > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sections: areas.map((e) {
                      final pct = (e.value / total * 100).toStringAsFixed(1);
                      return PieChartSectionData(
                        value: e.value.toDouble(),
                        title: '$pct%',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        color: AppTheme.areaColor(e.key),
                        radius: 60,
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: areas.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.areaColor(e.key),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey[300]!, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key}\n${e.value} apoio(s)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Ranking Gestores
// ──────────────────────────────────────────────

class _RankingGestores extends StatelessWidget {
  final List<MapEntry<String, int>> ranking;

  const _RankingGestores({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final maxVal = ranking.isEmpty ? 1 : ranking.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: ranking.map((entry) {
            final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
            final idx = ranking.indexOf(entry);
            Color medalColor;
            if (idx == 0) {
              medalColor = const Color(0xFFFFD700);
            } else if (idx == 1) {
              medalColor = const Color(0xFFC0C0C0);
            } else if (idx == 2) {
              medalColor = const Color(0xFFCD7F32);
            } else {
              medalColor = Colors.grey[400]!;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${idx + 1}°',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: idx < 3 ? medalColor : Colors.grey,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: medalColor.withValues(alpha: 0.2),
                    child: Text(
                      entry.key[0],
                      style: TextStyle(fontWeight: FontWeight.bold, color: medalColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(AppTheme.primary.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Ranking Professores
// ──────────────────────────────────────────────

class _RankingProfessores extends StatelessWidget {
  final List<MapEntry<String, int>> ranking;
  final String tipo;

  const _RankingProfessores({required this.ranking, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final maxVal = ranking.isEmpty ? 1 : ranking.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: ranking.asMap().entries.map((mapEntry) {
            final idx = mapEntry.key;
            final entry = mapEntry.value;
            final pct = maxVal > 0 ? entry.value / maxVal : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${idx + 1}°', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              tipo == 'mais' ? AppTheme.accent : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: tipo == 'mais' ? AppTheme.accent : AppTheme.warning,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Professores Sem Apoio
// ──────────────────────────────────────────────

class _ProfessoresSemApoio extends StatelessWidget {
  final List<String> professores;

  const _ProfessoresSemApoio({required this.professores});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.warning.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: professores.map((p) => Chip(
            avatar: const Icon(Icons.person_off, size: 14, color: AppTheme.warning),
            label: Text(p, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.warning.withValues(alpha: 0.1),
            side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.3)),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
      ),
    );
  }
}

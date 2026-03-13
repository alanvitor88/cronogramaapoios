import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/apoio_provider.dart';
import '../utils/app_theme.dart';
import '../screens/registrar_apoio_sheet.dart';

class AreaSection extends StatelessWidget {
  final String area;
  final List<String> professores;
  final DateTime semana;
  final String diaAtual; // '' se não for a semana atual

  const AreaSection({
    super.key,
    required this.area,
    required this.professores,
    required this.semana,
    required this.diaAtual,
  });

  @override
  Widget build(BuildContext context) {
    final areaColor = AppTheme.areaColor(area);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Column(
        children: List.generate(professores.length, (i) {
          final prof = professores[i];
          final isFirst = i == 0;
          return _ProfessorRow(
            professor: prof,
            area: area,
            areaLabel: isFirst ? area : '',
            areaColor: areaColor,
            semana: semana,
            diaAtual: diaAtual,
            isFirstInArea: isFirst,
            isLastInArea: i == professores.length - 1,
          );
        }),
      ),
    );
  }
}

class _ProfessorRow extends StatelessWidget {
  final String professor;
  final String area;
  final String areaLabel;
  final Color areaColor;
  final DateTime semana;
  final String diaAtual;
  final bool isFirstInArea;
  final bool isLastInArea;

  const _ProfessorRow({
    required this.professor,
    required this.area,
    required this.areaLabel,
    required this.areaColor,
    required this.semana,
    required this.diaAtual,
    required this.isFirstInArea,
    required this.isLastInArea,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApoioProvider>();

    return Container(
      decoration: BoxDecoration(
        color: areaColor.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          top: isFirstInArea ? BorderSide(color: areaColor, width: 1.5) : BorderSide.none,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área
            Container(
              width: 90,
              color: areaColor.withValues(alpha: areaLabel.isNotEmpty ? 0.7 : 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: areaLabel.isNotEmpty
                  ? Center(
                      child: Text(
                        areaLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),

            // Professor
            SizedBox(
              width: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  professor,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Dias da semana
            ...kDiasSemana.map((dia) {
              final apoiosDoDia = provider.apoiosDaSemana(semana)
                  .where((a) => a.professorNome == professor && a.diaSemana == dia)
                  .toList();
              final temApoio = apoiosDoDia.isNotEmpty;
              final isHoje = dia == diaAtual && diaAtual.isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _showCelulaOptions(context, dia, apoiosDoDia, provider),
                  onLongPress: () => _showRegistrarDireto(context, dia),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: temApoio
                          ? AppTheme.accent.withValues(alpha: 0.85)
                          : isHoje
                              ? AppTheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isHoje && !temApoio
                          ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1)
                          : null,
                    ),
                    child: temApoio
                        ? Center(
                            child: Tooltip(
                              message: apoiosDoDia.map((a) {
                                final t = a.turma != null ? ' [${a.turma}]' : '';
                                return '${a.gestorNome}$t';
                              }).join(', '),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 12),
                                  if (apoiosDoDia.length == 1) ...[
                                    Text(
                                      _abreviaNome(apoiosDoDia.first.gestorNome),
                                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (apoiosDoDia.first.turma != null)
                                      Text(
                                        apoiosDoDia.first.turma!,
                                        style: const TextStyle(color: Colors.white70, fontSize: 7),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                  if (apoiosDoDia.length > 1)
                                    Text(
                                      '${apoiosDoDia.length}x',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : isHoje
                            ? const Center(child: Icon(Icons.add, color: AppTheme.primary, size: 14))
                            : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _abreviaNome(String nome) {
    final partes = nome.split(' ');
    if (partes.length == 1) return nome.length > 6 ? nome.substring(0, 6) : nome;
    return partes[0];
  }

  void _showCelulaOptions(
    BuildContext context,
    String dia,
    List<dynamic> apoiosDoDia,
    ApoioProvider provider,
  ) {
    if (apoiosDoDia.isEmpty) {
      _showRegistrarDireto(context, dia);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apoios de $professor - $dia',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...apoiosDoDia.map((apoio) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accent,
                    radius: 16,
                    child: Text(
                      apoio.gestorNome[0],
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(apoio.gestorNome),
                  subtitle: Text(
                    apoio.turma != null
                        ? '${apoio.diaSemana} · $area · Turma ${apoio.turma}'
                        : '${apoio.diaSemana} · $area',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      provider.removerApoio(apoio.id);
                      Navigator.pop(context);
                    },
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRegistrarDireto(context, dia);
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar outro apoio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegistrarDireto(BuildContext context, String dia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RegistrarApoioSheet(
        semana: semana,
        diaPreSelecionado: dia,
        professorPreSelecionado: professor,
        areaPreSelecionada: area,
      ),
    );
  }
}

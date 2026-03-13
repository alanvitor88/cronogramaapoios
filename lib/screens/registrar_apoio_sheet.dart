import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/apoio_provider.dart';
import '../utils/app_theme.dart';

class RegistrarApoioSheet extends StatefulWidget {
  final DateTime semana;
  final String diaPreSelecionado;
  final String? professorPreSelecionado;
  final String? areaPreSelecionada;

  const RegistrarApoioSheet({
    super.key,
    required this.semana,
    required this.diaPreSelecionado,
    this.professorPreSelecionado,
    this.areaPreSelecionada,
  });

  @override
  State<RegistrarApoioSheet> createState() => _RegistrarApoioSheetState();
}

class _RegistrarApoioSheetState extends State<RegistrarApoioSheet> {
  String? _areaSelecionada;
  String? _professorSelecionado;
  String? _gestorSelecionado;
  late String _diaSelecionado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _diaSelecionado = widget.diaPreSelecionado;
    _areaSelecionada = widget.areaPreSelecionada;
    _professorSelecionado = widget.professorPreSelecionado;
  }

  List<String> get _professoresDaArea {
    if (_areaSelecionada == null) return [];
    return kProfessoresPorArea[_areaSelecionada!] ?? [];
  }

  Future<void> _registrar() async {
    if (_professorSelecionado == null || _gestorSelecionado == null || _areaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _salvando = true);

    final provider = context.read<ApoioProvider>();

    // Calcular data correta baseada no dia da semana
    final inicio = widget.semana.subtract(Duration(days: widget.semana.weekday - 1));
    final diaIndex = kDiasSemana.indexOf(_diaSelecionado);
    final dataApoio = DateTime(inicio.year, inicio.month, inicio.day + diaIndex, 8, 0, 0);

    final ok = await provider.registrarApoio(
      professorNome: _professorSelecionado!,
      professorArea: _areaSelecionada!,
      gestorNome: _gestorSelecionado!,
      diaSemana: _diaSelecionado,
      dataHora: dataApoio,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ok ? Icons.cloud_done : Icons.cloud_off, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                    ? '✓ Apoio salvo na nuvem: $_professorSelecionado por $_gestorSelecionado'
                    : '⚠ Salvo localmente. Verifique sua conexão.',
                ),
              ),
            ],
          ),
          backgroundColor: ok ? AppTheme.accent : AppTheme.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Registrar Apoio Presencial',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Dia da semana
            const Text('Dia da semana', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: kDiasSemana.map((d) => ChoiceChip(
                label: Text(d, style: const TextStyle(fontSize: 12)),
                selected: _diaSelecionado == d,
                onSelected: (_) => setState(() => _diaSelecionado = d),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: _diaSelecionado == d ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Área
            const Text('Área', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _areaSelecionada,
              hint: const Text('Selecione a área'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: kProfessoresPorArea.keys.map((a) {
                return DropdownMenuItem(
                  value: a,
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.areaColor(a),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(a),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() {
                _areaSelecionada = v;
                _professorSelecionado = null;
              }),
            ),
            const SizedBox(height: 14),

            // Professor
            const Text('Professor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _professorSelecionado,
              hint: const Text('Selecione o professor'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _professoresDaArea.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: _areaSelecionada == null ? null : (v) => setState(() => _professorSelecionado = v),
            ),
            const SizedBox(height: 14),

            // Gestor
            const Text('Gestor Responsável', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _gestorSelecionado,
              hint: const Text('Selecione o gestor'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: kGestores.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          g[0],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(g),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _gestorSelecionado = v),
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _registrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _salvando
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Salvando na nuvem...', style: TextStyle(fontSize: 15)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined),
                        SizedBox(width: 8),
                        Text('Confirmar Registro', style: TextStyle(fontSize: 15)),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

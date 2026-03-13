import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_data.dart';
import '../providers/apoio_provider.dart';
import '../utils/app_theme.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String _filtroGestor = 'Todos';
  String _filtroArea = 'Todas';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApoioProvider>();
    final semana = DateTime.now();

    // Filtros
    List<Apoio> apoios = provider.apoiosDaSemana(semana);
    if (_filtroGestor != 'Todos') {
      apoios = apoios.where((a) => a.gestorNome == _filtroGestor).toList();
    }
    if (_filtroArea != 'Todas') {
      apoios = apoios.where((a) => a.professorArea == _filtroArea).toList();
    }

    // Ordenar por data
    apoios.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    return Scaffold(
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filtroGestor,
                    decoration: InputDecoration(
                      labelText: 'Gestor',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    items: ['Todos', ...kGestores]
                        .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _filtroGestor = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filtroArea,
                    decoration: InputDecoration(
                      labelText: 'Área',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    items: ['Todas', ...kProfessoresPorArea.keys]
                        .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setState(() => _filtroArea = v!),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${apoios.length} apoio(s) encontrado(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (apoios.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmarLimpar(context, provider),
                    icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                    label: const Text('Limpar semana', style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: apoios.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum apoio encontrado',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: apoios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _ApoioCard(apoio: apoios[i], provider: provider),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmarLimpar(BuildContext context, ApoioProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar semana atual?'),
        content: const Text('Todos os apoios da semana atual serão removidos. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.limparSemana(DateTime.now());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _ApoioCard extends StatelessWidget {
  final Apoio apoio;
  final ApoioProvider provider;

  const _ApoioCard({required this.apoio, required this.provider});

  @override
  Widget build(BuildContext context) {
    final areaColor = AppTheme.areaColor(apoio.professorArea);
    final fmt = DateFormat('dd/MM HH:mm');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: areaColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              apoio.gestorNome[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        title: Text(
          apoio.professorNome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 3),
                Text(apoio.gestorNome, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: areaColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    apoio.professorArea,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text(apoio.diaSemana, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(width: 6),
                Icon(Icons.access_time, size: 11, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text(fmt.format(apoio.dataHora), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _confirmarRemover(context),
        ),
      ),
    );
  }

  void _confirmarRemover(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover apoio?'),
        content: Text('Deseja remover o apoio de ${apoio.professorNome} realizado por ${apoio.gestorNome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.removerApoio(apoio.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

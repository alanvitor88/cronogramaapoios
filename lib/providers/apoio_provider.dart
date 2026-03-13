import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/app_data.dart';

class ApoioProvider extends ChangeNotifier {
  List<Apoio> _apoios = [];
  bool _isLoading = false;
  bool _isOnline = true;
  String? _erro;
  RealtimeChannel? _channel;
  final _uuid = const Uuid();

  List<Apoio> get apoios => _apoios;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get erro => _erro;

  SupabaseClient get _db => Supabase.instance.client;

  ApoioProvider() {
    _init();
  }

  // ─────────────────────────────────────────────
  // Inicialização: carrega dados + assina realtime
  // ─────────────────────────────────────────────

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _carregarTodos();
    if (_isOnline) _assinarRealtime();
    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Carregar todos os apoios do Supabase
  // ─────────────────────────────────────────────

  Future<void> _carregarTodos() async {
    try {
      final response = await _db
          .from('apoios')
          .select('*')
          .order('data_hora', ascending: false)
          .timeout(const Duration(seconds: 15));

      _apoios = (response as List)
          .map((row) => Apoio.fromSupabase(Map<String, dynamic>.from(row)))
          .toList();
      _isOnline = true;
      _erro = null;
    } on SocketException catch (e) {
      _isOnline = false;
      _erro = 'Sem internet. Verifique sua conexão Wi-Fi ou dados móveis.';
      if (kDebugMode) debugPrint('SocketException: $e');
    } on TimeoutException catch (_) {
      _isOnline = false;
      _erro = 'Tempo esgotado. Servidor demorou para responder.';
      if (kDebugMode) debugPrint('Timeout ao conectar ao Supabase');
    } catch (e) {
      _isOnline = false;
      _erro = 'Erro ao conectar: ${e.toString().substring(0, e.toString().length.clamp(0, 120))}';
      if (kDebugMode) debugPrint('Erro ao carregar: $e');
    }
  }

  // Recarregar manualmente (pull-to-refresh) com retry
  Future<void> recarregar() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();
    await _carregarTodos();
    // Se conectou, assinar realtime se ainda não estiver
    if (_isOnline && _channel == null) {
      _assinarRealtime();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Realtime: escuta INSERT e DELETE de qualquer
  // dispositivo e atualiza a lista automaticamente
  // ─────────────────────────────────────────────

  void _assinarRealtime() {
    _channel = _db
        .channel('apoios_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'apoios',
          callback: (payload) {
            try {
              final novoApoio =
                  Apoio.fromSupabase(Map<String, dynamic>.from(payload.newRecord));
              // Evitar duplicatas
              if (!_apoios.any((a) => a.id == novoApoio.id)) {
                _apoios.insert(0, novoApoio);
                notifyListeners();
              }
            } catch (e) {
              if (kDebugMode) debugPrint('Realtime INSERT error: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'apoios',
          callback: (payload) {
            try {
              final id = payload.oldRecord['id'] as String?;
              if (id != null) {
                _apoios.removeWhere((a) => a.id == id);
                notifyListeners();
              }
            } catch (e) {
              if (kDebugMode) debugPrint('Realtime DELETE error: $e');
            }
          },
        )
        .subscribe();
  }

  // ─────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────

  Future<bool> registrarApoio({
    required String professorNome,
    required String professorArea,
    required String gestorNome,
    required String diaSemana,
    DateTime? dataHora,
  }) async {
    final id = _uuid.v4();
    final dataFinal = dataHora ?? DateTime.now();

    final apoio = Apoio(
      id: id,
      professorNome: professorNome,
      professorArea: professorArea,
      gestorNome: gestorNome,
      dataHora: dataFinal,
      diaSemana: diaSemana,
    );

    // Otimista: adiciona localmente antes de confirmar
    _apoios.insert(0, apoio);
    notifyListeners();

    try {
      await _db.from('apoios').insert(apoio.toSupabase());
      _isOnline = true;
      return true;
    } catch (e) {
      // Reverter em caso de erro
      _apoios.removeWhere((a) => a.id == id);
      _isOnline = false;
      _erro = 'Falha ao salvar. Verifique sua conexão.';
      notifyListeners();
      if (kDebugMode) debugPrint('Erro ao inserir: $e');
      return false;
    }
  }

  Future<bool> removerApoio(String id) async {
    // Guardar para reverter se necessário
    final backup = _apoios.firstWhere((a) => a.id == id);
    final index = _apoios.indexWhere((a) => a.id == id);

    // Otimista: remove localmente
    _apoios.removeWhere((a) => a.id == id);
    notifyListeners();

    try {
      await _db.from('apoios').delete().eq('id', id);
      _isOnline = true;
      return true;
    } catch (e) {
      // Reverter
      _apoios.insert(index, backup);
      _isOnline = false;
      _erro = 'Falha ao remover. Verifique sua conexão.';
      notifyListeners();
      if (kDebugMode) debugPrint('Erro ao remover: $e');
      return false;
    }
  }

  Future<void> limparSemana(DateTime semana) async {
    final inicio = _inicioSemana(semana);
    final fim = inicio.add(const Duration(days: 5));

    final ids = _apoios
        .where((a) =>
            !a.dataHora.isBefore(inicio) && a.dataHora.isBefore(fim))
        .map((a) => a.id)
        .toList();

    if (ids.isEmpty) return;

    // Otimista
    _apoios.removeWhere((a) => ids.contains(a.id));
    notifyListeners();

    try {
      for (final id in ids) {
        await _db.from('apoios').delete().eq('id', id);
      }
      _isOnline = true;
    } catch (e) {
      // Recarregar para recuperar estado correto
      await _carregarTodos();
      _isOnline = false;
      _erro = 'Falha ao limpar semana.';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Utilitários de data
  // ─────────────────────────────────────────────

  DateTime _inicioSemana(DateTime d) {
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
  }

  // ─────────────────────────────────────────────
  // Consultas por semana (todas locais/rápidas)
  // ─────────────────────────────────────────────

  List<Apoio> apoiosDaSemana(DateTime semana) {
    final inicio = _inicioSemana(semana);
    final fim = inicio.add(const Duration(days: 5));
    return _apoios.where((a) {
      final d = a.dataHora.toLocal();
      return !d.isBefore(inicio) && d.isBefore(fim);
    }).toList();
  }

  List<Apoio> apoiosDoDia(String diaSemana, DateTime semana) {
    return apoiosDaSemana(semana)
        .where((a) => a.diaSemana == diaSemana)
        .toList();
  }

  bool jaApoidoHoje(String professor, String diaSemana, DateTime semana) {
    return apoiosDaSemana(semana)
        .any((a) => a.professorNome == professor && a.diaSemana == diaSemana);
  }

  // ─────────────────────────────────────────────
  // Estatísticas
  // ─────────────────────────────────────────────

  int totalApoiosSemana(DateTime semana) => apoiosDaSemana(semana).length;

  List<MapEntry<String, int>> rankingProfessores(DateTime semana) {
    final Map<String, int> c = {};
    for (final a in apoiosDaSemana(semana)) {
      c[a.professorNome] = (c[a.professorNome] ?? 0) + 1;
    }
    return c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<String, int>> rankingGestores(DateTime semana) {
    final Map<String, int> c = {for (final g in kGestores) g: 0};
    for (final a in apoiosDaSemana(semana)) {
      c[a.gestorNome] = (c[a.gestorNome] ?? 0) + 1;
    }
    return c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  Map<String, int> apoiosPorDia(DateTime semana) {
    final Map<String, int> r = {for (final d in kDiasSemana) d: 0};
    for (final a in apoiosDaSemana(semana)) {
      r[a.diaSemana] = (r[a.diaSemana] ?? 0) + 1;
    }
    return r;
  }

  List<String> professoresSemApoio(DateTime semana) {
    final apoiados = apoiosDaSemana(semana).map((a) => a.professorNome).toSet();
    final List<String> semApoio = [];
    for (final area in kAreasComAlerta) {
      for (final prof in kProfessoresPorArea[area]!) {
        if (!apoiados.contains(prof)) semApoio.add(prof);
      }
    }
    return semApoio;
  }

  Map<String, int> apoiosPorArea(DateTime semana) {
    final Map<String, int> r = {for (final a in kProfessoresPorArea.keys) a: 0};
    for (final a in apoiosDaSemana(semana)) {
      r[a.professorArea] = (r[a.professorArea] ?? 0) + 1;
    }
    return r;
  }

  List<MapEntry<String, int>> historicoSemanal() {
    final List<MapEntry<String, int>> resultado = [];
    for (int i = 5; i >= 0; i--) {
      final semana = DateTime.now().subtract(Duration(days: i * 7));
      resultado.add(MapEntry('S${6 - i}', apoiosDaSemana(semana).length));
    }
    return resultado;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

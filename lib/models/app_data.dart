// Modelo de dados da aplicação

class Gestor {
  final String nome;
  const Gestor(this.nome);
}

class Professor {
  final String nome;
  final String area;
  const Professor({required this.nome, required this.area});
}

class Apoio {
  final String id;
  final String professorNome;
  final String professorArea;
  final String gestorNome;
  final DateTime dataHora;
  final String diaSemana; // 'SEG', 'TER', 'QUA', 'QUI', 'SEX'
  final String? turma;   // ex: '6A', '2ADM', etc.

  Apoio({
    required this.id,
    required this.professorNome,
    required this.professorArea,
    required this.gestorNome,
    required this.dataHora,
    required this.diaSemana,
    this.turma,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'professorNome': professorNome,
      'professorArea': professorArea,
      'gestorNome': gestorNome,
      'dataHora': dataHora.toIso8601String(),
      'diaSemana': diaSemana,
      'turma': turma,
    };
  }

  factory Apoio.fromMap(Map<String, dynamic> map) {
    return Apoio(
      id: map['id'],
      professorNome: map['professorNome'],
      professorArea: map['professorArea'],
      gestorNome: map['gestorNome'],
      dataHora: DateTime.parse(map['dataHora']),
      diaSemana: map['diaSemana'],
      turma: map['turma'] as String?,
    );
  }

  // ── Supabase (snake_case) ──
  Map<String, dynamic> toSupabase() {
    final m = <String, dynamic>{
      'id': id,
      'professor_nome': professorNome,
      'professor_area': professorArea,
      'gestor_nome': gestorNome,
      'data_hora': dataHora.toUtc().toIso8601String(),
      'dia_semana': diaSemana,
    };
    if (turma != null) m['turma'] = turma;
    return m;
  }

  factory Apoio.fromSupabase(Map<String, dynamic> map) {
    return Apoio(
      id: map['id'] as String,
      professorNome: map['professor_nome'] as String,
      professorArea: map['professor_area'] as String,
      gestorNome: map['gestor_nome'] as String,
      dataHora: DateTime.parse(map['data_hora'] as String).toLocal(),
      diaSemana: map['dia_semana'] as String,
      turma: map['turma'] as String?,
    );
  }
}

// ──────────────────────────────────────────────
// Dados estáticos
// ──────────────────────────────────────────────

const List<String> kGestores = [
  'Alan',
  'Meire',
  'Dayse',
  'Lore',
  'Gilberto',
  'Renato',
  'Marcia',
  'Priscila',
];

const List<String> kDiasSemana = ['SEG', 'TER', 'QUA', 'QUI', 'SEX'];

const Map<String, List<String>> kProfessoresPorArea = {
  'HUMANAS': [
    'Adriano',
    'Neide',
    'Antonio M.',
    'Renato',
    'Carla',
    'Andre',
  ],
  'LINGUAGENS': [
    'Tatiane',
    'Suellen',
    'Lidiane',
    'Daiane',
    'Fabiani',
    'Marcia',
    'Cristiane',
    'Fabricio',
    'Felipe',
    'Pedro',
    'Sandra',
    'Juvenal',
  ],
  'MAT E NATUREZA': [
    'Karina',
    'Ana Paula',
    'Sergio',
    'Ezel',
    'Priscila',
    'Thiago',
    'Danilo',
    'Diego',
    'Herbert',
    'Luciano',
    'Bianca',
  ],
  'ENS TÉCNICO': [
    'Alisson',
    'Daniel',
    'Danielly',
    'Gabriele',
    'Maurilei',
    'Paulo',
    'Vanessa',
  ],
};

// Áreas que geram alertas de professores não apoiados
const List<String> kAreasComAlerta = ['HUMANAS', 'LINGUAGENS', 'MAT E NATUREZA'];

const Map<String, int> kAreaColor = {
  'HUMANAS': 0xFFFFB3B3,       // Rosa
  'LINGUAGENS': 0xFF80D4F0,    // Azul claro
  'MAT E NATUREZA': 0xFF90EE90, // Verde
  'ENS TÉCNICO': 0xFFFFFF66,   // Amarelo
};

const int kMetaSemanal = 15;

// Turmas da escola
const List<String> kTurmas = [
  // Ensino Fundamental
  '6A', '6B', '6C',
  '7A', '7B', '7C',
  '8A', '8B', '8C',
  '9A', '9B', '9C',
  // Ensino Médio
  '1A', '1B', '1C', '1D',
  // Ensino Técnico
  '2ADM', '2ENF', '2C',
  '3A', '3ADM', '3B',
];

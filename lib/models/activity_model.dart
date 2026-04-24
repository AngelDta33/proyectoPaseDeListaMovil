import 'package:flutter/material.dart';

enum ActivityType { video, game, song, story }

class ActivityCategory {
  final String id;
  final String title;
  final String emoji;
  final Color color;
  final List<Activity> activities;

  const ActivityCategory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.activities,
  });
}

class Activity {
  final String id;
  final String title;
  final String emoji;
  final ActivityType type;
  final Color? cardColor;

  const Activity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.type,
    this.cardColor,
  });
}

// ─── Datos de ejemplo — añade actividades aquí ──────────────────────────────

final List<ActivityCategory> kidsCategories = [
  ActivityCategory(
    id: 'animales',
    title: 'Animales',
    emoji: '🐾',
    color: const Color(0xFF4CAF50),
    activities: [
      Activity(id: 'a1', title: 'La Granja', emoji: '🐄', type: ActivityType.video),
      Activity(id: 'a2', title: 'Animales del Mar', emoji: '🐬', type: ActivityType.game),
      Activity(id: 'a3', title: 'Canción del Zoo', emoji: '🦁', type: ActivityType.song),
      Activity(id: 'a4', title: 'La Selva', emoji: '🐒', type: ActivityType.story),
      Activity(id: 'a5', title: 'Las Aves', emoji: '🦜', type: ActivityType.video),
    ],
  ),
  ActivityCategory(
    id: 'numeros',
    title: 'Números',
    emoji: '🔢',
    color: const Color(0xFFFF9800),
    activities: [
      Activity(id: 'n1', title: 'Contemos Juntos', emoji: '🧮', type: ActivityType.song),
      Activity(id: 'n2', title: 'El 1 al 10', emoji: '1️⃣', type: ActivityType.video),
      Activity(id: 'n3', title: 'Sumas Divertidas', emoji: '➕', type: ActivityType.game),
      Activity(id: 'n4', title: 'Las Formas', emoji: '🔺', type: ActivityType.game),
    ],
  ),
  ActivityCategory(
    id: 'letras',
    title: 'Letras',
    emoji: '📝',
    color: const Color(0xFF2196F3),
    activities: [
      Activity(id: 'l1', title: 'El Abecedario', emoji: '🔤', type: ActivityType.song),
      Activity(id: 'l2', title: 'Mis Primeras Palabras', emoji: '📖', type: ActivityType.video),
      Activity(id: 'l3', title: 'Vocales', emoji: '🎵', type: ActivityType.game),
      Activity(id: 'l4', title: 'Aprende a Escribir', emoji: '✏️', type: ActivityType.game),
    ],
  ),
  ActivityCategory(
    id: 'naturaleza',
    title: 'Naturaleza',
    emoji: '🌿',
    color: const Color(0xFF009688),
    activities: [
      Activity(id: 'na1', title: 'Las Plantas', emoji: '🌱', type: ActivityType.video),
      Activity(id: 'na2', title: 'El Clima', emoji: '☁️', type: ActivityType.story),
      Activity(id: 'na3', title: 'Las Estaciones', emoji: '🍂', type: ActivityType.video),
    ],
  ),
  ActivityCategory(
    id: 'musica',
    title: 'Música',
    emoji: '🎵',
    color: const Color(0xFFE91E63),
    activities: [
      Activity(id: 'm1', title: 'Ritmos y Sonidos', emoji: '🥁', type: ActivityType.song),
      Activity(id: 'm2', title: 'Los Instrumentos', emoji: '🎸', type: ActivityType.video),
      Activity(id: 'm3', title: 'Canta Conmigo', emoji: '🎤', type: ActivityType.song),
    ],
  ),
  ActivityCategory(
    id: 'cuentos',
    title: 'Cuentos',
    emoji: '📚',
    color: const Color(0xFF9C27B0),
    activities: [
      Activity(id: 'c1', title: 'Los Tres Cerditos', emoji: '🐷', type: ActivityType.story),
      Activity(id: 'c2', title: 'Caperucita Roja', emoji: '🔴', type: ActivityType.story),
      Activity(id: 'c3', title: 'El Patito Feo', emoji: '🦆', type: ActivityType.video),
    ],
  ),
];

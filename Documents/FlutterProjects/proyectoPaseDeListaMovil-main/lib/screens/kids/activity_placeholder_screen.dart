import 'package:flutter/material.dart';
import '../../models/activity_model.dart';

class ActivityPlaceholderScreen extends StatelessWidget {
  final Activity activity;
  final Color categoryColor;

  const ActivityPlaceholderScreen({
    super.key,
    required this.activity,
    required this.categoryColor,
  });

  String get _typeLabel {
    switch (activity.type) {
      case ActivityType.video:
        return 'Video';
      case ActivityType.game:
        return 'Juego';
      case ActivityType.song:
        return 'Canción';
      case ActivityType.story:
        return 'Cuento';
    }
  }

  IconData get _typeIcon {
    switch (activity.type) {
      case ActivityType.video:
        return Icons.play_circle_rounded;
      case ActivityType.game:
        return Icons.extension_rounded;
      case ActivityType.song:
        return Icons.music_note_rounded;
      case ActivityType.story:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              categoryColor,
              categoryColor.withOpacity(0.7),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Emoji
              Text(
                activity.emoji,
                style: const TextStyle(fontSize: 100),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Placeholder content area
              Container(
                margin: const EdgeInsets.all(24),
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _typeIcon,
                      size: 60,
                      color: categoryColor.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El contenido se cargará aquí',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(próximamente)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

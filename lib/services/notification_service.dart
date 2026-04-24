import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handler para mensajes en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase ya está inicializado por el runtime en background.
  // No necesitamos hacer nada más aquí; el sistema mostrará la notificación.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _channelId = 'qr_escuela_channel';
  static const String _channelName = 'Notificaciones Escuela';
  static const String _channelDesc =
      'Avisos de tareas, exámenes y novedades';

  // ── Inicializar (llamar en main.dart antes de runApp) ─────────────────────
  static Future<void> initialize() async {
    // Registrar handler de mensajes en background
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Solicitar permisos (iOS y Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Crear canal de notificaciones en Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Inicializar flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(initSettings);

    // Mostrar notificación local cuando llega mensaje FCM en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'] ?? 'aviso';
      showLocal(
        title: message.notification?.title ?? 'Nueva notificación',
        body: message.notification?.body ?? '',
        type: type,
      );
    });
  }

  // ── Guardar token FCM del usuario en Firestore ────────────────────────────
  static Future<void> saveToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
      }
      // Actualizar token cuando Firebase lo renueva
      _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await _db
              .collection('users')
              .doc(uid)
              .update({'fcmToken': newToken});
        } catch (_) {}
      });
    } catch (_) {
      // No es crítico si falla (p.ej. sin permisos)
    }
  }

  // ── Mostrar una notificación local ────────────────────────────────────────
  static Future<void> showLocal({
    required String title,
    required String body,
    required String type,
  }) async {
    final color = _colorForType(type);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      icon: '@mipmap/ic_launcher',
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    // Usamos timestamp como ID para evitar sobreescribir notificaciones previas
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    await _local.show(id, title, body, details);
  }

  // ── Crear notificación pendiente en Firestore para un alumno ──────────────
  static Future<void> sendTaskNotification({
    required String studentId,
    required String title,
    required String body,
    required String type,
    required String taskId,
  }) async {
    await _db
        .collection('notifications')
        .doc(studentId)
        .collection('pending')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'taskId': taskId,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  // ── Verificar notificaciones pendientes y mostrarlas ──────────────────────
  static Future<void> checkPendingNotifications(String studentId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .doc(studentId)
          .collection('pending')
          .where('seen', isEqualTo: false)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        await showLocal(
          title: data['title'] as String? ?? 'Nueva notificación',
          body: data['body'] as String? ?? '',
          type: data['type'] as String? ?? 'aviso',
        );
        // Marcar como vista para no mostrarla de nuevo
        await doc.reference.update({'seen': true});
      }
    } catch (_) {
      // No crítico
    }
  }

  // ── Color según tipo de tarea ─────────────────────────────────────────────
  static Color _colorForType(String type) {
    switch (type) {
      case 'examen':
        return Colors.red;
      case 'comentario':
        return const Color(0xFF1565C0);
      case 'aviso':
        return Colors.orange;
      default:
        return const Color(0xFF6A1B9A);
    }
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Initialisation complète ──────────────────────────────────────
  static Future<void> init() async {
    // 1. Demander la permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialiser les notifications locales
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // 3. Sauvegarder le token FCM dans Firestore
    await _sauvegarderToken();

    // 4. Écouter les messages reçus quand l'app est ouverte
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _afficherNotificationLocale(
        titre: message.notification?.title ?? 'Rappel de session',
        corps: message.notification?.body ?? '',
      );
    });
  }

  // ── Sauvegarder le token FCM dans le profil utilisateur ──────────
  static Future<void> _sauvegarderToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});

    // Rafraîchir le token si il change
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': newToken});
    });
  }

  // ── Afficher une notification locale ─────────────────────────────
  static Future<void> _afficherNotificationLocale({
    required String titre,
    required String corps,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'sessions_rappel',       // channel id
      'Rappels de sessions',   // channel name
      channelDescription: 'Notifications de rappel avant les sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titre,
      corps,
      details,
    );
  }

  // ── Planifier un rappel local 24h avant la session ────────────────
  static Future<void> planifierRappel({
    required String sessionId,
    required String titreSession,
    required DateTime dateSession,
  }) async {
    // Calcule 24h avant la session
    final DateTime heureRappel =
    dateSession.subtract(const Duration(hours: 24));

    // Si la session est dans moins de 24h, rappel dans 1h
    final DateTime maintenant = DateTime.now();
    final DateTime heureEffective =
    heureRappel.isAfter(maintenant) ? heureRappel :
    maintenant.add(const Duration(hours: 1));

    // Sauvegarde le rappel dans Firestore pour traitement serveur
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('rappels')
        .doc('${uid}_$sessionId')
        .set({
      'uid': uid,
      'sessionId': sessionId,
      'titreSession': titreSession,
      'dateSession': dateSession,
      'heureRappel': heureEffective,
      'envoye': false,
      'creeLe': FieldValue.serverTimestamp(),
    });
  }

  // ── Annuler un rappel si le bénévole se désinscrit ────────────────
  static Future<void> annulerRappel({
    required String sessionId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('rappels')
        .doc('${uid}_$sessionId')
        .delete();
  }

  // ── Test immédiat ─────────────────────────────────────────────────
  static Future<void> envoyerNotificationTest({
    required String titreSession,
  }) async {
    await _afficherNotificationLocale(
      titre: '📅 Rappel de session',
      corps: 'Vous êtes inscrit à : $titreSession',
    );
  }
}
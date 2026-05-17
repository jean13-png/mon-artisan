import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialiser le service de notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Demander la permission
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Écouter les messages en avant-plan
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Écouter les messages en arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Obtenir le token FCM
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      _isInitialized = true;
    } catch (e) {
      print('Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) async {
          // Gérer les notifications iOS
        },
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Gérer le clic sur la notification
        },
      );

      // Créer un canal de notification pour Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'mon_artisan_channel',
          'Mon Artisan Notifications',
          description: 'Notifications pour Mon Artisan',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des notifications locales: $e');
    }
  }

  /// Gérer les messages en avant-plan
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Message reçu en avant-plan: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Mon Artisan',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Gérer les messages en arrière-plan
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Message reçu en arrière-plan: ${message.notification?.title}');
    // Naviguer vers l'écran approprié
  }

  /// Afficher une notification locale
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'mon_artisan_channel',
        'Mon Artisan Notifications',
        channelDescription: 'Notifications pour Mon Artisan',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647, // Mi2 — ID unique (int max safe)
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
    }
  }

  /// Obtenir le token FCM
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  /// S'abonner à un topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Abonné au topic: $topic');
    } catch (e) {
      print('Erreur lors de l\'abonnement au topic: $e');
    }
  }

  /// Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Désabonné du topic: $topic');
    } catch (e) {
      print('Erreur lors de la désinscription du topic: $e');
    }
  }

  /// Envoyer une notification locale simple
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Envoyer une notification de nouvelle commande
  static Future<void> showNewCommandeNotification({
    required String artisanName,
    required String metier,
    required String ville,
    required double montant,
  }) async {
    await _showLocalNotification(
      title: 'Nouvelle commande !',
      body: '$artisanName demande un $metier à $ville - $montant FCFA',
      payload: 'new_commande',
    );
  }

  /// Envoyer une notification de commande acceptée
  static Future<void> showCommandeAcceptedNotification({
    required String artisanName,
  }) async {
    await _showLocalNotification(
      title: 'Commande acceptée',
      body: '$artisanName a accepté votre commande',
      payload: 'commande_accepted',
    );
  }

  /// Envoyer une notification de paiement confirmé
  static Future<void> showPaymentConfirmedNotification({
    required double montant,
  }) async {
    await _showLocalNotification(
      title: 'Paiement confirmé',
      body: 'Votre paiement de $montant FCFA a été confirmé',
      payload: 'payment_confirmed',
    );
  }

  /// Envoyer une notification de prestation terminée
  static Future<void> showPrestationCompletedNotification({
    required String artisanName,
  }) async {
    await _showLocalNotification(
      title: 'Prestation terminée',
      body: '$artisanName a terminé votre prestation. Notez-le !',
      payload: 'prestation_completed',
    );
  }

  /// Envoyer une notification d'avis reçu
  static Future<void> showReviewReceivedNotification({
    required String clientName,
    required double note,
  }) async {
    await _showLocalNotification(
      title: 'Nouvel avis reçu',
      body: '$clientName vous a noté $note/5',
      payload: 'review_received',
    );
  }

  /// Envoyer une notification de retrait approuvé
  static Future<void> showWithdrawalApprovedNotification({
    required double montant,
  }) async {
    await _showLocalNotification(
      title: 'Retrait approuvé',
      body: 'Votre retrait de $montant FCFA a été approuvé',
      payload: 'withdrawal_approved',
    );
  }
}

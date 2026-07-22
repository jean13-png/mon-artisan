import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';
import '../../core/utils/logger.dart';

/// Fonction globale obligatoire pour gérer les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase pour le background isolate
  await Firebase.initializeApp();
  Logger.log("Message reçu en arrière-plan : ${message.messageId}");
  
  // Afficher une notification locale même en arrière-plan
  if (message.notification != null) {
    // Réinitialiser les notifications locales pour l'isolate
    final FlutterLocalNotificationsPlugin localNotifs = FlutterLocalNotificationsPlugin();
    // Configuration minimale
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifs.initialize(
      const InitializationSettings(android: androidInit),
    );
    
    // Afficher la notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mon_artisan_channel',
      'Mon Artisan Notifications',
      channelDescription: 'Notifications pour Mon Artisan',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      visibility: NotificationVisibility.public,
    );

    await localNotifs.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      message.notification!.title ?? 'Mon Artisan',
      message.notification!.body ?? '',
      const NotificationDetails(android: androidDetails),
    );
  }
}

class NotificationService {
  static FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static StreamSubscription? _notificationsSubscription;

  /// Initialiser le service de notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurer le handler de fond avant toute chose
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Demander la permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Logger.log('Statut des permissions : ${settings.authorizationStatus}');

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Écouter les messages en avant-plan
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Écouter les messages en arrière-plan (quand on clique sur la notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Gérer le cas où l'app est lancée via une notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      // Écouter le rafraîchissement du token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        Logger.log('FCM Token rafraîchi : $newToken');
        // On ne peut pas mettre à jour ici car on n'a pas forcément l'ID utilisateur
      });

      _isInitialized = true;
    } catch (e) {
      Logger.log('Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Associer le token FCM actuel à un utilisateur dans Firestore et commencer à écouter les notifications
  static Future<void> updateUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.log('FCM Token mis à jour pour l\'utilisateur $userId');
      }
      // Commencer à écouter les nouvelles notifications pour cet utilisateur
      _listenToNotifications(userId);
    } catch (e) {
      Logger.log('Erreur lors de la mise à jour du token FCM : $e');
    }
  }

  /// Écouter les nouvelles notifications dans Firestore
  static void _listenToNotifications(String userId) {
    // Annuler l'écoute précédente si elle existe
    _notificationsSubscription?.cancel();

    // Écouter les nouvelles notifications
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final notification = change.doc.data() as Map<String, dynamic>;
              final titre = notification['titre'] as String?;
              final message = notification['message'] as String?;
              if (titre != null && message != null) {
                _showLocalNotification(
                  title: titre,
                  body: message,
                  payload: change.doc.id,
                );
              }
            }
          }
        });
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
          showBadge: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      Logger.log('Erreur lors de l\'initialisation des notifications locales: $e');
    }
  }

  /// Gérer les messages en avant-plan
  static void _handleForegroundMessage(RemoteMessage message) {
    Logger.log('Message reçu en avant-plan: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Mon Artisan',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    } else if (message.data.isNotEmpty) {
      _showLocalNotification(
        title: message.data['titre']?.toString() ?? 'Mon Artisan',
        body: message.data['message']?.toString() ?? '',
        payload: message.data['payload']?.toString(),
      );
    }
  }

  /// Gérer les messages en arrière-plan
  static void _handleBackgroundMessage(RemoteMessage message) {
    Logger.log('Message reçu en arrière-plan: ${message.notification?.title}');
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
        visibility: NotificationVisibility.public, // Affiche sur écran de verrouillage
        channelShowBadge: true, // Affiche badge sur l'icône
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
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
      Logger.log('Erreur lors de l\'affichage de la notification: $e');
    }
  }

  /// Obtenir le token FCM
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      Logger.log('Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  /// S'abonner à un topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.log('Abonné au topic: $topic');
    } catch (e) {
      Logger.log('Erreur lors de l\'abonnement au topic: $e');
    }
  }

  /// Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.log('Désabonné du topic: $topic');
    } catch (e) {
      Logger.log('Erreur lors de la désinscription du topic: $e');
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

  /// Arrêter d'écouter les notifications (lors de la déconnexion)
  static void stopListening() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }
}

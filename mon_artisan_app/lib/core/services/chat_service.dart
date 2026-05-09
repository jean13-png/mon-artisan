import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Génère un ID de chat unique pour deux utilisateurs
  /// L'ID est toujours le même peu importe l'ordre des utilisateurs
  static String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  /// Crée ou récupère un chat entre deux utilisateurs
  static Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);
    
    print('[INFO] getOrCreateChat - ChatId: $chatId');
    print('[INFO] getOrCreateChat - Current: $currentUserName ($currentUserId)');
    print('[INFO] getOrCreateChat - Other: $otherUserName ($otherUserId)');

    // Vérifier si le chat existe
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      print('[INFO] getOrCreateChat - Chat n\'existe pas, création...');
      
      // Créer le chat avec les métadonnées
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'createdAt': Timestamp.now(),
        'lastMessageAt': Timestamp.now(),
        'lastMessage': '',
      });
      
      print('[SUCCESS] getOrCreateChat - Chat créé avec succès');
    } else {
      print('[INFO] getOrCreateChat - Chat existe déjà');
    }

    return chatId;
  }

  /// Envoie un message dans un chat
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    print('[INFO] sendMessage - ChatId: $chatId');
    print('[INFO] sendMessage - De: $senderId vers: $receiverId');
    print('[INFO] sendMessage - Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
    
    try {
      // Ajouter le message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });

      print('[INFO] sendMessage - Message ajouté à la collection messages');

      // Mettre à jour le dernier message du chat
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.now(),
        'lastMessage': message,
      });

      print('[SUCCESS] sendMessage - Chat mis à jour avec le dernier message');
    } catch (e) {
      print('[ERROR] sendMessage - Erreur: $e');
      rethrow;
    }
  }

  /// Récupère tous les chats d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      print('[INFO] getUserChats - Recherche des chats pour userId: $userId');
      
      // Récupérer tous les chats où l'utilisateur est participant
      // Sans orderBy pour éviter les problèmes d'index
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      print('[INFO] getUserChats - ${chatsSnapshot.docs.length} chat(s) trouvé(s) dans Firestore');

      List<Map<String, dynamic>> conversations = [];

      for (var chatDoc in chatsSnapshot.docs) {
        print('[INFO] getUserChats - Traitement du chat: ${chatDoc.id}');
        
        final chatData = chatDoc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        final participantNames = Map<String, dynamic>.from(chatData['participantNames'] ?? {});

        print('[INFO] getUserChats - Participants: $participants');
        print('[INFO] getUserChats - Noms: $participantNames');

        // Trouver l'autre utilisateur
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) {
          print('[WARNING] getUserChats - Impossible de trouver l\'autre utilisateur dans ${chatDoc.id}');
          continue;
        }

        final otherUserName = participantNames[otherUserId] ?? 'Utilisateur';
        final lastMessage = chatData['lastMessage'] ?? '';
        final lastMessageAt = chatData['lastMessageAt'] as Timestamp?;

        print('[INFO] getUserChats - Autre utilisateur: $otherUserName ($otherUserId)');
        print('[INFO] getUserChats - Dernier message: $lastMessage');

        // Compter les messages non lus
        final unreadSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        print('[INFO] getUserChats - Messages non lus: ${unreadSnapshot.docs.length}');

        conversations.add({
          'chatId': chatDoc.id,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'lastMessage': lastMessage,
          'timestamp': lastMessageAt?.toDate() ?? DateTime.now(),
          'unreadCount': unreadSnapshot.docs.length,
        });
      }

      // Trier par date (côté client)
      conversations.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });

      print('[SUCCESS] getUserChats - ${conversations.length} conversation(s) retournée(s)');
      return conversations;
    } catch (e) {
      print('[ERROR] getUserChats - Erreur: $e');
      print('[ERROR] getUserChats - Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Marque tous les messages d'un chat comme lus
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('[ERROR] Erreur marquage messages lus: $e');
    }
  }

  /// Compte le nombre total de messages non lus pour un utilisateur
  static Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (var chatDoc in chatsSnapshot.docs) {
        final unreadSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        totalUnread += unreadSnapshot.docs.length;
      }

      return totalUnread;
    } catch (e) {
      print('[ERROR] Erreur comptage messages non lus: $e');
      return 0;
    }
  }

  /// Supprime un chat et tous ses messages
  static Future<void> deleteChat(String chatId) async {
    try {
      // Supprimer tous les messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer le chat
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
    } catch (e) {
      print('[ERROR] Erreur suppression chat: $e');
      rethrow;
    }
  }
}

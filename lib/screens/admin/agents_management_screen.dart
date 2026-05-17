import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../models/agent_model.dart';
import '../../models/user_model.dart';

class AgentsManagementScreen extends StatefulWidget {
  const AgentsManagementScreen({super.key});

  @override
  State<AgentsManagementScreen> createState() => _AgentsManagementScreenState();
}

class _AgentsManagementScreenState extends State<AgentsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppRouter.adminDashboard);
            }
          },
        ),
        title: Text(
          'Gestion des agents',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Agents actifs'),
            Tab(text: 'Demandes (Pending)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.white),
            onPressed: _showAddAgentDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveAgentsList(),
          _buildPendingRequestsList(),
        ],
      ),
    );
  }

  Widget _buildActiveAgentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection('agents')
          .orderBy('nombreInscriptions', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucun agent actif', Icons.badge_outlined, true);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final agent = AgentModel.fromFirestore(doc);
            return _buildAgentCard(agent);
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection('users')
          .where('agentStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucune demande en attente', Icons.hourglass_empty, false);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final user = UserModel.fromFirestore(doc);
            return _buildPendingRequestCard(user);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool showAddButton) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.greyMedium),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.h3.copyWith(color: AppColors.greyDark)),
          if (showAddButton) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddAgentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un agent'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppColors.primaryBlue, child: Icon(Icons.person, color: AppColors.white)),
            title: Text('${user.prenom} ${user.nom}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAgentRequest(user, false),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Rejeter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAgentRequest(user, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white),
                  child: const Text('Approuver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAgentRequest(UserModel user, bool approved) async {
    final TextEditingController codeController = TextEditingController();
    
    if (approved) {
      // Demander à l'admin de saisir le code promo pour cet agent
      final code = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Attribuer un code promo'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(hintText: 'Ex: AGENT007', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(context, codeController.text.trim().toUpperCase()), child: const Text('Valider')),
          ],
        ),
      );

      if (code == null || code.isEmpty) return;

      try {
        // 1. Mettre à jour l'utilisateur
        await FirebaseService.firestore.collection('users').doc(user.id).update({
          'agentStatus': 'approved',
          'isAgent': true,
          'codePromoAgent': code,
          'roles': FieldValue.arrayUnion(['agent']),
        });

        // 2. Créer l'entrée dans la collection agents
        await FirebaseService.firestore.collection('agents').doc(user.id).set({
          'userId': user.id,
          'nom': user.nom,
          'prenom': user.prenom,
          'telephone': user.telephone,
          'email': user.email,
          'ville': user.ville,
          'quartier': user.quartier,
          'codeParrainage': code,
          'nombreInscriptions': 0,
          'revenusTotal': 0.0,
          'revenusDisponibles': 0.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent approuvé !'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    } else {
      // Rejeter la demande
      await FirebaseService.firestore.collection('users').doc(user.id).update({
        'agentStatus': 'rejected',
        'isAgent': false,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande rejetée'), backgroundColor: AppColors.error));
    }
  }

  Widget _buildAgentCard(AgentModel agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: agent.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge,
                  color: agent.isActive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${agent.prenom} ${agent.nom}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${agent.codeParrainage}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: agent.isActive,
                onChanged: (value) => _toggleAgentStatus(agent.id, value),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.people,
                  agent.nombreInscriptions.toString(),
                  'Inscriptions',
                  AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.attach_money,
                  '${agent.revenusDisponibles.toStringAsFixed(0)} F',
                  'Disponible',
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.location_on,
                  agent.ville,
                  'Ville',
                  AppColors.greyDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.phone,
                  agent.telephone,
                  'Téléphone',
                  AppColors.greyDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.greyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleAgentStatus(String agentId, bool isActive) async {
    try {
      await FirebaseService.firestore
          .collection('agents')
          .doc(agentId)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Agent activé' : 'Agent désactivé'),
            backgroundColor: isActive ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddAgentDialog() {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final telephoneController = TextEditingController();
    final emailController = TextEditingController();
    final villeController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un agent', style: AppTextStyles.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code de parrainage',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: AGENT001',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (prenomController.text.isEmpty ||
                  nomController.text.isEmpty ||
                  codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs obligatoires'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                await FirebaseService.firestore.collection('agents').add({
                  'nom': nomController.text.trim(),
                  'prenom': prenomController.text.trim(),
                  'telephone': telephoneController.text.trim(),
                  'email': emailController.text.trim(),
                  'ville': villeController.text.trim(),
                  'quartier': '',
                  'codeParrainage': codeController.text.trim().toUpperCase(),
                  'nombreInscriptions': 0,
                  'revenusTotal': 0.0,
                  'revenusDisponibles': 0.0,
                  'isActive': true,
                  'createdAt': Timestamp.now(),
                  'updatedAt': Timestamp.now(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agent ajouté avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}


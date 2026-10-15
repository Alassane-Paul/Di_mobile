import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar_widget.dart';
import '../config/app_config.dart';
import 'surveillance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditing = false;
  final _displayNameController = TextEditingController();
  final _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<ChatProvider>().currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _statusController.text = user.status ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final uploadResult = await context.read<ChatProvider>().uploadFile(image.path);
      await context.read<ChatProvider>().updateProfile({
        'avatar': uploadResult['mediaUrl'],
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<ChatProvider>().updateProfile({
        'displayName': _displayNameController.text,
        'status': _statusController.text,
      });
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showServerConfigDialog() {
    final serverController = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuration Serveur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modifiez l\'adresse de l\'API backend (ex: http://192.168.1.50:5000/api ou https://api.votredomaine.com/api)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                labelText: 'URL API Backend',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newUrl = serverController.text.trim();
              if (newUrl.isNotEmpty) {
                AppConfig.baseUrl = newUrl;
                final root = newUrl.replaceAll('/api', '');
                AppConfig.socketUrl = root;
                AppConfig.serverUrl = root;
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final user = chatProvider.currentUser;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            backgroundColor: const Color(0xFF075E54),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveProfile,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await context.read<ChatProvider>().logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isEditing ? _pickAvatar : null,
                  child: Stack(
                    children: [
                      AvatarWidget(
                        imageUrl: user.avatar,
                        name: user.displayName,
                        size: 100,
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'affichage',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                else
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _statusController,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                else
                  Text(
                    user.status ?? 'Disponible',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSettingTile(
                  icon: Icons.visibility,
                  title: 'Mode Premium',
                  subtitle: 'Gestion personnelle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SurveillanceScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingTile(
                  icon: Icons.dns,
                  title: 'Serveur API & WebSocket',
                  subtitle: AppConfig.baseUrl,
                  onTap: _showServerConfigDialog,
                ),
                _buildSettingTile(
                  icon: Icons.account_circle,
                  title: 'Compte',
                  subtitle: 'Sécurité, notifications, langue',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.lock,
                  title: 'Confidentialité',
                  subtitle: 'Vu, statut en ligne, profil',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.chat,
                  title: 'Discussions',
                  subtitle: 'Thème, fond d\'écran, chat',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Messages, groupes, appels',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.storage,
                  title: 'Stockage et données',
                  subtitle: 'Gérer l\'espace de stockage',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.help,
                  title: 'Aide',
                  subtitle: 'Centre d\'aide, contactez-nous',
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF075E54)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

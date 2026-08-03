import 'package:flutter/material.dart';
import '../models/authentic_geo_photo.dart';

/// Renders a authentic geotag stamp watermark over photo previews or saved images.
class GeotagWatermarkOverlay extends StatelessWidget {
  final AuthenticGeoPhoto photo;
  final Widget child;

  const GeotagWatermarkOverlay({
    super.key,
    required this.photo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        
        // Top-Right Cryptographic Authenticity Badge
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF00E676), size: 14),
                const SizedBox(width: 6),
                Text(
                  'AUTH #${photo.cryptoHash}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Geotag Watermark Bar
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: photo.category.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(photo.category.icon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            photo.category.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      photo.isLiveCamera ? Icons.camera_alt_rounded : Icons.photo_library_rounded,
                      size: 13,
                      color: photo.isLiveCamera ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      photo.isLiveCamera ? 'Live In-App Photo' : 'Gallery Upload',
                      style: TextStyle(
                        color: photo.isLiveCamera ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        photo.formattedGeotag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      photo.formattedDateTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Accuracy: ±${photo.accuracyMeters.toStringAsFixed(1)}m',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.map_rounded, size: 12, color: Colors.white54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        photo.address,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

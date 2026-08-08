import 'package:flutter/material.dart';
import '../models/authentic_geo_photo.dart';

/// Renders an authentic "GPS Map Camera" geotag stamp with Google Maps Satellite thumbnail,
/// multi-line detailed address, exact Lat/Long coordinates, and AI authenticity score.
class GeotagWatermarkOverlay extends StatelessWidget {
  final AuthenticGeoPhoto photo;
  final Widget child;
  final String? customLabel;

  const GeotagWatermarkOverlay({
    super.key,
    required this.photo,
    required this.child,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ai = photo.aiVerification;
    final geo = photo.geotag;

    return Stack(
      children: [
        child,

        // Top-Right AI Authenticity Score & Crypto Proof Token
        Positioned(
          top: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ai.isRealPhoto ? const Color(0xFF00E676) : Colors.orangeAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ai.isRealPhoto ? Icons.verified_user_rounded : Icons.warning_rounded,
                      color: ai.isRealPhoto ? const Color(0xFF00E676) : Colors.orangeAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI Score: ${ai.formattedPercentage} (${ai.isRealPhoto ? "Real Photo" : "AI Warning"})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AUTH #${photo.cryptoHash}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Custom Mode Badge (e.g. BEFORE RECYCLE / AFTER RECYCLE)
        if (customLabel != null)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: photo.category.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
              ),
              child: Text(
                customLabel!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Bottom "GPS Map Camera" Geotag Watermark Overlay Card
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Google Maps Satellite Thumbnail Preview Box
                Container(
                  width: 95,
                  height: 105,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white54, width: 1.2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://tile.openstreetmap.org/17/93863/56241.png',
                      ),
                      fit: BoxFit.cover,
                      onError: null,
                    ),
                    color: const Color(0xFF1E2D1F),
                  ),
                  child: Stack(
                    children: [
                      // Dark Satellite Overlay Grid Pattern
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      // Center Red Google Pin Marker
                      const Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 32,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 6),
                          ],
                        ),
                      ),
                      // Google Logo Branding at Bottom Left
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Google',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Multi-line Detailed Google Maps Location & Timestamp Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: GPS Map Camera Badge
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.blueAccent, size: 10),
                                SizedBox(width: 3),
                                Text(
                                  'GPS Map Camera',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Line 1: City, State, Country Header
                      Text(
                        '${geo.city}, ${geo.state}, ${geo.country} 🇮🇳',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Line 2: Detailed Street & Sublocality Line 1
                      Text(
                        '${geo.addressLine1},',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),

                      // Line 3: City, State Pincode, Country Line 2
                      Text(
                        geo.addressLine2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Line 4: Latitude & Longitude Line
                      Text(
                        'Lat ${photo.latitude.abs().toStringAsFixed(6)}° Long ${photo.longitude.abs().toStringAsFixed(6)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Line 5: Day, Full Date & GMT Timestamp Line
                      Text(
                        '${_dayOfWeek(photo.timestamp)}, ${_formatDateSlash(photo.timestamp)} ${_formatTimeAmPm(photo.timestamp)} ${geo.timeZoneOffset.replaceAll('UTC', 'GMT')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _dayOfWeek(DateTime dt) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(dt.weekday - 1) % 7];
  }

  static String _formatDateSlash(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  static String _formatTimeAmPm(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute:$second $amPm';
  }
}

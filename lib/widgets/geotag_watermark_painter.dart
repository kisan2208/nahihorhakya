import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/authentic_geo_photo.dart';
import '../services/geotag_service.dart';

/// A small, current-location map used in both the live capture screen and the
/// stamped photo preview. It deliberately uses an OpenStreetMap tile while the
/// surrounding UI keeps the familiar GPS camera layout.
class GeotagMapThumbnail extends StatelessWidget {
  final GeotagData geotag;
  final double width;
  final double height;
  final double borderRadius;

  const GeotagMapThumbnail({
    super.key,
    required this.geotag,
    this.width = 94,
    this.height = 104,
    this.borderRadius = 11,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = geotag.latitude != 0 || geotag.longitude != 0;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            border: Border.all(color: Colors.white54),
          ),
          child: hasCoordinates
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _tileUrl(geotag.latitude, geotag.longitude),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const _MapFallback(),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFF4D5E),
                        size: 34,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 6),
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 5,
                      bottom: 4,
                      child: Text(
                        'MAP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const _MapFallback(),
        ),
      ),
    );
  }

  static String _tileUrl(double latitude, double longitude) {
    const zoom = 16;
    final n = 1 << zoom;
    final x = (((longitude + 180) / 360) * n).floor().clamp(0, n - 1);
    final latitudeRadians = latitude * math.pi / 180;
    final mercator = math.log(math.tan(math.pi / 4 + latitudeRadians / 2));
    final y = ((1 - mercator / math.pi) / 2 * n).floor().clamp(0, n - 1);
    return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.map_outlined, color: Colors.white54, size: 28),
    );
  }
}

/// Renders the GPS Map Camera-style stamp shown on captured images.
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

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ai.isRealPhoto
                        ? const Color(0xFF00E676)
                        : Colors.orangeAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ai.isRealPhoto
                          ? Icons.verified_user_rounded
                          : Icons.warning_rounded,
                      color: ai.isRealPhoto
                          ? const Color(0xFF00E676)
                          : Colors.orangeAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI score: ${ai.formattedPercentage}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
        if (customLabel != null)
          Positioned(
            top: 14,
            left: 14,
            child: _ModeBadge(label: customLabel!, color: photo.category.color),
          ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: _GeotagStamp(photo: photo),
        ),
      ],
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GeotagStamp extends StatelessWidget {
  final AuthenticGeoPhoto photo;

  const _GeotagStamp({required this.photo});

  @override
  Widget build(BuildContext context) {
    final geo = photo.geotag;
    final title = [
      geo.city,
      geo.state,
      geo.country,
    ].where((item) => item.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeotagMapThumbnail(geotag: geo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: _GpsCameraLabel(),
                ),
                const SizedBox(height: 2),
                Text(
                  title.isEmpty ? 'Location unavailable' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  geo.addressLine1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  geo.addressLine2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lat ${photo.latitude.abs().toStringAsFixed(6)} deg  Long ${photo.longitude.abs().toStringAsFixed(6)} deg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dayOfWeek(photo.timestamp)}, ${_formatDate(photo.timestamp)} ${_formatTime(photo.timestamp)} ${geo.timeZoneOffset.replaceFirst('UTC', 'GMT')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dayOfWeek(DateTime value) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[value.weekday - 1];
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _formatTime(DateTime value) {
    final hour =
        value.hour > 12 ? value.hour - 12 : (value.hour == 0 ? 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute:$second ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _GpsCameraLabel extends StatelessWidget {
  const _GpsCameraLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_rounded, color: Color(0xFF64B5F6), size: 10),
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
    );
  }
}

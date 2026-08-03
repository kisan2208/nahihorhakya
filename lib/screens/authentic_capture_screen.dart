import 'package:flutter/material.dart';
import '../models/action_category.dart';
import '../models/authentic_geo_photo.dart';
import '../services/proximity_tracker_service.dart';
import '../theme.dart';
import '../glass.dart';
import '../widgets/geotag_watermark_painter.dart';

/// Screen displaying the Geotagged Authentic Photo Capture with 30m Proximity Warning.
class AuthenticCaptureScreen extends StatefulWidget {
  const AuthenticCaptureScreen({super.key});

  @override
  State<AuthenticCaptureScreen> createState() => _AuthenticCaptureScreenState();
}

class _AuthenticCaptureScreenState extends State<AuthenticCaptureScreen> {
  final ProximityTrackerService _proximityTracker = ProximityTrackerService();

  late ActionCategory _selectedCategory;
  
  // Simulated user GPS position (Default center: Ward 12, Pune)
  double _currentLat = 18.52042;
  double _currentLng = 73.85673;

  late ProximityCheckResult _proximityResult;
  AuthenticGeoPhoto? _capturedPhoto;
  bool _isLiveCapture = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ActionCategory.defaultCategory;
    _evaluateProximity();
  }

  void _evaluateProximity() {
    if (_selectedCategory.requiresProximityCheck) {
      _proximityResult = _proximityTracker.checkTreeProximity(
        _currentLat,
        _currentLng,
        radiusMeters: _selectedCategory.proximityRadiusMeters,
      );
    } else {
      _proximityResult = ProximityCheckResult.clear;
    }
  }

  void _onCategoryChanged(ActionCategory cat) {
    setState(() {
      _selectedCategory = cat;
      _evaluateProximity();
    });
  }

  void _capturePhoto() {
    final photo = AuthenticGeoPhoto(
      id: 'GEO_${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      timestamp: DateTime.now(),
      latitude: _currentLat,
      longitude: _currentLng,
      address: 'Ward 12, Pune, Maharashtra 411005',
      isLiveCamera: _isLiveCapture,
    );

    setState(() {
      _capturedPhoto = photo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Authentic Geotag Capture',
              style: AppTheme.display(16, c: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              'Time • Place • Anti-Spoof Proof',
              style: AppTheme.body(11, c: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _capturedPhoto != null ? _buildCapturedResultView() : _buildCameraCaptureView(),
    );
  }

  /// Camera capture viewfinder with category selector and 30m proximity warning banner.
  Widget _buildCameraCaptureView() {
    return Stack(
      children: [
        // Simulated Camera Viewfinder Grid
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _selectedCategory.color.withValues(alpha: 0.35),
                  const Color(0xFF11170F),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _selectedCategory.icon,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 340,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _proximityResult.hasNearbyTree
                            ? AppColors.danger
                            : AppColors.accent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main Overlay Controls
        SafeArea(
          child: Column(
            children: [
              // 1. Category Selector Horizontal Bar
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: ActionCategory.allCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = ActionCategory.allCategories[idx];
                    final isSelected = cat.id == _selectedCategory.id;
                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? Colors.white : cat.color,
                      ),
                      label: Text(
                        cat.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selectedColor: cat.color,
                      backgroundColor: Colors.black45,
                      side: BorderSide(
                        color: isSelected ? cat.color : Colors.white24,
                      ),
                      onSelected: (_) => _onCategoryChanged(cat),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 2. 30-Meter Proximity Warning Banner (Appears when tree planted near < 30m)
              if (_selectedCategory.requiresProximityCheck && _proximityResult.hasNearbyTree)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _proximityResult.warningLevel == ProximityWarningLevel.critical
                          ? AppColors.danger.withValues(alpha: 0.9)
                          : const Color(0xFFE65100).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '30m Proximity Duplicate Warning',
                                style: AppTheme.body(12.5, w: FontWeight.bold, c: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _proximityResult.warningMessage,
                                style: AppTheme.body(11, c: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                          onPressed: () => _showProximityDetailDialog(),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // 3. Location Simulation & Geotag Status Controller
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${_currentLat.toStringAsFixed(5)}°, ${_currentLng.toStringAsFixed(5)}°',
                            style: AppTheme.body(11.5, w: FontWeight.bold, c: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: const Text(
                              'Authentic GPS',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Distance Slider Simulation Control
                      Row(
                        children: [
                          Text('Simulate Proximity:', style: AppTheme.body(11, c: Colors.white70)),
                          Expanded(
                            child: Slider(
                              value: _currentLat,
                              min: 18.52040, // 5m near tree
                              max: 18.52180, // ~160m away
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                setState(() {
                                  _currentLat = val;
                                  _evaluateProximity();
                                });
                              },
                            ),
                          ),
                          Text(
                            _proximityResult.hasNearbyTree
                                ? '${_proximityResult.closestDistanceMeters.toStringAsFixed(1)}m'
                                : '>30m Clear',
                            style: TextStyle(
                              color: _proximityResult.hasNearbyTree ? Colors.amber : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Shutter Controls Row
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mode Toggle (Live Camera vs Gallery test)
                    IconButton(
                      icon: Icon(
                        _isLiveCapture ? Icons.camera_alt_rounded : Icons.photo_library_rounded,
                        color: _isLiveCapture ? AppColors.accent : Colors.orangeAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _isLiveCapture = !_isLiveCapture;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isLiveCapture ? 'Switched to Live Camera Capture' : 'Testing Gallery Upload Mode',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),

                    // Primary Shutter Button
                    GestureDetector(
                      onTap: _capturePhoto,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _proximityResult.hasNearbyTree ? AppColors.danger : Colors.white,
                            width: 4,
                          ),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _proximityResult.hasNearbyTree ? AppColors.danger : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedCategory.icon,
                            color: _proximityResult.hasNearbyTree ? Colors.white : _selectedCategory.color,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 48), // Balance shutter position
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Displays the captured authentic geotagged photo preview.
  Widget _buildCapturedResultView() {
    final photo = _capturedPhoto!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GeotagWatermarkOverlay(
                  photo: photo,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF1E281F),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(photo.category.icon, size: 90, color: photo.category.color),
                          const SizedBox(height: 16),
                          Text(
                            'Photo Captured with Geotag',
                            style: AppTheme.display(18, c: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake Photo'),
                    onPressed: () {
                      setState(() {
                        _capturedPhoto = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Submit Geotag'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Authentic ${photo.category.title} geotag submitted! Crypto Hash: #${photo.cryptoHash}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProximityDetailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E281F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tree Proximity Warning',
                style: AppTheme.display(16, c: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our anti-duplicate system detected existing trees within 30 meters of your current coordinates:',
              style: AppTheme.body(12.5, c: Colors.white70),
            ),
            const SizedBox(height: 12),
            ..._proximityResult.nearbyTrees.map(
              (tree) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tree.treeSpecies,
                        style: AppTheme.body(12, w: FontWeight.bold, c: Colors.greenAccent),
                      ),
                      Text(
                        'Distance: ${tree.distanceTo(_currentLat, _currentLng).toStringAsFixed(1)}m • Planter: ${tree.planterName}',
                        style: AppTheme.body(11, c: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

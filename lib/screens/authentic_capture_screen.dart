import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../models/action_category.dart';
import '../models/authentic_geo_photo.dart';
import '../services/ai_verification_service.dart';
import '../services/eco_action_backend.dart';
import '../theme.dart';
import '../glass.dart';
import '../widgets/geotag_watermark_painter.dart';

/// Screen using real physical hardware camera capture & real device GPS location.
class AuthenticCaptureScreen extends StatefulWidget {
  const AuthenticCaptureScreen({super.key});

  @override
  State<AuthenticCaptureScreen> createState() => _AuthenticCaptureScreenState();
}

class _AuthenticCaptureScreenState extends State<AuthenticCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final EcoActionBackend _backend = EcoActionBackend();
  final AIVerificationService _aiService = AIVerificationService();

  late ActionCategory _selectedCategory;
  
  // Real or Simulated GPS Position
  double _currentLat = 18.52042;
  double _currentLng = 73.85673;
  bool _usingRealGPS = false;

  late ProximityCheckResult _proximityResult;
  
  AuthenticGeoPhoto? _firstPhoto;
  AuthenticGeoPhoto? _secondPhoto;
  
  bool _isLiveCapture = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ActionCategory.defaultCategory;
    _evaluateProximity();
    _initDeviceLocation();
  }

  /// Attempts to fetch real hardware GPS coordinates from phone.
  Future<void> _initDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
          _usingRealGPS = true;
          _evaluateProximity();
        });
      }
    } catch (_) {
      // Fallback to simulated coordinates if permissions or GPS unavailable
    }
  }

  void _evaluateProximity() {
    if (_selectedCategory.requiresProximityCheck) {
      _proximityResult = _backend.check30mProximity(
        currentLat: _currentLat,
        currentLng: _currentLng,
        categoryId: _selectedCategory.id,
        radiusMeters: _selectedCategory.proximityRadiusMeters,
      );
    } else {
      _proximityResult = ProximityCheckResult.clear;
    }
  }

  void _onCategoryChanged(ActionCategory cat) {
    setState(() {
      _selectedCategory = cat;
      _firstPhoto = null;
      _secondPhoto = null;
      _evaluateProximity();
    });
  }

  /// Triggers the real physical phone camera hardware via ImagePicker.
  Future<void> _takePhotoWithCamera() async {
    try {
      final ImageSource source = _isLiveCapture ? ImageSource.camera : ImageSource.gallery;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return; // User cancelled capture

      setState(() => _isProcessing = true);

      // AI Image Verification
      final aiResult = await _aiService.verifyPhotoIntegrity(
        imagePath: pickedFile.path,
        isLiveCamera: _isLiveCapture,
      );

      final photo = AuthenticGeoPhoto(
        id: 'GEO_${DateTime.now().millisecondsSinceEpoch}',
        category: _selectedCategory,
        timestamp: DateTime.now(),
        latitude: _currentLat,
        longitude: _currentLng,
        address: _usingRealGPS ? 'Live Device GPS Location' : 'Ward 12, Pune, Maharashtra 411005',
        isLiveCamera: _isLiveCapture,
        aiVerification: aiResult,
        imagePath: pickedFile.path,
      );

      setState(() {
        _isProcessing = false;
        if (_selectedCategory.requiresDualPhoto && _firstPhoto == null) {
          _firstPhoto = photo;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Step 1 Captured: Product BEFORE Recycling! Now capture Step 2 (AFTER).'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else if (_selectedCategory.requiresDualPhoto && _firstPhoto != null) {
          _secondPhoto = photo;
        } else {
          _firstPhoto = photo;
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _submitToBackend() async {
    if (_firstPhoto == null) return;

    final finalPhoto = _selectedCategory.requiresDualPhoto && _secondPhoto != null
        ? AuthenticGeoPhoto(
            id: _firstPhoto!.id,
            category: _firstPhoto!.category,
            timestamp: _firstPhoto!.timestamp,
            latitude: _firstPhoto!.latitude,
            longitude: _firstPhoto!.longitude,
            address: _firstPhoto!.address,
            isLiveCamera: _firstPhoto!.isLiveCamera,
            aiVerification: _firstPhoto!.aiVerification,
            imagePath: _firstPhoto!.imagePath,
            secondaryImagePath: _secondPhoto!.imagePath,
            secondaryTimestamp: _secondPhoto!.timestamp,
          )
        : _firstPhoto!;

    await _backend.saveAction(finalPhoto);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Real Photo & Geotag saved to backend! Hash: #${finalPhoto.cryptoHash}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDualMode = _selectedCategory.requiresDualPhoto;
    final isComplete = isDualMode ? (_firstPhoto != null && _secondPhoto != null) : (_firstPhoto != null);

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
            Text('Authentic Geotag Capture', style: AppTheme.display(16, c: Colors.white)),
            const SizedBox(height: 2),
            Text('Live Phone Camera • Hardware GPS', style: AppTheme.body(11, c: Colors.white70)),
          ],
        ),
        centerTitle: true,
      ),
      body: isComplete ? _buildResultPreviewView() : _buildCameraCaptureView(),
    );
  }

  Widget _buildCameraCaptureView() {
    final isDualMode = _selectedCategory.requiresDualPhoto;
    final currentStepLabel = isDualMode
        ? (_firstPhoto == null ? 'Photo 1 of 2: Take Picture BEFORE Recycling' : 'Photo 2 of 2: Take Picture AFTER Recycling')
        : 'Tap Shutter to Open Phone Camera';

    return Stack(
      children: [
        // Camera viewfinder representation
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
                        color: _proximityResult.hasNearbyAction ? AppColors.danger : AppColors.accent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Colors.white.withValues(alpha: 0.6), size: 48),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Tap red button below to trigger real hardware camera',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(12, c: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // UI Controls Overlay
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Category selector bar
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
                      avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
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
                      side: BorderSide(color: isSelected ? cat.color : Colors.white24),
                      onSelected: (_) => _onCategoryChanged(cat),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(currentStepLabel, style: AppTheme.body(11.5, w: FontWeight.bold, c: Colors.white)),
              ),

              const SizedBox(height: 8),

              // 30m Proximity Banner
              if (_selectedCategory.requiresProximityCheck && _proximityResult.hasNearbyAction)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('30m Proximity Duplicate Warning', style: AppTheme.body(12, w: FontWeight.bold, c: Colors.white)),
                              const SizedBox(height: 2),
                              Text(_proximityResult.warningMessage, style: AppTheme.body(10.5, c: Colors.white.withValues(alpha: 0.9))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // GPS Status Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.my_location_rounded, color: _usingRealGPS ? Colors.greenAccent : AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${_currentLat.toStringAsFixed(5)}°, ${_currentLng.toStringAsFixed(5)}°',
                            style: AppTheme.body(11.5, w: FontWeight.bold, c: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_usingRealGPS ? Colors.green : Colors.blue).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _usingRealGPS ? Colors.greenAccent : AppColors.accent),
                            ),
                            child: Text(
                              _usingRealGPS ? 'Real Phone GPS' : 'Simulated GPS',
                              style: TextStyle(color: _usingRealGPS ? Colors.greenAccent : AppColors.accent, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategory.requiresProximityCheck)
                        Row(
                          children: [
                            Text('Simulate Proximity:', style: AppTheme.body(11, c: Colors.white70)),
                            Expanded(
                              child: Slider(
                                value: _currentLat,
                                min: 18.52040,
                                max: 18.52180,
                                activeColor: AppColors.accent,
                                onChanged: (val) {
                                  setState(() {
                                    _currentLat = val;
                                    _usingRealGPS = false;
                                    _evaluateProximity();
                                  });
                                },
                              ),
                            ),
                            Text(
                              _proximityResult.hasNearbyAction ? '${_proximityResult.closestDistanceMeters.toStringAsFixed(1)}m' : '>30m Clear',
                              style: TextStyle(
                                color: _proximityResult.hasNearbyAction ? Colors.amber : Colors.greenAccent,
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

              // Hardware Shutter Button Row
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiveCapture ? Icons.camera_alt_rounded : Icons.photo_library_rounded,
                        color: _isLiveCapture ? AppColors.accent : Colors.orangeAccent,
                      ),
                      onPressed: () {
                        setState(() => _isLiveCapture = !_isLiveCapture);
                      },
                    ),

                    // Shutter Button -> Triggers Phone Camera
                    GestureDetector(
                      onTap: _isProcessing ? null : _takePhotoWithCamera,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _proximityResult.hasNearbyAction ? AppColors.danger : Colors.white,
                            width: 4,
                          ),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _proximityResult.hasNearbyAction ? AppColors.danger : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Icon(
                                  Icons.camera_alt_rounded,
                                  color: _proximityResult.hasNearbyAction ? Colors.white : _selectedCategory.color,
                                  size: 34,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultPreviewView() {
    final isDualMode = _selectedCategory.requiresDualPhoto;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isDualMode
                  ? Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GeotagWatermarkOverlay(
                              photo: _firstPhoto!,
                              customLabel: '1. BEFORE RECYCLE',
                              child: _displayCapturedImage(_firstPhoto!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GeotagWatermarkOverlay(
                              photo: _secondPhoto!,
                              customLabel: '2. AFTER RECYCLE',
                              child: _displayCapturedImage(_secondPhoto!),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GeotagWatermarkOverlay(
                        photo: _firstPhoto!,
                        child: _displayCapturedImage(_firstPhoto!),
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
                    label: const Text('Retake Real Photo'),
                    onPressed: () {
                      setState(() {
                        _firstPhoto = null;
                        _secondPhoto = null;
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
                    label: const Text('Save to Backend'),
                    onPressed: _submitToBackend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayCapturedImage(AuthenticGeoPhoto photo) {
    if (photo.imagePath != null && photo.imagePath!.isNotEmpty && File(photo.imagePath!).existsSync()) {
      return Image.file(
        File(photo.imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E281F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(photo.category.icon, size: 70, color: photo.category.color),
            const SizedBox(height: 12),
            Text(photo.category.title, style: AppTheme.display(16, c: Colors.white)),
          ],
        ),
      ),
    );
  }
}

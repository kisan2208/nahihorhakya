import 'package:flutter/material.dart';
import '../models/action_category.dart';
import '../models/authentic_geo_photo.dart';
import '../services/ai_verification_service.dart';
import '../services/eco_action_backend.dart';
import '../theme.dart';
import '../glass.dart';
import '../widgets/geotag_watermark_painter.dart';

/// Comprehensive Authentic Photo Capture Screen with AI check, dual-photo recycle proof, and 30m tree/beach proximity warning.
class AuthenticCaptureScreen extends StatefulWidget {
  const AuthenticCaptureScreen({super.key});

  @override
  State<AuthenticCaptureScreen> createState() => _AuthenticCaptureScreenState();
}

class _AuthenticCaptureScreenState extends State<AuthenticCaptureScreen> {
  final EcoActionBackend _backend = EcoActionBackend();
  final AIVerificationService _aiService = AIVerificationService();

  late ActionCategory _selectedCategory;
  
  // Simulated user GPS position (Default center: Ward 12, Pune)
  double _currentLat = 18.52042;
  double _currentLng = 73.85673;

  late ProximityCheckResult _proximityResult;
  
  // Single & Dual Photo states
  AuthenticGeoPhoto? _firstPhoto; // Single photo or "BEFORE" photo
  AuthenticGeoPhoto? _secondPhoto; // "AFTER" photo for dual-photo mode (Recycle)
  
  bool _isLiveCapture = true;
  bool _isAnalyzingAI = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ActionCategory.defaultCategory;
    _evaluateProximity();
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

  Future<void> _capturePhoto() async {
    setState(() => _isAnalyzingAI = true);

    final aiResult = await _aiService.verifyPhotoIntegrity(
      imagePath: 'simulated_camera_stream.jpg',
      isLiveCamera: _isLiveCapture,
    );

    final photo = AuthenticGeoPhoto(
      id: 'GEO_${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      timestamp: DateTime.now(),
      latitude: _currentLat,
      longitude: _currentLng,
      address: 'Ward 12, Pune, Maharashtra 411005',
      isLiveCamera: _isLiveCapture,
      aiVerification: aiResult,
      imagePath: 'captured_img_1.jpg',
    );

    setState(() {
      _isAnalyzingAI = false;
      if (_selectedCategory.requiresDualPhoto && _firstPhoto == null) {
        // Step 1 of Dual Photo (BEFORE)
        _firstPhoto = photo;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Step 1 Captured: Product BEFORE Recycling! Now capture Step 2 (AFTER).'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (_selectedCategory.requiresDualPhoto && _firstPhoto != null) {
        // Step 2 of Dual Photo (AFTER)
        _secondPhoto = photo;
      } else {
        // Single Photo mode (Tree, Beach Clean, Compost, Segregate)
        _firstPhoto = photo;
      }
    });
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
            '✅ Authentic ${finalPhoto.category.title} submitted to backend! Crypto Hash: #${finalPhoto.cryptoHash}',
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
            Text(
              'Authentic Geotag Capture',
              style: AppTheme.display(16, c: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              'Time • Place • AI Authenticity Proof',
              style: AppTheme.body(11, c: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isComplete ? _buildResultPreviewView() : _buildCameraCaptureView(),
    );
  }

  /// Camera capture viewfinder UI.
  Widget _buildCameraCaptureView() {
    final isDualMode = _selectedCategory.requiresDualPhoto;
    final currentStepLabel = isDualMode
        ? (_firstPhoto == null ? 'Photo 1 of 2: Capture Product BEFORE Recycling' : 'Photo 2 of 2: Capture Product AFTER Recycling')
        : 'Capture 1 Authentic Photo';

    return Stack(
      children: [
        // Camera Viewfinder Background
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
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls Overlay
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 1. Category Selector Bar
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

              // Step Indicator Pill for Dual Photo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(
                  currentStepLabel,
                  style: AppTheme.body(11.5, w: FontWeight.bold, c: Colors.white),
                ),
              ),

              const SizedBox(height: 8),

              // 2. 30-Meter Proximity Warning Banner (Tree Planting & Beach Clean ONLY)
              if (_selectedCategory.requiresProximityCheck && _proximityResult.hasNearbyAction)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
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
                                style: AppTheme.body(12, w: FontWeight.bold, c: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _proximityResult.warningMessage,
                                style: AppTheme.body(10.5, c: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // 3. Location Simulation & GPS Status Card
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
                      // Distance Slider for Testing 30m Rule on Tree / Beach Clean
                      if (_selectedCategory.requiresProximityCheck)
                        Row(
                          children: [
                            Text('Simulate Proximity:', style: AppTheme.body(11, c: Colors.white70)),
                            Expanded(
                              child: Slider(
                                value: _currentLat,
                                min: 18.52040, // 5m near anchor
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
                              _proximityResult.hasNearbyAction
                                  ? '${_proximityResult.closestDistanceMeters.toStringAsFixed(1)}m'
                                  : '>30m Clear',
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

              // 4. Shutter Control Row
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

                    // Shutter Button
                    GestureDetector(
                      onTap: _isAnalyzingAI ? null : _capturePhoto,
                      child: Container(
                        width: 76,
                        height: 76,
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
                          child: _isAnalyzingAI
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Icon(
                                  _selectedCategory.icon,
                                  color: _proximityResult.hasNearbyAction ? Colors.white : _selectedCategory.color,
                                  size: 32,
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

  /// Displays captured result preview (Dual-Photo side-by-side for Recycle, Single-Photo for others).
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
                              child: _photoPlaceholder('Product Before Recycling'),
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
                              child: _photoPlaceholder('Processed Product After Recycling'),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GeotagWatermarkOverlay(
                        photo: _firstPhoto!,
                        child: _photoPlaceholder('Authentic Geotagged Capture'),
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
                    label: const Text('Retake'),
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

  Widget _photoPlaceholder(String label) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E281F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_selectedCategory.icon, size: 70, color: _selectedCategory.color),
            const SizedBox(height: 12),
            Text(label, style: AppTheme.display(16, c: Colors.white)),
          ],
        ),
      ),
    );
  }
}

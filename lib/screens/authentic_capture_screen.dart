import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../models/action_category.dart';
import '../models/authentic_geo_photo.dart';
import '../services/ai_verification_service.dart';
import '../services/eco_action_backend.dart';
import '../services/geotag_service.dart';
import '../theme.dart';
import '../widgets/geotag_watermark_painter.dart';

/// GPS Map Camera-style capture flow. The camera and GPS warm up when this
/// screen opens, so pressing the shutter does not re-request location or make
/// a reverse-geocoding request.
class AuthenticCaptureScreen extends StatefulWidget {
  const AuthenticCaptureScreen({super.key});

  @override
  State<AuthenticCaptureScreen> createState() => _AuthenticCaptureScreenState();
}

class _AuthenticCaptureScreenState extends State<AuthenticCaptureScreen>
    with WidgetsBindingObserver {
  final EcoActionBackend _backend = EcoActionBackend();
  final AIVerificationService _aiService = AIVerificationService();
  final GeotagService _geotagService = GeotagService();
  final picker.ImagePicker _fallbackPicker = picker.ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _activeLens = CameraLensDirection.back;

  late ActionCategory _selectedCategory;
  late GeotagData _currentGeotag;
  late ProximityCheckResult _proximityResult;

  AuthenticGeoPhoto? _firstPhoto;
  AuthenticGeoPhoto? _secondPhoto;

  bool _isLoadingLocation = true;
  bool _hasLocationPermission = true;
  bool _isCameraInitializing = true;
  bool _cameraUnavailable = false;
  bool _isCapturing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCategory = ActionCategory.defaultCategory;
    _currentGeotag = GeotagData.defaultFallback();
    _evaluateProximity();
    _prepareCapture();
  }

  /// Start independent setup work together. Neither the camera preview nor GPS
  /// loading waits for persisted activity data to be read.
  Future<void> _prepareCapture() async {
    _initializeCamera();
    _fetchRealGeotag();
    await _backend.initialize();
    if (mounted) {
      setState(_evaluateProximity);
    }
  }

  Future<void> _initializeCamera({CameraLensDirection? preferredLens}) async {
    if (_isCameraInitializing && _cameraController != null) return;

    if (mounted) {
      setState(() {
        _isCameraInitializing = true;
        _cameraUnavailable = false;
      });
    }

    try {
      _cameras = _cameras.isEmpty ? await availableCameras() : _cameras;
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera is available.');
      }

      final direction = preferredLens ?? _activeLens;
      final description = _cameras.firstWhere(
        (camera) => camera.lensDirection == direction,
        orElse: () => _cameras.first,
      );
      final previousController = _cameraController;
      _cameraController = null;
      await previousController?.dispose();

      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _activeLens = description.lensDirection;
        _isCameraInitializing = false;
      });
    } on CameraException {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _isCameraInitializing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _fetchRealGeotag() async {
    if (mounted) setState(() => _isLoadingLocation = true);

    // Ask once. captureRealGeotag receives that result and never asks again.
    final permissionGranted = await _geotagService.requestLocationPermission();
    final geotag = await _geotagService.captureRealGeotag(
      requestPermission: false,
    );

    if (!mounted) return;
    setState(() {
      _hasLocationPermission = permissionGranted;
      _currentGeotag = geotag;
      _isLoadingLocation = false;
      _evaluateProximity();
    });
  }

  void _evaluateProximity() {
    final latitude = _currentGeotag.latitude;
    final longitude = _currentGeotag.longitude;

    _proximityResult = _selectedCategory.requiresProximityCheck
        ? _backend.check30mProximity(
            currentLat: latitude,
            currentLng: longitude,
            categoryId: _selectedCategory.id,
            radiusMeters: _selectedCategory.proximityRadiusMeters,
          )
        : ProximityCheckResult.clear;
  }

  void _onCategoryChanged(ActionCategory category) {
    setState(() {
      _selectedCategory = category;
      _firstPhoto = null;
      _secondPhoto = null;
      _evaluateProximity();
    });
  }

  Future<void> _switchCamera() async {
    if (_isCameraInitializing || _cameras.length < 2) return;
    final nextLens = _activeLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _initializeCamera(preferredLens: nextLens);
  }

  /// Captures from the already-running viewfinder. The only fallback uses the
  /// system camera if this device cannot start the embedded preview.
  Future<void> _takePhoto() async {
    if (_isCapturing || _isLoadingLocation) return;

    setState(() => _isCapturing = true);
    try {
      String? imagePath;
      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) {
        final photo = await controller.takePicture();
        imagePath = photo.path;
      } else {
        final photo = await _fallbackPicker.pickImage(
          source: picker.ImageSource.camera,
          imageQuality: 95,
        );
        imagePath = photo?.path;
      }

      if (imagePath == null || imagePath.isEmpty) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      await _registerCapture(imagePath);
    } catch (error) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _registerCapture(String imagePath) async {
    final captureTime = DateTime.now();
    final photo = AuthenticGeoPhoto(
      id: 'GEO_${captureTime.millisecondsSinceEpoch}',
      category: _selectedCategory,
      geotag: _currentGeotag.withCaptureTimestamp(captureTime),
      isLiveCamera: !_cameraUnavailable,
      imagePath: imagePath,
      // This local check does not delay the photo screen. A real remote model
      // can replace the service later without changing this UI flow.
      aiVerification: await _aiService.verifyPhotoIntegrity(
        imagePath: imagePath,
        isLiveCamera: !_cameraUnavailable,
      ),
    );

    if (!mounted) return;
    final needsSecondPhoto =
        _selectedCategory.requiresDualPhoto && _firstPhoto == null;
    setState(() {
      _isCapturing = false;
      if (needsSecondPhoto) {
        _firstPhoto = photo;
      } else if (_selectedCategory.requiresDualPhoto) {
        _secondPhoto = photo;
      } else {
        _firstPhoto = photo;
      }
    });

    if (needsSecondPhoto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Before photo captured. Now take the after photo.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _uploadAction() async {
    if (_firstPhoto == null || _isUploading) return;

    final photoToUpload =
        _selectedCategory.requiresDualPhoto && _secondPhoto != null
            ? AuthenticGeoPhoto(
                id: _firstPhoto!.id,
                category: _firstPhoto!.category,
                geotag: _firstPhoto!.geotag,
                isLiveCamera: _firstPhoto!.isLiveCamera,
                aiVerification: _firstPhoto!.aiVerification,
                imagePath: _firstPhoto!.imagePath,
                secondaryImagePath: _secondPhoto!.imagePath,
                secondaryTimestamp: _secondPhoto!.timestamp,
              )
            : _firstPhoto!;

    setState(() => _isUploading = true);
    try {
      await _backend.saveAction(photoToUpload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uploaded to your activity record. Proof #${photoToUpload.cryptoHash}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController = null;
      controller.dispose();
      if (mounted) setState(() => _isCameraInitializing = true);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = _selectedCategory.requiresDualPhoto
        ? _firstPhoto != null && _secondPhoto != null
        : _firstPhoto != null;

    return Scaffold(
      backgroundColor: const Color(0xFF050606),
      appBar: AppBar(
        backgroundColor: const Color(0xE6050606),
        surfaceTintColor: Colors.transparent,
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
              'GPS Map Camera - Real time proof',
              style: AppTheme.body(11, c: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: complete ? _buildResultPreview() : _buildLiveCamera(),
    );
  }

  Widget _buildLiveCamera() {
    final stepLabel = _selectedCategory.requiresDualPhoto
        ? (_firstPhoto == null
            ? '1 of 2  -  Capture before recycling'
            : '2 of 2  -  Capture after recycling')
        : 'Live GPS camera ready';
    final canCapture = !_isCapturing && !_isLoadingLocation;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraBackground(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x4D000000), Color(0x00000000), Color(0xCC000000)],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _buildCategoryStrip(),
                const SizedBox(height: 10),
                _buildStepPill(stepLabel),
                if (_selectedCategory.requiresProximityCheck &&
                    _proximityResult.hasNearbyAction) ...[
                  const SizedBox(height: 10),
                  _buildProximityWarning(),
                ],
                const Spacer(),
                _buildLocationCard(),
                const SizedBox(height: 18),
                _buildCameraControls(canCapture),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraBackground() {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF101212),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCameraInitializing)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2,
              ),
            )
          else
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white54,
              size: 42,
            ),
          const SizedBox(height: 12),
          Text(
            _isCameraInitializing
                ? 'Opening secure camera...'
                : 'Camera preview unavailable',
            style: AppTheme.body(13, c: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ActionCategory.allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ActionCategory.allCategories[index];
          final selected = category.id == _selectedCategory.id;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              category.icon,
              size: 15,
              color: selected ? Colors.white : category.color,
            ),
            label: Text(
              category.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            selectedColor: category.color.withValues(alpha: 0.90),
            backgroundColor: Colors.black.withValues(alpha: 0.55),
            side: BorderSide(color: selected ? Colors.white70 : Colors.white24),
            onSelected: (_) => _onCategoryChanged(category),
          );
        },
      ),
    );
  }

  Widget _buildStepPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        label,
        style: AppTheme.body(11.5, c: Colors.white, w: FontWeight.w700),
      ),
    );
  }

  Widget _buildProximityWarning() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _proximityResult.warningMessage,
              style: AppTheme.body(10.5, c: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final title = [
      _currentGeotag.city,
      _currentGeotag.state,
      _currentGeotag.country,
    ].where((part) => part.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeotagMapThumbnail(
            geotag: _currentGeotag,
            width: 76,
            height: 88,
            borderRadius: 10,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Finding current location...'
                            : (title.isEmpty ? 'Location unavailable' : title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          12.5,
                          c: Colors.white,
                          w: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh location',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      color: Colors.white,
                      onPressed: _isLoadingLocation ? null : _fetchRealGeotag,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded),
                    ),
                  ],
                ),
                Text(
                  _isLoadingLocation
                      ? 'GPS and address are being cached once.'
                      : _currentGeotag.addressLine1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(10.5, c: Colors.white70),
                ),
                Text(
                  _isLoadingLocation
                      ? 'The shutter will unlock as soon as it is ready.'
                      : _currentGeotag.addressLine2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(10.5, c: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  _isLoadingLocation
                      ? 'Authentic GPS tag pending'
                      : '${_currentGeotag.formattedCoordinates}  |  ${_currentGeotag.formattedDateTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                  ),
                ),
                if (!_hasLocationPermission) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Enable location permission to create a verified tag.',
                    style: TextStyle(color: Color(0xFFFFCC80), fontSize: 9.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls(bool canCapture) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 58,
          child: IconButton(
            tooltip: 'Refresh camera',
            onPressed: _isCameraInitializing ? null : _initializeCamera,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
        ),
        GestureDetector(
          onTap: canCapture ? _takePhoto : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: canCapture ? Colors.white : Colors.white38,
                width: 4,
              ),
              color: Colors.black.withValues(alpha: 0.28),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canCapture ? Colors.white : Colors.white38,
              ),
              child: Center(
                child: _isCapturing
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.black87,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        color: canCapture ? Colors.black : Colors.black45,
                        size: 31,
                      ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 58,
          child: IconButton(
            tooltip: 'Switch camera',
            onPressed: _cameras.length > 1 && !_isCameraInitializing
                ? _switchCamera
                : null,
            icon: Icon(
              Icons.cameraswitch_rounded,
              color: _cameras.length > 1 ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPreview() {
    final dualPhoto = _selectedCategory.requiresDualPhoto;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: dualPhoto
                  ? Column(
                      children: [
                        Expanded(
                          child: _watermarkedPhoto(
                            _firstPhoto!,
                            label: '1. Before recycle',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _watermarkedPhoto(
                            _secondPhoto!,
                            label: '2. After recycle',
                          ),
                        ),
                      ],
                    )
                  : _watermarkedPhoto(_firstPhoto!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake'),
                    onPressed: _isUploading
                        ? null
                        : () => setState(() {
                              _firstPhoto = null;
                              _secondPhoto = null;
                            }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                    onPressed: _isUploading ? null : _uploadAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _watermarkedPhoto(AuthenticGeoPhoto photo, {String? label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GeotagWatermarkOverlay(
        photo: photo,
        customLabel: label,
        child: _displayCapturedImage(photo),
      ),
    );
  }

  Widget _displayCapturedImage(AuthenticGeoPhoto photo) {
    final imagePath = photo.imagePath;
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: const Color(0xFF202020),
      child: Center(
        child: Icon(photo.category.icon, size: 70, color: Colors.white54),
      ),
    );
  }
}

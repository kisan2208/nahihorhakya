import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import '../glass.dart';

/// Recycle E-Waste screen with two modes:
///   1. Photo Upload  — Before & After camera capture
///   2. Barcode Scan  — Scan product barcode for device info
class EWasteRecycleScreen extends StatefulWidget {
  const EWasteRecycleScreen({super.key});

  @override
  State<EWasteRecycleScreen> createState() => _EWasteRecycleScreenState();
}

class _EWasteRecycleScreenState extends State<EWasteRecycleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Recycle E-Waste', style: AppTheme.display(18, c: AppColors.primaryDark)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                padding: const EdgeInsets.all(4),
                radius: 16,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.charcoal,
                  labelStyle: AppTheme.body(13, w: FontWeight.w700),
                  unselectedLabelStyle: AppTheme.body(13, w: FontWeight.w500),
                  tabs: const [
                    Tab(icon: Icon(Icons.photo_camera_rounded, size: 18), text: 'Photo Upload'),
                    Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Barcode Scan'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PhotoUploadTab(),
            _BarcodeScanTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — PHOTO UPLOAD
// ─────────────────────────────────────────────────────────────
class _PhotoUploadTab extends StatefulWidget {
  const _PhotoUploadTab();

  @override
  State<_PhotoUploadTab> createState() => _PhotoUploadTabState();
}

class _PhotoUploadTabState extends State<_PhotoUploadTab> {
  final ImagePicker _picker = ImagePicker();
  File? _beforePhoto;
  File? _afterPhoto;
  bool _isSubmitting = false;

  Future<void> _pickPhoto(bool isBefore) async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file == null) return;
    setState(() {
      if (isBefore) {
        _beforePhoto = File(file.path);
      } else {
        _afterPhoto = File(file.path);
      }
    });
  }

  Future<void> _submit() async {
    if (_beforePhoto == null || _afterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture both BEFORE and AFTER photos.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('E-Waste photos submitted! 150 credits pending verification.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.all(14),
            tint: AppColors.accent,
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Capture 2 photos: your device BEFORE dropping it at the recycling centre, and AFTER.',
                  style: AppTheme.body(12.5, c: AppColors.charcoal),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('Earn 150 Credits', style: AppTheme.body(13.5, w: FontWeight.w700, c: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Step 1 — Before Recycling', style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primaryDark)),
          const SizedBox(height: 8),
          _PhotoSlot(
            photo: _beforePhoto,
            label: 'Take BEFORE Photo',
            icon: Icons.camera_alt_rounded,
            accentColor: AppColors.primary,
            onTap: () => _pickPhoto(true),
          ),
          const SizedBox(height: 20),

          Text('Step 2 — After Recycling', style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primaryDark)),
          const SizedBox(height: 8),
          _PhotoSlot(
            photo: _afterPhoto,
            label: 'Take AFTER Photo',
            icon: Icons.camera_alt_rounded,
            accentColor: AppColors.primaryDark,
            onTap: () => _pickPhoto(false),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(filled: _beforePhoto != null, label: 'Before'),
              const SizedBox(width: 8),
              Container(width: 32, height: 2, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              _Dot(filled: _afterPhoto != null, label: 'After'),
            ],
          ),
          const SizedBox(height: 24),

          if (_isSubmitting)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            PrimaryButton(
              label: 'Submit for Verification',
              icon: Icons.verified_rounded,
              onTap: _submit,
            ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final File? photo;
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.photo,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        radius: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: photo != null
              ? Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.file(photo!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text('Retake', style: AppTheme.body(11, c: Colors.white70)),
                        ]),
                      ),
                    ),
                  ],
                )
              : Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(label, style: AppTheme.body(13.5, w: FontWeight.w600, c: accentColor)),
                      const SizedBox(height: 4),
                      Text('Tap to open camera', style: AppTheme.body(11.5, c: AppColors.muted)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool filled;
  final String label;
  const _Dot({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
            border: Border.all(
              color: filled ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.body(10, c: AppColors.muted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — BARCODE SCANNER
// ─────────────────────────────────────────────────────────────

class _DeviceInfo {
  final String brand;
  final String model;
  final String category;
  final String material;
  final int credits;
  final bool eligible;

  const _DeviceInfo({
    required this.brand,
    required this.model,
    required this.category,
    required this.material,
    required this.credits,
    required this.eligible,
  });
}

const _kDeviceDb = <String, _DeviceInfo>{
  '5901234123457': _DeviceInfo(
    brand: 'Samsung',
    model: 'Galaxy S10',
    category: 'Smartphone',
    material: 'Lithium-ion battery · Aluminium · Glass',
    credits: 150,
    eligible: true,
  ),
  '012345678901': _DeviceInfo(
    brand: 'Apple',
    model: 'iPhone 11',
    category: 'Smartphone',
    material: 'Lithium-ion battery · Steel · Glass',
    credits: 150,
    eligible: true,
  ),
  '012345678905': _DeviceInfo(
    brand: 'Dell',
    model: 'Inspiron Laptop',
    category: 'Laptop',
    material: 'Lithium battery · Aluminium · Plastic',
    credits: 150,
    eligible: true,
  ),
  '012345678906': _DeviceInfo(
    brand: 'HP',
    model: 'DeskJet Printer',
    category: 'Printer',
    material: 'Plastic · Ink cartridges',
    credits: 120,
    eligible: true,
  ),
};

class _BarcodeScanTab extends StatefulWidget {
  const _BarcodeScanTab();

  @override
  State<_BarcodeScanTab> createState() => _BarcodeScanTabState();
}

class _BarcodeScanTabState extends State<_BarcodeScanTab> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _scannedValue;
  BarcodeFormat? _scannedFormat;
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    setState(() {
      _scannedValue = barcode.rawValue!;
      _scannedFormat = barcode.format;
      _isScanning = false;
    });
    _scannerController.stop();
  }

  void _resetScan() {
    setState(() {
      _scannedValue = null;
      _scannedFormat = null;
      _isScanning = true;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return _isScanning ? _buildScanner(context) : _buildResult(context);
  }

  Widget _buildScanner(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetected,
        ),

        // Overlay
        Positioned.fill(
          child: Column(
            children: [
              Expanded(flex: 2, child: Container(color: Colors.black54)),
              Row(
                children: [
                  Expanded(child: Container(color: Colors.black54)),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Expanded(child: Container(color: Colors.black54)),
                ],
              ),
              Expanded(flex: 3, child: Container(color: Colors.black54)),
            ],
          ),
        ),

        // Top info bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Scan E-Waste Barcode',
                          style: AppTheme.display(17, c: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Point camera at product barcode or QR code',
                          style: AppTheme.body(12, c: Colors.white70),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _scannerController.toggleTorch(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom hint
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 60),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.recycling_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text('Scanning for e-waste barcode…',
                        style: AppTheme.body(12.5, c: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Supports QR Code · EAN-13 · CODE-128 · UPC-A',
                  style: AppTheme.body(11, c: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final info = _kDeviceDb[_scannedValue];
    final formatName = _scannedFormat?.name.toUpperCase() ?? 'UNKNOWN';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success/Unknown banner
          GlassCard(
            radius: 20,
            tint: info != null ? AppColors.accent : Colors.orange,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (info != null ? AppColors.primary : Colors.orange)
                        .withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info != null ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                    color: info != null ? AppColors.primary : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info != null ? 'Device Identified!' : 'Unknown Barcode',
                        style: AppTheme.body(15, w: FontWeight.w700, c: AppColors.charcoal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info != null
                            ? 'This device is eligible for e-waste recycling credits'
                            : 'Device not found — manual review required',
                        style: AppTheme.body(12, c: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Raw scan data
          GlassCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Data', style: AppTheme.body(13, w: FontWeight.w700, c: AppColors.primaryDark)),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.qr_code_rounded, label: 'Barcode Value', value: _scannedValue ?? '—'),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.format_list_bulleted_rounded, label: 'Format', value: formatName),
              ],
            ),
          ),

          if (info != null) ...[
            const SizedBox(height: 16),

            // Device details
            GlassCard(
              radius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device Information', style: AppTheme.body(13, w: FontWeight.w700, c: AppColors.primaryDark)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.business_rounded, label: 'Brand', value: info.brand),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.devices_rounded, label: 'Model', value: info.model),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.category_rounded, label: 'Category', value: info.category),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.science_rounded, label: 'Materials', value: info.material),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Credits card
            GlassCard(
              radius: 16,
              tint: AppColors.accent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recycling Credits', style: AppTheme.body(12.5, c: AppColors.muted)),
                        Text(
                          '${info.credits} Credits',
                          style: AppTheme.display(22, c: AppColors.primaryDark),
                        ),
                        Text(
                          info.eligible
                              ? 'Eligible for recycling programme'
                              : 'Not eligible',
                          style: AppTheme.body(12, c: info.eligible ? AppColors.primary : AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Scan again
          Pressable(
            onTap: _resetScan,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 8),
                  Text('Scan Again', style: AppTheme.body(14, w: FontWeight.w700, c: AppColors.primaryDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTheme.body(12.5, w: FontWeight.w600, c: AppColors.muted)),
        Expanded(
          child: Text(value, style: AppTheme.body(12.5, c: AppColors.charcoal)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../core/story_logger.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/validators.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isProcessing = false;

  void _onQRViewCreated(QRViewController controller) {
    StoryLogger.d('QR camera ready', tag: 'QrScan');
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;
      final code = scanData.code?.trim();
      if (code == null || code.isEmpty) {
        StoryLogger.d('Empty scan payload ignored', tag: 'QrScan');
        return;
      }

      _isProcessing = true;
      if (mounted) setState(() {});
      StoryLogger.i(
        'Scan captured len=${code.length} snippet=${truncateAddress(code)}',
        tag: 'QrScan',
      );
      try {
        await HapticFeedback.mediumImpact();
        await controller.pauseCamera();
      } catch (e, st) {
        // Camera pause is best-effort; still return the code.
        StoryLogger.w(
          'pauseCamera failed; returning scan anyway',
          tag: 'QrScan',
          error: e,
          stackTrace: st,
        );
      }
      if (!mounted) {
        StoryLogger.w('Scan discarded: page unmounted', tag: 'QrScan');
        return;
      }
      StoryLogger.d('Pop with scan result', tag: 'QrScan');
      Navigator.of(context).pop(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            StoryLogger.d('Scan cancelled by user', tag: 'QrScan');
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          l10n.qrScannerTitle,
          style: StoryTextStyles.titleMedium(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          QRView(
            key: _qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: StoryColors.brandTeal,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 4,
              cutOutSize: 250,
            ),
          ),
          _buildInstructions(l10n, isDark),
        ],
      ),
    );
  }

  Widget _buildInstructions(AppLocalizations l10n, bool isDark) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: StorySpacing.xl,
              vertical: StorySpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: StorySpacing.xl),
            child: Text(
              l10n.qrScannerHint,
              textAlign: TextAlign.center,
              style: StoryTextStyles.bodyMedium(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

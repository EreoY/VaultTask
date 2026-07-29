import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';

class FloatingRecordingBar extends StatefulWidget {
  final String recordingTimeStr;
  final VoidCallback onLap;
  final VoidCallback onStop;

  const FloatingRecordingBar({
    super.key,
    required this.recordingTimeStr,
    required this.onLap,
    required this.onStop,
  });

  @override
  State<FloatingRecordingBar> createState() => _FloatingRecordingBarState();
}

class _FloatingRecordingBarState extends State<FloatingRecordingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.recordingTimeStr,
              style: GlassText.bodyMD().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                foregroundColor: Colors.blueAccent,
                shape: const StadiumBorder(),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Text('⏱️', style: TextStyle(fontSize: 16)),
              label: Text(
                'คั่นเวลา',
                style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                widget.onLap();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'สร้างการ์ดสรุปช่วงเวลาเรียบร้อย!',
                      style: GlassText.bodyMD().copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                shape: const StadiumBorder(),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Text('⏹️', style: TextStyle(fontSize: 16)),
              label: Text(
                'หยุด',
                style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: widget.onStop,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/status_bar/widgets/battery_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class StatusBar extends StatelessWidget {
  final String title;

  const StatusBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final gradientColors = isDarkTheme
        ? const [
            AppPalette.darkStatusBarGradientColor1,
            AppPalette.darkStatusBarGradientColor2,
          ]
        : const [
            AppPalette.statusBarGradientColor1,
            AppPalette.statusBarGradientColor2,
          ];
    final borderColor = isDarkTheme
        ? AppPalette.darkStatusBarBorderColor
        : AppPalette.statusBarBorderColor;

    return SizedBox(
      height: 30,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Expanded(
                child: _MaintenanceTapTarget(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isPlaying = ref.watch(
                    nowPlayingDetailsProvider.select((e) => e.isPlaying),
                  );
                  return Icon(
                    isPlaying
                        ? CupertinoIcons.play_fill
                        : CupertinoIcons.pause_fill,
                    color: AppPalette.selectedTileGradientColor1,
                  );
                },
              ),
              const SizedBox(width: 2),
              const RepaintBoundary(child: BatteryIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceTapTarget extends StatefulWidget {
  final Widget child;

  const _MaintenanceTapTarget({required this.child});

  @override
  State<_MaintenanceTapTarget> createState() => _MaintenanceTapTargetState();
}

class _MaintenanceTapTargetState extends State<_MaintenanceTapTarget> {
  static const _requiredTaps = 7;
  static const _channel = MethodChannel('classipod/maintenance');

  Timer? _resetTimer;
  int _tapCount = 0;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () => _tapCount = 0);
    _tapCount++;

    if (_tapCount >= _requiredTaps) {
      _tapCount = 0;
      _channel.invokeMethod<void>('openBridge');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}

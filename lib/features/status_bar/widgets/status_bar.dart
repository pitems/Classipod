import 'dart:async';

import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/status_bar/widgets/battery_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatusBar extends StatelessWidget {
  final String title;
  final bool showSepiaLayout;

  const StatusBar({
    super.key,
    required this.title,
    this.showSepiaLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    if (StatusBarScope.of(context)) {
      return const SizedBox.shrink();
    }

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
        child: showSepiaLayout
            ? _SepiaStatusBarContent(title: title)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _StatusBarContent(title: title),
              ),
      ),
    );
  }
}

class _StatusBarContent extends StatelessWidget {
  final String title;

  const _StatusBarContent({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const _PlaybackIndicator(),
        const SizedBox(width: 2),
        const RepaintBoundary(child: BatteryIndicator()),
      ],
    );
  }
}

class _SepiaStatusBarContent extends StatelessWidget {
  final String title;

  const _SepiaStatusBarContent({required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 5),
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
        ),
        const _CurrentTime(),
        const Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.volume_up,
                size: 14,
                color: CupertinoColors.black,
              ),
              SizedBox(width: 6),
              _PlaybackIndicator(),
              SizedBox(width: 4),
              RepaintBoundary(child: BatteryIndicator()),
              SizedBox(width: 5),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackIndicator extends ConsumerWidget {
  const _PlaybackIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(
      nowPlayingDetailsProvider.select((e) => e.isPlaying),
    );
    return Icon(
      isPlaying ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
      size: 14,
      color: AppPalette.selectedTileGradientColor1,
    );
  }
}

class _CurrentTime extends StatefulWidget {
  const _CurrentTime();

  @override
  State<_CurrentTime> createState() => _CurrentTimeState();
}

class _CurrentTimeState extends State<_CurrentTime> {
  late String _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() => _time = DateFormat('h:mm a').format(DateTime.now()));
    } else {
      _time = DateFormat('h:mm a').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: const TextStyle(
        color: CupertinoColors.black,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class StatusBarScope extends InheritedWidget {
  const StatusBarScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StatusBarScope>() != null;

  @override
  bool updateShouldNotify(StatusBarScope oldWidget) => false;
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
      unawaited(_channel.invokeMethod<void>('openBridge'));
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

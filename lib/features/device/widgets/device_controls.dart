import 'dart:async';
import 'dart:math' as math;

import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/constants/keys.dart';
import 'package:classipod/core/custom_painter/next_button_custom_painter.dart';
import 'package:classipod/core/custom_painter/play_pause_button_custom_painter.dart';
import 'package:classipod/core/custom_painter/previous_button_custom_painter.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/device/models/device_action.dart';
import 'package:classipod/features/device/services/device_buttons_service_provider.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:classipod/features/settings/models/click_wheel_size.dart';
import 'package:classipod/features/settings/models/device_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceControls extends ConsumerStatefulWidget {
  const DeviceControls({super.key});

  @override
  ConsumerState createState() => _DeviceControlsState();
}

class _DeviceControlsState extends ConsumerState<DeviceControls> {
  double? _lastWheelAngle;
  double _accumulatedWheelAngle = 0;
  Future<void> _wheelActionQueue = Future<void>.value();

  double _wheelAngle(Offset position, double radius) {
    return math.atan2(position.dy - radius, position.dx - radius);
  }

  double _shortestAngleDelta(double current, double previous) {
    double delta = current - previous;
    if (delta > math.pi) {
      delta -= math.pi * 2;
    } else if (delta < -math.pi) {
      delta += math.pi * 2;
    }
    return delta;
  }

  void onClickWheelPanStart({
    required DragStartDetails details,
    required double radius,
  }) {
    _lastWheelAngle = _wheelAngle(details.localPosition, radius);
    _accumulatedWheelAngle = 0;
  }

  void onClickWheelPanEnd() {
    _lastWheelAngle = null;
    _accumulatedWheelAngle = 0;
  }

  void _queueWheelAction(DeviceAction action) {
    _wheelActionQueue = _wheelActionQueue.then((_) {
      return ref
          .read(deviceButtonsServiceProvider.notifier)
          .setDeviceAction(action);
    });
  }

  void onClickWheelScroll({
    required DragUpdateDetails dragUpdateDetails,
    required double radius,
    required double stepAngle,
  }) {
    final double currentAngle = _wheelAngle(
      dragUpdateDetails.localPosition,
      radius,
    );
    final double? previousAngle = _lastWheelAngle;
    _lastWheelAngle = currentAngle;
    if (previousAngle == null) {
      return;
    }

    _accumulatedWheelAngle += _shortestAngleDelta(currentAngle, previousAngle);

    while (_accumulatedWheelAngle.abs() >= stepAngle) {
      final bool isForwardDirection = _accumulatedWheelAngle > 0;
      _accumulatedWheelAngle -= isForwardDirection ? stepAngle : -stepAngle;
      _queueWheelAction(
        isForwardDirection
            ? DeviceAction.rotateForward
            : DeviceAction.rotateBackward,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceColor deviceColor = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.deviceColor,
      ),
    );
    final deviceColorStyle = deviceColor.style;
    final clickWheelSize = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clickWheelSize,
      ),
    );
    final clickWheelSensitivity = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clickWheelSensitivity,
      ),
    );
    late final double clickWheelRadiusRatio;
    late final double selectButtonRadiusRatio;
    switch (clickWheelSize) {
      case ClickWheelSize.small:
        clickWheelRadiusRatio = Constants.deviceClickWheelSmallRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonSmallRadiusRatio;
        break;
      case ClickWheelSize.medium:
        clickWheelRadiusRatio = Constants.deviceClickWheelMediumRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonMediumRadiusRatio;
        break;
      case ClickWheelSize.large:
        clickWheelRadiusRatio = Constants.deviceClickWheelLargeRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonLargeRadiusRatio;
        break;
    }

    late final double stepAngle;
    switch (clickWheelSensitivity) {
      case ClickWheelSensitivity.veryLow:
        stepAngle = 0.70;
        break;
      case ClickWheelSensitivity.low:
        stepAngle = 0.35;
        break;
      case ClickWheelSensitivity.medium:
        stepAngle = 0.18;
        break;
      case ClickWheelSensitivity.high:
        stepAngle = 0.09;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth + 40;

        return GestureDetector(
          onPanStart: (details) => onClickWheelPanStart(
            details: details,
            radius: (screenWidth * clickWheelRadiusRatio) / 2,
          ),
          onPanUpdate: (dragUpdateDetails) => onClickWheelScroll(
            dragUpdateDetails: dragUpdateDetails,
            radius: (screenWidth * clickWheelRadiusRatio) / 2,
            stepAngle: stepAngle,
          ),
          onPanEnd: (_) => onClickWheelPanEnd(),
          onPanCancel: onClickWheelPanEnd,
          child: Container(
            height: screenWidth * clickWheelRadiusRatio,
            width: screenWidth * clickWheelRadiusRatio,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: deviceColorStyle.controlBackgroundColor,
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async => ref
                        .read(deviceButtonsServiceProvider.notifier)
                        .setDeviceAction(DeviceAction.menu),
                    onLongPress: () async {
                      await Future.wait([
                        ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .buttonPressVibrate(),
                        ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .clickWheelSound(),
                      ]);
                      if (context.mounted) {
                        context.goNamed(Routes.menu.name);
                        if (!ref
                            .read(splitScreenViewControllerProvider)
                            .isScreenVisible) {
                          unawaited(
                            ref
                                .read(splitScreenViewControllerProvider)
                                .openSplitView(),
                          );
                        }
                      }
                    },
                    child: ColoredBox(
                      color: deviceColorStyle.controlBackgroundColor,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          context.localization.menuButtonText,
                          key: menuButtonGlobalKey,
                          style: TextStyle(
                            color: deviceColorStyle.buttonAccentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      key: previousButtonGlobalKey,
                      child: GestureDetector(
                        onTap: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.seekBackward),
                        onLongPress: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(
                              DeviceAction.seekBackwardLongPress,
                            ),
                        onLongPressEnd: (_) async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.longPressEnd),
                        child: SizedBox(
                          height: screenWidth * 0.2175,
                          child: ColoredBox(
                            color: deviceColorStyle.controlBackgroundColor,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomPaint(
                                size: const Size(20, 10),
                                painter: PreviousButtonCustomPainter(
                                  color: deviceColorStyle.buttonIconColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: centerButtonGlobalKey,
                      onTap: () async => ref
                          .read(deviceButtonsServiceProvider.notifier)
                          .setDeviceAction(DeviceAction.select),
                      onLongPress: () async => ref
                          .read(deviceButtonsServiceProvider.notifier)
                          .setDeviceAction(DeviceAction.selectLongPress),
                      onLongPressEnd: (_) async => ref
                          .read(deviceButtonsServiceProvider.notifier)
                          .setDeviceAction(DeviceAction.longPressEnd),
                      child: SizedBox(
                        height: screenWidth * selectButtonRadiusRatio,
                        width: screenWidth * selectButtonRadiusRatio,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: deviceColorStyle.controlBorderColor,
                            ),
                            image: const DecorationImage(
                              image: AssetImage(Assets.noiseImage),
                              fit: BoxFit.cover,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors:
                                  deviceColorStyle.innerButtonGradientColors,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      key: nextButtonGlobalKey,
                      child: GestureDetector(
                        onTap: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.seekForward),
                        onLongPress: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.seekForwardLongPress),
                        onLongPressEnd: (_) async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.longPressEnd),
                        child: SizedBox(
                          height: screenWidth * selectButtonRadiusRatio,
                          child: ColoredBox(
                            color: deviceColorStyle.controlBackgroundColor,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomPaint(
                                size: const Size(20, 10),
                                painter: NextButtonCustomPainter(
                                  color: deviceColorStyle.buttonIconColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async => ref
                        .read(deviceButtonsServiceProvider.notifier)
                        .playPauseButtonClick(),
                    child: ColoredBox(
                      color: deviceColorStyle.controlBackgroundColor,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: CustomPaint(
                          key: playPauseButtonGlobalKey,
                          size: const Size(26, 12),
                          painter: PlayPauseButtonCustomPainter(
                            color: deviceColorStyle.buttonIconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

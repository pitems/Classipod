import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/go_router_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/providers/filtered_audio_files_provider.dart';
import 'package:classipod/features/device/models/device_action.dart';
import 'package:classipod/features/device/services/device_buttons_service_provider.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:classipod/features/music/artists/providers/artist_names_provider.dart';
import 'package:classipod/features/settings/widgets/about_list_tile.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  static const _requiredCenterPresses = 3;
  static const _maintenanceChannel = MethodChannel('classipod/maintenance');

  Timer? _centerPressResetTimer;
  int _centerPressCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _centerPressResetTimer?.cancel();
    super.dispose();
  }

  void _handleCenterPress() {
    _centerPressResetTimer?.cancel();
    _centerPressResetTimer = Timer(
      const Duration(seconds: 2),
      () => _centerPressCount = 0,
    );
    _centerPressCount++;

    if (_centerPressCount >= _requiredCenterPresses) {
      _centerPressCount = 0;
      unawaited(_maintenanceChannel.invokeMethod<void>('openBridge'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    ref.listen(deviceButtonsServiceProvider, (prevState, newState) {
      if (newState == null ||
          context.router.locationNamed != Routes.about.name) {
        return;
      } else if (newState == DeviceAction.menu) {
        context.pop();
      } else if (newState == DeviceAction.select) {
        _handleCenterPress();
      }
    });

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.about.title(context)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  context.localization.appTitle,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.appPrimaryTextColor,
                      ),
                ),
                const SizedBox(height: 10),
                AboutListTile(
                  titleText: context.localization.songsScreenTitle,
                  valueText:
                      "${ref.read(filteredAudioFilesProvider).requireValue.length}",
                ),
                AboutListTile(
                  titleText: context.localization.artistsScreenTitle,
                  valueText: "${ref.read(artistNamesProvider).length}",
                ),
                AboutListTile(
                  titleText: context.localization.albumsScreenTitle,
                  valueText: "${ref.read(albumDetailsProvider).length}",
                ),
                AboutListTile(
                  titleText: context.localization.versionAboutScreenTitle,
                  valueText: "1.13.0",
                ),
                AboutListTile(
                  titleText: context.localization.madeWithLoveTitle,
                  valueText: "Aditya",
                ),
                const AboutListTile(
                  titleText: "Improved by",
                  valueText: "Pitems",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

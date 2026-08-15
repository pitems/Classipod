import 'dart:io';

import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/providers/filtered_audio_files_provider.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:classipod/features/music/artists/providers/artist_names_provider.dart';
import 'package:classipod/features/music/genres/providers/genres_provider.dart';
import 'package:classipod/features/music/playlist/providers/playlists_provider.dart';
import 'package:classipod/features/music/songs/provider/songs_provider.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/tutorial/controller/tutorial_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final splashControllerProvider =
    AsyncNotifierProvider<SplashControllerNotifier, void>(
      SplashControllerNotifier.new,
    );

class SplashControllerNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    await requestStoragePermissions();
  }

  Future<void> requestStoragePermissions() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final PermissionStatus audioPermission = await Permission.audio
            .request();
        final PermissionStatus genericStoragePermission = await Permission
            .storage
            .request();
        if (audioPermission.isDenied && genericStoragePermission.isDenied) {
          throw const AudioPermissionDeniedException();
        }
        if (audioPermission.isPermanentlyDenied &&
            genericStoragePermission.isPermanentlyDenied) {
          throw const AudioPermissionPermanentlyDeniedException();
        }
      }

      await initializeApp();
    });
  }

  Future<void> initializeApp() async {
    // Load the filtered audio files metadata
    final filteredAudioFilesMetadata = await ref
        .read(filteredAudioFilesProvider.future)
        .then((value) => value.toList());

    // Set the audio source
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .setAudioSource(musicMetadataList: filteredAudioFilesMetadata);

    // Set the initial loop mode
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setInitialRepeatMode();

    // Invalidate the providers that depend on the audio files metadata
    ref.invalidate(albumDetailsProvider);
    ref.invalidate(artistNamesProvider);
    ref.invalidate(songsProvider);
    ref.invalidate(playlistsProvider);
    ref.invalidate(genresProvider);
    ref.invalidate(tutorialControllerProvider);

    // Load the playlists
    ref.read(playlistsProvider.notifier).refreshProvider();
  }

  Future<void> preloadForFirstFrame(BuildContext context) async {
    // Force the providers used by the primary library screens to build while
    // the splash screen is still visible.
    final albums = ref.read(albumDetailsProvider);
    ref.read(artistNamesProvider);
    ref.read(songsProvider);
    ref.read(genresProvider);
    ref.read(playlistsProvider);

    final imageProviders = <ImageProvider<Object>>[
      const AssetImage(Assets.appIcon),
      const AssetImage(Assets.defaultAlbumCoverImage),
    ];

    // Warm the first visible batch rather than retaining every original-size
    // cover in memory. Cover Flow continues warming nearby covers as needed.
    for (final album in albums.take(12)) {
      final path = album.albumArtPath;
      if (path == null || path.isEmpty || !album.isOnDevice()) {
        continue;
      }
      final file = File(path);
      if (file.existsSync()) {
        imageProviders.add(FileImage(file));
      }
    }

    await Future.wait(
      imageProviders.map((image) async {
        try {
          await precacheImage(image, context);
        } catch (_) {
          // Individual artwork failures should never block startup.
        }
      }),
    );
  }
}

class AudioPermissionDeniedException implements Exception {
  const AudioPermissionDeniedException();
}

class AudioPermissionPermanentlyDeniedException implements Exception {
  const AudioPermissionPermanentlyDeniedException();
}

import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _MusicListDisplayItems {
  coverFlow,
  playlists,
  artists,
  albums,
  songs,
  genres,
  search;

  String title(BuildContext context) {
    switch (this) {
      case coverFlow:
        return context.localization.coverFlowScreenTitle;
      case playlists:
        return context.localization.playlistsScreenTitle;
      case artists:
        return context.localization.artistsScreenTitle;
      case albums:
        return context.localization.albumsScreenTitle;
      case songs:
        return context.localization.songsScreenTitle;
      case genres:
        return context.localization.genresScreenTitle;
      case search:
        return context.localization.searchScreenTitle;
    }
  }
}

class MusicMenuScreen extends ConsumerStatefulWidget {
  const MusicMenuScreen({super.key});

  @override
  ConsumerState createState() => _MusicMenuScreenState();
}

class _MusicMenuScreenState extends ConsumerState<MusicMenuScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.musicMenu.name;

  @override
  List<_MusicListDisplayItems> get displayItems =>
      _MusicListDisplayItems.values;

  @override
  Future<void> onSelectPressed() =>
      _navigateToScreen(_MusicListDisplayItems.values[selectedDisplayItem]);

  Future<void> _navigateToScreen(
    _MusicListDisplayItems musicDisplayItem,
  ) async {
    setState(
      () => selectedDisplayItem = displayItems.indexOf(musicDisplayItem),
    );
    switch (musicDisplayItem) {
      case _MusicListDisplayItems.coverFlow:
        unawaited(ref.read(splitScreenViewControllerProvider).closeSplitView());
        await context.pushNamed(
          Routes.coverFlow.name,
          extra: Routes.musicMenu.name,
        );
        break;
      case _MusicListDisplayItems.playlists:
        await _openSection(Routes.playlists.name);
        break;
      case _MusicListDisplayItems.artists:
        await _openSection(Routes.artists.name);
        break;
      case _MusicListDisplayItems.albums:
        await _openSection(Routes.albums.name);
        break;
      case _MusicListDisplayItems.songs:
        await _openSection(Routes.songs.name);
        break;
      case _MusicListDisplayItems.genres:
        await _openSection(Routes.genres.name);
        break;
      case _MusicListDisplayItems.search:
        await _openSection(Routes.search.name);
        break;
    }
  }

  Future<void> _openSection(String routeName) async {
    final splitScreenController = ref.read(splitScreenViewControllerProvider);
    unawaited(splitScreenController.closeSplitView());
    if (!mounted) {
      return;
    }
    await context.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.musicMenu.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: const DisplayListTile(
                  text: '',
                  isSelected: false,
                ),
                itemBuilder: (context, index) => DisplayListTile(
                  text: displayItems[index].title(context),
                  isSelected: selectedDisplayItem == index,
                  isAlternate: index.isOdd,
                  onTap: () async => _navigateToScreen(displayItems[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

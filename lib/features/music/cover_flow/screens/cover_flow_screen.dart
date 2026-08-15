import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_page_screen.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:classipod/features/music/cover_flow/screens/cover_flow_album_selection_screen.dart';
import 'package:classipod/features/music/cover_flow/widgets/album_song_list_panel.dart';
import 'package:classipod/features/music/cover_flow/widgets/album_transition_card.dart';
import 'package:classipod/features/now_playing/widgets/album_reflective_art.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CoverFlowScreen extends ConsumerStatefulWidget {
  const CoverFlowScreen({super.key});

  @override
  ConsumerState createState() => _CoverFlowScreenState();
}

class _CoverFlowScreenState extends ConsumerState<CoverFlowScreen>
    with CustomPageScreen, TickerProviderStateMixin {
  static const _albumDimDuration = Duration(milliseconds: 900);
  static int _lastCoverFlowIndex = 0;

  late final AnimationController _albumDimController;
  final _selectedTransitionKey = GlobalKey<AlbumTransitionCardState>();
  bool _isLeaving = false;
  bool _transitionActive = false;

  @override
  String get routeName => Routes.coverFlow.name;

  @override
  void onMenuButtonPressed() {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;
    unawaited(_leaveCoverFlow());
  }

  @override
  void initState() {
    super.initState();
    currentPage = initialPage.toDouble();
    selectedDisplayItem = initialPage;
    pageController.addListener(_rememberCoverFlowPosition);
    _albumDimController = AnimationController(
      vsync: this,
      duration: _albumDimDuration,
      reverseDuration: _albumDimDuration,
    );
  }

  @override
  void dispose() {
    _albumDimController.dispose();
    super.dispose();
  }

  Future<void> _leaveCoverFlow() async {
    if (mounted) {
      context.pop();
    }
  }

  @override
  double get viewPortFraction => 0.54;

  @override
  int get initialPage {
    final itemCount = displayItems.length;
    if (itemCount == 0) {
      return 0;
    }
    return _lastCoverFlowIndex.clamp(0, itemCount - 1);
  }

  @override
  List<AlbumModel> get displayItems => ref.read(albumDetailsProvider);

  void _rememberCoverFlowPosition() {
    final page = pageController.page;
    if (page != null) {
      _lastCoverFlowIndex = page.round();
    }
  }

  @override
  void onSelectPressed() => _chooseAlbum(selectedDisplayItem);

  void _chooseAlbum(int index) {
    final transition = _selectedTransitionKey.currentState;
    if (transition == null) {
      unawaited(_openAlbumSelection(displayItems[index]));
      return;
    }
    transition.resetTitleAnimation();
    setState(() => _transitionActive = true);
    unawaited(_albumDimController.forward());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(transition.open());
      }
    });
  }

  Future<void> _openAlbumSelection(AlbumModel albumDetail) async {
    final transition = _selectedTransitionKey.currentState;
    await context.pushNamed(
      Routes.coverFlowSelection.name,
      extra: CoverFlowAlbumSelectionRouteArgs(
        albumDetail: albumDetail,
        onRouteReady: () {
          transition?.hideForRoute();
          transition?.startTitleAnimation();
        },
        titleAnimationEnabled: transition?.titleAnimationEnabled,
      ),
    );
    if (mounted) {
      transition?.showForClose();
      await Future.wait([
        transition?.close() ?? Future<void>.value(),
        _albumDimController.reverse(),
      ]);
      if (mounted) {
        setState(() => _transitionActive = false);
      }
    }
  }

  Widget _buildTransparentPage(BuildContext context, Widget content) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: ColoredBox(color: context.appBackgroundColor, child: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (displayItems.isEmpty) {
      return _buildTransparentPage(
        context,
        Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }

    return _buildTransparentPage(
      context,
      Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: AlbumSongListPanel.targetHeight(context),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 230,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: displayItems.length,
                        clipBehavior: Clip.none,
                        itemBuilder: (context, index) {
                          final double relativePosition = index - currentPage;
                          return GestureDetector(
                            key: ValueKey(
                              'cover-flow-item-${displayItems[index].albumName}-${displayItems[index].albumArtistName}',
                            ),
                            onTap: relativePosition == 0
                                ? () => _chooseAlbum(index)
                                : () async => pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  ),
                            child: Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.003)
                                ..scaleByDouble(
                                  (1 - relativePosition.abs()).clamp(0.2, 0.6) +
                                      0.4,
                                  (1 - relativePosition.abs()).clamp(0.2, 0.6) +
                                      0.4,
                                  (1 - relativePosition.abs()).clamp(0.2, 0.6) +
                                      0.4,
                                  1,
                                )
                                ..rotateY(relativePosition * 0.9),
                              alignment: relativePosition >= 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: relativePosition == 0
                                  ? _transitionActive
                                        ? const SizedBox(
                                            width: 230,
                                            height: 230,
                                          )
                                        : AlbumTransitionCard(
                                            key: _selectedTransitionKey,
                                            album: displayItems[index],
                                            onOpenCompleted: () => unawaited(
                                              _openAlbumSelection(
                                                displayItems[index],
                                              ),
                                            ),
                                          )
                                  : RepaintBoundary(
                                      child: AlbumReflectiveArt(
                                        imageWidth: 230,
                                        thumbnailPath:
                                            displayItems[index].albumArtPath,
                                        isOnDevice: displayItems[index]
                                            .isOnDevice(),
                                        animateReflection: false,
                                        heroTag:
                                            "${displayItems[index].albumName}-${displayItems[index].albumArtistName}",
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          displayItems[selectedDisplayItem].albumName,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          displayItems[selectedDisplayItem].albumArtistName,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_transitionActive)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _albumDimController,
                      builder: (context, _) => ColoredBox(
                        color: CupertinoColors.black.withValues(
                          alpha: 0.54 * _albumDimController.value,
                        ),
                      ),
                    ),
                  ),
                if (_transitionActive)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AlbumTransitionCard(
                        key: _selectedTransitionKey,
                        album: displayItems[selectedDisplayItem],
                        onOpenCompleted: () => unawaited(
                          _openAlbumSelection(
                            displayItems[selectedDisplayItem],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

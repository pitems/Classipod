import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_page_screen.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
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
    with CustomPageScreen, SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 350);

  late final AnimationController _transitionController;
  late final Animation<double> _transitionAnimation;
  bool _isLeaving = false;

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
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      reverseDuration: _transitionDuration,
    );
    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_transitionController.forward());
      }
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _leaveCoverFlow() async {
    final splitScreenAnimation = ref
        .read(splitScreenViewControllerProvider)
        .openSplitView();
    await _transitionController.reverse();
    await splitScreenAnimation;
    if (mounted) {
      context.pop();
    }
  }

  Widget _withTransition(Widget child) {
    return AnimatedBuilder(
      animation: _transitionAnimation,
      child: child,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            child: FractionallySizedBox(
              widthFactor: _transitionAnimation.value,
              heightFactor: 1,
              child: RepaintBoundary(child: child),
            ),
          ),
        );
      },
    );
  }

  @override
  double get viewPortFraction => 0.54;

  @override
  List<AlbumModel> get displayItems => ref.read(albumDetailsProvider);

  @override
  void onSelectPressed() => _chooseAlbum(selectedDisplayItem);

  void _chooseAlbum(int index) {
    final albumDetail = ref.read(albumDetailsProvider).elementAt(index);
    unawaited(
      context.pushNamed(Routes.coverFlowSelection.name, extra: albumDetail),
    );
  }

  Widget _buildTransparentPage(BuildContext context, Widget content) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Expanded(
            child: _withTransition(
              ColoredBox(color: context.appBackgroundColor, child: content),
            ),
          ),
        ],
      ),
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
                    height: 230,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final double relativePosition = index - currentPage;
                        return GestureDetector(
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
                            child: AlbumReflectiveArt(
                              imageWidth: 230,
                              thumbnailPath: displayItems[index].albumArtPath,
                              isOnDevice: displayItems[index].isOnDevice(),
                              heroTag:
                                  "${displayItems[index].albumName}-${displayItems[index].albumArtistName}",
                            ),
                          ),
                        );
                      },
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
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
  }
}

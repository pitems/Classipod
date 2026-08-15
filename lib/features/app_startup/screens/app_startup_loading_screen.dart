import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:flutter/cupertino.dart';

class AppStartupLoading extends StatelessWidget {
  const AppStartupLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        backgroundColor: AppPalette.darkScreenBackgroundGradient2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.darkScreenBackgroundGradient1,
                AppPalette.darkScreenBackgroundGradient2,
              ],
            ),
          ),
          child: Center(child: _StartupBranding()),
        ),
      ),
    );
  }
}

class _StartupBranding extends StatelessWidget {
  const _StartupBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          Assets.appIcon,
          height: 64,
          width: 64,
          color: CupertinoColors.white,
        ),
        const SizedBox(height: 24),
        const CupertinoActivityIndicator(
          radius: 12,
          color: CupertinoColors.white,
        ),
      ],
    );
  }
}

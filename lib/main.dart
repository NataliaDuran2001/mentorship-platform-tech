import 'package:flutter/material.dart';

import 'core/config/app_branding.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/state/auth_actions.dart';
import 'presentation/utils/app_colors.dart';
import 'presentation/utils/constants.dart';

Future<void> main() async {
  // Needed because we initialize plugins before runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // We boot Supabase before registering dependencies that rely on the
    // client.
    await SupabaseConfig.initialize();

    // We initialize the get_it dependency injection.
    setupDependencies();

    // Restores the persisted session and fetches the profile before mounting
    // the UI, so that the route guards never decide with a half-loaded
    // profile.
    await bootstrapAuth();
  } catch (e) {
    // Without this catch, any backend failure left an indefinite white screen
    // with no diagnosis: it was debt 2 of §3 of the handoff.
    runApp(StartupFailed(detail: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      // The full theme lives in AppTheme; no style is defined here.
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}

/// Last resort screen for when the app cannot start.
///
/// It shows a plain message and leaves the technical detail in sight: there is
/// no user to protect from the raw error here, there is someone looking at an
/// app that did not start and who needs to know why.
class StartupFailed extends StatelessWidget {
  const StartupFailed({super.key, required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: AppConstants.iconTileSize,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  'We could not start the app',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Check your connection and open it again. If the problem '
                  'persists, the service may be down.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLg),
                SelectableText(detail, style: AppTheme.code),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

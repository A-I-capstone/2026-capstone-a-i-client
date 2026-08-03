import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/village_game.dart';
import '../../services/village/firestore_village_repository.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/village_viewmodel.dart';
import 'widgets/bottom_action_buttons.dart';
import 'widgets/debug_village_toolbar.dart';
import 'widgets/edit_drawer.dart';
import 'widgets/placing_mode_overlay.dart';
import 'widgets/shop_drawer.dart';
import 'widgets/village_hud.dart';
import 'widgets/village_loading_screen.dart';

/// Screen View for Town Decorating mini-game.
class VillageView extends StatelessWidget {
  const VillageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VillageViewModel>(
      create: (ctx) {
        final profileVm = ctx.read<ProfileViewModel>();
        final userId = profileVm.userId;
        final profileId = profileVm.activeProfile?.id ?? 'default_profile';

        final viewModel = VillageViewModel(
          repository: FirestoreVillageRepository(),
        );

        // Initialise state asynchronously
        viewModel.initialize(userId, profileId);
        return viewModel;
      },
      child: const _VillageScreenBody(),
    );
  }
}

class _VillageScreenBody extends StatefulWidget {
  const _VillageScreenBody();

  @override
  State<_VillageScreenBody> createState() => _VillageScreenBodyState();
}

class _VillageScreenBodyState extends State<_VillageScreenBody> {
  VillageGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= VillageGame(viewModel: context.read<VillageViewModel>());
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<VillageViewModel, bool>((vm) => vm.isLoading);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isLoading
            ? const VillageLoadingScreen(key: ValueKey('village_loading'))
            : Stack(
                key: const ValueKey('village_game_stack'),
                children: [
                  if (_game != null) GameWidget(game: _game!),
                  const VillageHud(),
                  const DebugVillageToolbar(),
                  const PlacingModeOverlay(),
                  const BottomActionButtons(),
                  const ShopDrawer(),
                  const EditDrawer(),
                ],
              ),
      ),
    );
  }
}



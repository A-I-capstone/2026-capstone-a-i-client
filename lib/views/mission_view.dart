import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/mission_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/bouncy_button.dart';

/// Mission Screen displaying missions generated from conversation context.
class MissionView extends StatelessWidget {
  const MissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MissionViewModel>(
      create: (_) => MissionViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const _MissionAppBar(),
        body: SafeArea(
          child: Column(
            children: const [
              Expanded(child: _MissionListView()),
              _MissionBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MissionAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        '오늘의 미션',
        style: AppTypography.headlineMedium,
      ),
    );
  }
}

class _MissionListView extends StatelessWidget {
  const _MissionListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionViewModel>(
      builder: (context, viewModel, child) {
        final missions = viewModel.missions;
        if (missions.isEmpty) {
          return const Center(
            child: Text(
              '등록된 미션이 없어요!',
              style: AppTypography.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20.0),
          itemCount: missions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16.0),
          itemBuilder: (context, index) {
            return _MissionCardItem(mission: missions[index]);
          },
        );
      },
    );
  }
}

class _MissionCardItem extends StatelessWidget {
  final Mission mission;

  const _MissionCardItem({required this.mission});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 22.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  mission.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.ink,
            size: 32.0,
          ),
        ],
      ),
    );
  }
}

class _MissionBottomBar extends StatelessWidget {
  const _MissionBottomBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 56.0,
        child: BouncyButton(
          label: '돌아가기',
          backgroundColor: AppColors.marigold,
          foregroundColor: AppColors.ink,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

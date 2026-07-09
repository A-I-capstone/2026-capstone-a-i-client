import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/screen_time_settings_viewmodel.dart';

class ScreenTimeSettingsView extends StatelessWidget {
  const ScreenTimeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScreenTimeSettingsViewModel(),
      child: const _ScreenTimeSettingsViewContent(),
    );
  }
}

class _ScreenTimeSettingsViewContent extends StatelessWidget {
  const _ScreenTimeSettingsViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScreenTimeSettingsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft pastel blue background
      appBar: AppBar(
        title: const Text(
          '스크린 타임 설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A4A4A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          itemCount: viewModel.days.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final day = viewModel.days[index];
            return _DayScreenTimeCard(
              day: day,
              onToggle: (val) => viewModel.toggleDay(index, val),
              onTap: () => _showTimePicker(context, index, viewModel),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, int index, ScreenTimeSettingsViewModel viewModel) async {
    final day = viewModel.days[index];
    Duration initialTimerDuration = day.timeLimit;
    if (initialTimerDuration.inMinutes == 0) {
      initialTimerDuration = const Duration(hours: 1);
    }

    final initialTime = TimeOfDay(
      hour: initialTimerDuration.inHours.clamp(0, 23),
      minute: initialTimerDuration.inMinutes % 60,
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial, // Android/Material Clock Dial style
      builder: (BuildContext context, Widget? child) {
        // Use 24-hour format since this is for duration (hours and minutes), not AM/PM
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFB5EAD7), // Pastel mint green
              onPrimary: const Color(0xFF4A4A4A), // Text color on selected items
              primaryContainer: const Color(0xFFB5EAD7).withOpacity(0.3), // Background for selected inputs
              onPrimaryContainer: const Color(0xFF4A4A4A),
              surface: Colors.white, // Dialog background
              onSurface: const Color(0xFF4A4A4A), // Default text color
              surfaceTint: Colors.transparent, // Remove M3 purple tint overlay
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: WidgetStateColor.resolveWith((states) => 
                states.contains(WidgetState.selected) 
                  ? const Color(0xFFB5EAD7).withOpacity(0.4) 
                  : Colors.grey.shade100
              ),
              hourMinuteTextColor: const Color(0xFF4A4A4A),
              dialHandColor: const Color(0xFFB5EAD7),
              dialBackgroundColor: Colors.grey.shade100,
              dialTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                  ? const Color(0xFF4A4A4A)
                  : Colors.black87
              ),
              entryModeIconColor: const Color(0xFF64748B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A4A4A), // Button text color
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final newDuration = Duration(hours: pickedTime.hour, minutes: pickedTime.minute);
      viewModel.updateTimeLimit(index, newDuration);
    }
  }
}

class _DayScreenTimeCard extends StatefulWidget {
  final DayScreenTime day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _DayScreenTimeCard({
    required this.day,
    required this.onToggle,
    required this.onTap,
  });

  @override
  State<_DayScreenTimeCard> createState() => _DayScreenTimeCardState();
}

class _DayScreenTimeCardState extends State<_DayScreenTimeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(40), // Organic continuous curve
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.day.dayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.day.formattedTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: widget.day.isEnabled,
                onChanged: widget.onToggle,
                activeColor: const Color(0xFFB5EAD7), // Pastel mint green
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';

class DayScreenTime {
  final String dayName;
  bool isEnabled;
  Duration timeLimit;
  Duration lastTimeLimit;

  DayScreenTime({
    required this.dayName,
    this.isEnabled = true,
    required this.timeLimit,
  }) : lastTimeLimit = timeLimit;

  String get formattedTime {
    if (!isEnabled) return '제한 없음';
    final hours = timeLimit.inHours;
    final minutes = timeLimit.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }
}

class ScreenTimeSettingsViewModel extends ChangeNotifier {
  final List<DayScreenTime> days = [
    DayScreenTime(dayName: '월요일', timeLimit: const Duration(hours: 1, minutes: 30)),
    DayScreenTime(dayName: '화요일', timeLimit: const Duration(hours: 1, minutes: 30)),
    DayScreenTime(dayName: '수요일', timeLimit: const Duration(hours: 1, minutes: 30)),
    DayScreenTime(dayName: '목요일', timeLimit: const Duration(hours: 1, minutes: 30)),
    DayScreenTime(dayName: '금요일', timeLimit: const Duration(hours: 2)),
    DayScreenTime(dayName: '토요일', timeLimit: const Duration(hours: 3)),
    DayScreenTime(dayName: '일요일', timeLimit: const Duration(hours: 3)),
  ];

  void toggleDay(int index, bool value) {
    days[index].isEnabled = value;
    if (value) {
      days[index].timeLimit = days[index].lastTimeLimit;
    }
    notifyListeners();
  }

  void updateTimeLimit(int index, Duration newDuration) {
    days[index].timeLimit = newDuration;
    days[index].lastTimeLimit = newDuration;
    if (!days[index].isEnabled) {
      days[index].isEnabled = true;
    }
    notifyListeners();
  }
}

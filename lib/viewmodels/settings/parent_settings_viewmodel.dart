import 'package:flutter/foundation.dart';

class ParentSettingsViewModel extends ChangeNotifier {
  void onSourceSettingsClicked() {
    debugPrint('Navigate to Source Settings');
  }

  void onScreenTimeSettingsClicked() {
    debugPrint('Navigate to Screen Time Settings');
  }

  void onParentReportSettingsClicked() {
    debugPrint('Navigate to Parent Report Settings');
  }

  void onChatbotSafetySettingsClicked() {
    debugPrint('Navigate to Chatbot Safety Settings');
  }

  void onPasswordChangeClicked() {
    debugPrint('Navigate to Password Change');
  }
}

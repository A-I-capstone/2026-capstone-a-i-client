import 'package:flutter/foundation.dart';

enum PasswordChangeStep { enterNew, confirmNew }

class PasswordChangeViewModel extends ChangeNotifier {
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  PasswordChangeStep _step = PasswordChangeStep.enterNew;
  PasswordChangeStep get step => _step;

  String _firstPassword = '';

  void submitFirstPassword(String newPass) {
    _errorMessage = '';
    if (newPass.isEmpty) {
      _errorMessage = '새 비밀번호 4자리를 입력해주세요.';
    } else if (newPass.length != 4) {
      _errorMessage = '새 비밀번호는 4자리 숫자로 정해주세요.';
    } else {
      _firstPassword = newPass;
      _step = PasswordChangeStep.confirmNew;
    }
    notifyListeners();
  }

  bool submitConfirmPassword(String confirmPass) {
    _errorMessage = '';
    if (confirmPass.isEmpty) {
      _errorMessage = '비밀번호를 한 번 더 입력해주세요.';
      notifyListeners();
      return false;
    } else if (_firstPassword != confirmPass) {
      _errorMessage = '처음 입력한 비밀번호와 다릅니다. 다시 확인해 주세요.';
      notifyListeners();
      return false;
    }
    return true;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:parent/models/child_info.dart';
import 'package:parent/services/settings/parent_account_service.dart';
import 'package:parent/viewmodels/onboarding_viewmodel.dart';
import 'package:parent/viewmodels/parent_settings_viewmodel.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockParentAccountService extends ParentAccountService {
  bool unlinkChildResult = true;
  bool deleteAllDataResult = true;
  List<ChildInfo> mockChildren = [];

  @override
  Future<List<ChildInfo>> fetchPairedChildren(String parentUid) async {
    return List.from(mockChildren);
  }

  @override
  Future<bool> unlinkChild(String familyId) async {
    return unlinkChildResult;
  }

  @override
  Future<bool> deleteAllParentData(String parentUid) async {
    return deleteAllDataResult;
  }
}

class MockAuthProvider implements BaseAuthProvider {
  bool deleteAccountCalled = false;
  bool signOutCalled = false;

  @override
  String? get currentUid => 'mock_parent_uid';

  @override
  Future<String> signInAnonymously() async => 'mock_parent_uid';

  @override
  Future<bool> deleteAccount() async {
    deleteAccountCalled = true;
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParentSettingsViewModel Tests', () {
    late MockParentAccountService mockService;
    late MockAuthProvider mockAuth;
    late ParentOnboardingViewModel onboardingViewModel;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockService = MockParentAccountService();
      mockAuth = MockAuthProvider();
      onboardingViewModel = ParentOnboardingViewModel();
      mockService.mockChildren = [
        ChildInfo(
          childUid: 'child_1',
          familyId: 'family_1',
          name: '민수',
          pairedAt: DateTime.now(),
        ),
        ChildInfo(
          childUid: 'child_2',
          familyId: 'family_2',
          name: '영희',
          pairedAt: DateTime.now(),
        ),
      ];
    });

    test('loadChildren updates children list in ViewModel', () async {
      final viewModel = ParentSettingsViewModel(
        parentUid: 'parent_123',
        accountService: mockService,
      );

      await viewModel.loadChildren();

      expect(viewModel.children.length, 2);
      expect(viewModel.children[0].name, '민수');
      expect(viewModel.children[1].name, '영희');
      expect(viewModel.isLoading, isFalse);
    });

    test('unlinkChild removes the unlinked child on success', () async {
      final viewModel = ParentSettingsViewModel(
        parentUid: 'parent_123',
        accountService: mockService,
      );
      await viewModel.loadChildren();

      final success = await viewModel.unlinkChild('family_1');

      expect(success, isTrue);
      expect(viewModel.children.length, 1);
      expect(viewModel.children.first.familyId, 'family_2');
      expect(viewModel.errorMessage, isNull);
    });

    test('unlinkChild sets errorMessage on failure', () async {
      mockService.unlinkChildResult = false;
      final viewModel = ParentSettingsViewModel(
        parentUid: 'parent_123',
        accountService: mockService,
      );
      await viewModel.loadChildren();

      final success = await viewModel.unlinkChild('family_1');

      expect(success, isFalse);
      expect(viewModel.children.length, 2);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('deleteAllData deletes data, calls auth delete and resets onboarding', () async {
      final viewModel = ParentSettingsViewModel(
        parentUid: 'parent_123',
        accountService: mockService,
      );
      await viewModel.loadChildren();

      final success = await viewModel.deleteAllData(
        authProvider: mockAuth,
        onboardingViewModel: onboardingViewModel,
      );

      expect(success, isTrue);
      expect(mockAuth.deleteAccountCalled, isTrue);
      expect(onboardingViewModel.termsAccepted, isFalse);
      expect(onboardingViewModel.pairingComplete, isFalse);
      expect(viewModel.children.isEmpty, isTrue);
    });
  });
}

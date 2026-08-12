import '../../models/subject.dart';

/// Abstract repository interface for Subject management.
abstract class BaseSubjectRepository {
  Stream<List<Subject>> streamSubjects(String userId);
  Future<List<Subject>> loadSubjects(String userId);
  Future<Subject?> createSubject(String userId, Subject subject);
  Future<void> updateSubject(String userId, Subject subject);
  Future<void> deleteSubject(String userId, String subjectId);
}

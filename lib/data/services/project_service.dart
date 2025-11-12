import '../models/project.dart';

abstract class ProjectService {
  Stream<List<Project>> watchProjects();

  Future<void> updateProject(Project project);

  Future<void> createProject(Project project);
}




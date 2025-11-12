import 'dart:async';

import '../../models/project.dart';
import '../project_service.dart';
import 'mock_data.dart';

class MockProjectService implements ProjectService {
  MockProjectService()
      : _controller = StreamController<List<Project>>.broadcast() {
    _controller.add(List<Project>.from(mockProjects));
  }

  final StreamController<List<Project>> _controller;
  final List<Project> _buffer = List<Project>.from(mockProjects);

  @override
  Stream<List<Project>> watchProjects() => _controller.stream;

  @override
  Future<void> createProject(Project project) async {
    _buffer.insert(0, project);
    _controller.add(List<Project>.from(_buffer));
  }

  @override
  Future<void> updateProject(Project project) async {
    final index = _buffer.indexWhere((element) => element.id == project.id);
    if (index == -1) return;
    _buffer[index] = project;
    _controller.add(List<Project>.from(_buffer));
  }

  void dispose() {
    _controller.close();
  }
}




import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/project.dart';
import '../../../data/services/project_service.dart';
import '../../../data/services/supabase/supabase_project_service.dart';

final projectServiceProvider = Provider<ProjectService>((ref) {
  final service = SupabaseProjectService();
  ref.onDispose(service.dispose);
  return service;
});

final projectControllerProvider =
    StateNotifierProvider<ProjectController, AsyncValue<List<Project>>>((ref) {
  final service = ref.watch(projectServiceProvider);
  return ProjectController(projectService: service);
});

class ProjectController extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectController({required ProjectService projectService})
      : _projectService = projectService,
        super(const AsyncValue.loading()) {
    _subscription = _projectService.watchProjects().listen(
      (projects) => state = AsyncValue.data(projects),
      onError: (error, stackTrace) => state = AsyncValue.error(error, stackTrace),
    );
  }

  final ProjectService _projectService;
  late final StreamSubscription<List<Project>> _subscription;

  Future<void> refresh() async {
    // Placeholder for real API refresh call.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}




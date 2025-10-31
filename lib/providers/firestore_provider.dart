import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/project.dart';

/// Firestore service singleton
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Stream of Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.authStateChanges();
});

/// Check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Stream of all projects for current user
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.streamProjects();
});

/// Filtered projects: Active only
final activeProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsStreamProvider);
  return projects.when(
    data: (list) => list.where((p) => !p.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Filtered projects: Completed only
final completedProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsStreamProvider);
  return projects.when(
    data: (list) => list.where((p) => p.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Project count
final projectCountProvider = Provider<int>((ref) {
  final projects = ref.watch(projectsStreamProvider);
  return projects.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Stream provider for projects
final projectListProvider = StreamProvider<List<Project>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for single project by ID
final projectProvider = Provider.family<AsyncValue<Project?>, String>((ref, id) {
  return ref.watch(projectListProvider).whenData(
    (projects) => projects.where((p) => p.id == id).firstOrNull,
  );
});

// Service class for project operations
class ProjectService {
  final FirebaseFirestore _firestore;
  final String _userId;

  ProjectService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('users').doc(_userId).collection('projects');

  Future<void> createProject({
    required String name,
    String? description,
  }) async {
    final project = Project(
      name: name,
      description: description,
    );

    await _projectsCollection.add(project.toFirestore());
  }

  Future<void> updateProject(Project project) async {
    if (project.id == null) return;
    
    final updatedData = project.copyWith(
      updatedAt: DateTime.now(),
    ).toFirestore();

    await _projectsCollection.doc(project.id).update(updatedData);
  }

  Future<void> deleteProject(Project project) async {
    if (project.id == null) return;
    
    await _projectsCollection.doc(project.id).delete();
  }

  Future<Project?> getProjectByName(String name) async {
    final querySnapshot = await _projectsCollection
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    
    return Project.fromFirestore(querySnapshot.docs.first);
  }

  Future<List<Project>> getAllProjects() async {
    final querySnapshot = await _projectsCollection
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList();
  }
}

// Provider for project service
final projectServiceProvider = Provider<ProjectService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) => user != null ? ProjectService(firestore, user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

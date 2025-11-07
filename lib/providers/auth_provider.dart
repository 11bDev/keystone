import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:keystone/services/auth_service.dart';
import 'package:keystone/services/google_calendar_service.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    ref.watch(googleSignInProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).firebaseAuth.authStateChanges();
});

// Google Calendar service provider
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final service = GoogleCalendarService();
  
  // Watch for auth changes and initialize calendar service when user signs in
  ref.listen(authStateChangesProvider, (previous, next) {
    next.whenData((user) async {
      if (user != null) {
        final googleSignIn = ref.read(googleSignInProvider);
        final googleUser = await googleSignIn.signInSilently();
        
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          
          if (googleAuth.accessToken != null) {
            // Create authenticated client
            final credentials = auth.AccessCredentials(
              auth.AccessToken(
                'Bearer',
                googleAuth.accessToken!,
                DateTime.now().add(const Duration(hours: 1)).toUtc(),
              ),
              null, // refreshToken
              ['https://www.googleapis.com/auth/calendar'],
            );
            
            final client = auth.authenticatedClient(
              http.Client(),
              credentials,
            );
            
            service.initialize(client);
          }
        }
      } else {
        service.dispose();
      }
    });
  });
  
  return service;
});

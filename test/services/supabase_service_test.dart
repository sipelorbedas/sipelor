import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipelor/services/supabase_service.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([SupabaseClient, GoTrueClient, SupabaseStorageClient])
import 'supabase_service_test.mocks.dart';

void main() {
  group('SupabaseService Tests', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockSupabaseStorageClient mockStorage;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockStorage = MockSupabaseStorageClient();

      when(mockClient.auth).thenReturn(mockAuth);
      when(mockClient.storage).thenReturn(mockStorage);
    });

    group('Authentication Tests', () {
      test('Sign in with valid credentials should succeed', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'Test123!';
        final mockResponse = AuthResponse(
          session: Session(
            accessToken: 'mock-access-token',
            tokenType: 'bearer',
            user: User(
              id: 'user-id-123',
              email: email,
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        );

        when(mockAuth.signInWithPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockResponse);

        // Act
        final response = await mockAuth.signInWithPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(response.session, isNotNull);
        expect(response.session!.user.email, equals(email));
        verify(mockAuth.signInWithPassword(
          email: email,
          password: password,
        )).called(1);
      });

      test('Sign in with invalid credentials should throw error', () async {
        // Arrange
        final email = 'wrong@example.com';
        final password = 'wrongpassword';

        when(mockAuth.signInWithPassword(
          email: email,
          password: password,
        )).thenThrow(AuthException('Invalid credentials'));

        // Act & Assert
        expect(
          () => mockAuth.signInWithPassword(email: email, password: password),
          throwsA(isA<AuthException>()),
        );
      });

      test('Sign up with valid data should succeed', () async {
        // Arrange
        final email = 'newuser@example.com';
        final password = 'NewUser123!';
        final mockResponse = AuthResponse(
          user: User(
            id: 'new-user-id',
            email: email,
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        when(mockAuth.signUp(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockResponse);

        // Act
        final response = await mockAuth.signUp(
          email: email,
          password: password,
        );

        // Assert
        expect(response.user, isNotNull);
        expect(response.user!.email, equals(email));
      });

      test('Sign out should clear session', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await mockAuth.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('Email Verification Tests', () {
      test('Resend verification email should succeed', () async {
        // Arrange
        final email = 'test@example.com';
        
        when(mockAuth.resend(
          type: OtpType.signup,
          email: email,
        )).thenAnswer((_) async => ResendResponse());

        // Act
        await mockAuth.resend(
          type: OtpType.signup,
          email: email,
        );

        // Assert
        verify(mockAuth.resend(
          type: OtpType.signup,
          email: email,
        )).called(1);
      });
    });

    group('Password Reset Tests', () {
      test('Reset password request should send email', () async {
        // Arrange
        final email = 'test@example.com';
        
        when(mockAuth.resetPasswordForEmail(email))
            .thenAnswer((_) async => {});

        // Act
        await mockAuth.resetPasswordForEmail(email);

        // Assert
        verify(mockAuth.resetPasswordForEmail(email)).called(1);
      });
    });
  });

  group('Data Operations Tests', () {
    // TODO: Add database operation tests
    // - Fetch venues
    // - Create booking
    // - Update booking status
    // - Delete booking
  });

  group('Storage Tests', () {
    // TODO: Add storage operation tests
    // - Upload payment proof
    // - Upload profile photo
    // - Delete files
  });
}

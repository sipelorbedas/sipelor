import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/review.dart';

void main() {
  group('Review Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testReview = Review(
      id: 'review123',
      bookingId: 'booking456',
      userId: 'user789',
      rating: 5,
      comment: 'Great experience!',
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('should create Review with all required fields', () {
      expect(testReview.id, 'review123');
      expect(testReview.bookingId, 'booking456');
      expect(testReview.userId, 'user789');
      expect(testReview.rating, 5);
      expect(testReview.comment, 'Great experience!');
      expect(testReview.createdAt, testDateTime);
      expect(testReview.updatedAt, testDateTime);
    });

    test('should create Review with null comment', () {
      final reviewWithoutComment = Review(
        id: 'review123',
        bookingId: 'booking456',
        userId: 'user789',
        rating: 4,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(reviewWithoutComment.comment, isNull);
      expect(reviewWithoutComment.rating, 4);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'review123',
        'booking_id': 'booking456',
        'user_id': 'user789',
        'rating': 5,
        'comment': 'Great experience!',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final review = Review.fromJson(json);

      expect(review.id, 'review123');
      expect(review.bookingId, 'booking456');
      expect(review.userId, 'user789');
      expect(review.rating, 5);
      expect(review.comment, 'Great experience!');
      expect(review.createdAt.year, 2024);
      expect(review.createdAt.month, 1);
      expect(review.updatedAt.year, 2024);
    });

    test('fromJson should handle null comment', () {
      final json = {
        'id': 'review123',
        'booking_id': 'booking456',
        'user_id': 'user789',
        'rating': 3,
        'comment': null,
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final review = Review.fromJson(json);

      expect(review.comment, isNull);
      expect(review.rating, 3);
    });

    test('toJson should convert Review to JSON correctly', () {
      final json = testReview.toJson();

      expect(json['id'], 'review123');
      expect(json['booking_id'], 'booking456');
      expect(json['user_id'], 'user789');
      expect(json['rating'], 5);
      expect(json['comment'], 'Great experience!');
      expect(json['created_at'], testDateTime.toIso8601String());
      expect(json['updated_at'], testDateTime.toIso8601String());
    });

    test('toJson should handle null comment', () {
      final reviewWithoutComment = Review(
        id: 'review123',
        bookingId: 'booking456',
        userId: 'user789',
        rating: 4,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final json = reviewWithoutComment.toJson();

      expect(json['comment'], isNull);
    });

    test('should handle rating boundaries', () {
      final minRating = Review(
        id: 'review123',
        bookingId: 'booking456',
        userId: 'user789',
        rating: 1,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final maxRating = Review(
        id: 'review123',
        bookingId: 'booking456',
        userId: 'user789',
        rating: 5,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(minRating.rating, 1);
      expect(maxRating.rating, 5);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testReview.toJson();
      final reconstructed = Review.fromJson(json);

      expect(reconstructed.id, testReview.id);
      expect(reconstructed.bookingId, testReview.bookingId);
      expect(reconstructed.userId, testReview.userId);
      expect(reconstructed.rating, testReview.rating);
      expect(reconstructed.comment, testReview.comment);
      expect(reconstructed.createdAt.toIso8601String(), 
             testReview.createdAt.toIso8601String());
    });
  });
}

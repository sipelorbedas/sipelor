import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/venue.dart';

void main() {
  group('Venue Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testVenue = Venue(
      id: 'venue123',
      name: 'Best Futsal Arena',
      venueType: 'Futsal',
      description: 'Premium futsal venue with modern facilities',
      address: 'Jl. Sports No. 123',
      city: 'Jakarta',
      imageUrl: 'https://example.com/venue.jpg',
      rating: 4.5,
      totalReviews: 100,
      isActive: true,
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('should create Venue with all fields', () {
      expect(testVenue.id, 'venue123');
      expect(testVenue.name, 'Best Futsal Arena');
      expect(testVenue.venueType, 'Futsal');
      expect(testVenue.description, 'Premium futsal venue with modern facilities');
      expect(testVenue.address, 'Jl. Sports No. 123');
      expect(testVenue.city, 'Jakarta');
      expect(testVenue.imageUrl, 'https://example.com/venue.jpg');
      expect(testVenue.rating, 4.5);
      expect(testVenue.totalReviews, 100);
      expect(testVenue.isActive, true);
      expect(testVenue.createdAt, testDateTime);
      expect(testVenue.updatedAt, testDateTime);
    });

    test('should create Venue with null optional fields', () {
      final venueMinimal = Venue(
        id: 'venue456',
        name: 'Basic Arena',
        address: 'Jl. Simple No. 1',
        city: 'Bandung',
        rating: 0.0,
        totalReviews: 0,
        isActive: true,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(venueMinimal.venueType, isNull);
      expect(venueMinimal.description, isNull);
      expect(venueMinimal.imageUrl, isNull);
      expect(venueMinimal.rating, 0.0);
      expect(venueMinimal.totalReviews, 0);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'venue123',
        'name': 'Best Futsal Arena',
        'venue_type': 'Futsal',
        'description': 'Premium futsal venue',
        'address': 'Jl. Sports No. 123',
        'city': 'Jakarta',
        'image_url': 'https://example.com/venue.jpg',
        'rating': 4.5,
        'total_reviews': 100,
        'is_active': true,
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final venue = Venue.fromJson(json);

      expect(venue.id, 'venue123');
      expect(venue.name, 'Best Futsal Arena');
      expect(venue.venueType, 'Futsal');
      expect(venue.rating, 4.5);
      expect(venue.totalReviews, 100);
      expect(venue.isActive, true);
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'id': 'venue456',
        'name': 'Basic Arena',
        'address': 'Jl. Simple No. 1',
        'city': 'Bandung',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final venue = Venue.fromJson(json);

      expect(venue.venueType, isNull);
      expect(venue.description, isNull);
      expect(venue.imageUrl, isNull);
      expect(venue.rating, 0.0); // Default value
      expect(venue.totalReviews, 0); // Default value
      expect(venue.isActive, true); // Default value
    });

    test('fromJson should handle integer rating', () {
      final json = {
        'id': 'venue789',
        'name': 'Test Arena',
        'address': 'Test Address',
        'city': 'Test City',
        'rating': 5, // Integer instead of double
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final venue = Venue.fromJson(json);

      expect(venue.rating, 5.0);
    });

    test('toJson should convert Venue to JSON correctly', () {
      final json = testVenue.toJson();

      expect(json['id'], 'venue123');
      expect(json['name'], 'Best Futsal Arena');
      expect(json['venue_type'], 'Futsal');
      expect(json['description'], 'Premium futsal venue with modern facilities');
      expect(json['address'], 'Jl. Sports No. 123');
      expect(json['city'], 'Jakarta');
      expect(json['image_url'], 'https://example.com/venue.jpg');
      expect(json['rating'], 4.5);
      expect(json['total_reviews'], 100);
      expect(json['is_active'], true);
      expect(json['created_at'], testDateTime.toIso8601String());
      expect(json['updated_at'], testDateTime.toIso8601String());
    });

    test('toJson should handle null optional fields', () {
      final venueMinimal = Venue(
        id: 'venue456',
        name: 'Basic Arena',
        address: 'Jl. Simple No. 1',
        city: 'Bandung',
        rating: 0.0,
        totalReviews: 0,
        isActive: false,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final json = venueMinimal.toJson();

      expect(json['venue_type'], isNull);
      expect(json['description'], isNull);
      expect(json['image_url'], isNull);
      expect(json['is_active'], false);
    });

    test('should handle different venue types', () {
      final types = ['Futsal', 'Badminton', 'Basketball', 'Volleyball'];
      
      for (final type in types) {
        final venue = Venue(
          id: 'venue-$type',
          name: '$type Arena',
          venueType: type,
          address: 'Test Address',
          city: 'Test City',
          rating: 4.0,
          totalReviews: 50,
          isActive: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        expect(venue.venueType, type);
      }
    });

    test('should handle rating boundaries', () {
      final noRating = Venue(
        id: 'venue1',
        name: 'No Rating Venue',
        address: 'Address',
        city: 'City',
        rating: 0.0,
        totalReviews: 0,
        isActive: true,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final perfectRating = Venue(
        id: 'venue2',
        name: 'Perfect Venue',
        address: 'Address',
        city: 'City',
        rating: 5.0,
        totalReviews: 1000,
        isActive: true,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(noRating.rating, 0.0);
      expect(perfectRating.rating, 5.0);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testVenue.toJson();
      final reconstructed = Venue.fromJson(json);

      expect(reconstructed.id, testVenue.id);
      expect(reconstructed.name, testVenue.name);
      expect(reconstructed.venueType, testVenue.venueType);
      expect(reconstructed.rating, testVenue.rating);
      expect(reconstructed.totalReviews, testVenue.totalReviews);
      expect(reconstructed.isActive, testVenue.isActive);
    });
  });
}

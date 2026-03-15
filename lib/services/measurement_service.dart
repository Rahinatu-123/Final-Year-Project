import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MeasurementShareUnit { cm, inch, both }

class MeasurementService {
  MeasurementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> saveMeasurementSession({
    required String gender,
    required double heightCm,
    required double weightKg,
    required Map<String, double> measurements,
    required int inferenceMs,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception('User not signed in');
    }

    final normalized = measurements.map(
      (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
    );

    final payload = {
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'measurements': normalized,
      'inferenceMs': inferenceMs,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .add(payload);

    await _firestore.collection('users').doc(uid).set({
      'latestMeasurement': payload,
      'latestMeasurementUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchLatestMeasurement() {
    final uid = _currentUserId;
    if (uid == null) {
      return const Stream<Map<String, dynamic>?>.empty();
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.data()?['latestMeasurement'] as Map<String, dynamic>?,
        );
  }

  static String buildShareText({
    required String gender,
    required double heightCm,
    required double weightKg,
    required Map<String, double> measurements,
    MeasurementShareUnit unit = MeasurementShareUnit.both,
  }) {
    final sortedEntries = measurements.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final allMeasurementsText = sortedEntries
        .map((entry) {
          final prettyName = entry.key
              .split('-')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');

          if (unit == MeasurementShareUnit.cm) {
            return '- $prettyName: ${entry.value.toStringAsFixed(1)} cm';
          }

          final inchValue = entry.value / 2.54;
          if (unit == MeasurementShareUnit.inch) {
            return '- $prettyName: ${inchValue.toStringAsFixed(1)} in';
          }

          return '- $prettyName: ${entry.value.toStringAsFixed(1)} cm (${inchValue.toStringAsFixed(1)} in)';
        })
        .join('\n');

    final unitLabel = switch (unit) {
      MeasurementShareUnit.cm => 'CM',
      MeasurementShareUnit.inch => 'INCH',
      MeasurementShareUnit.both => 'CM + INCH',
    };

    return [
      'My Body Measurements (FashionHub)',
      'Gender: ${gender[0].toUpperCase()}${gender.substring(1)}',
      'Height: ${heightCm.toStringAsFixed(1)} cm',
      'Weight: ${weightKg.toStringAsFixed(1)} kg',
      'Shared Unit: $unitLabel',
      'Total: ${sortedEntries.length} measurements',
      '',
      allMeasurementsText,
    ].join('\n');
  }
}

String resolveProfileImage(Map<String, dynamic>? data, {String fallback = ''}) {
  if (data == null) return fallback;

  final candidates = <dynamic>[
    data['profileImage'],
    data['profilePictureUrl'],
    data['logoUrl'],
    data['photoURL'],
    data['photoUrl'],
  ];

  for (final candidate in candidates) {
    final value = (candidate ?? '').toString().trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return fallback;
}

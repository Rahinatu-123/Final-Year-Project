import 'package:cloud_firestore/cloud_firestore.dart';

class Style {
  final String? id;
  final String name;
  final String description;
  final String category; // 'Upper-body', 'Lower-body', 'Dresses', etc.
  final String imageUrl;
  final String? sellerId;
  final String? createdBy;
  final DateTime? createdAt;
  final List<String>? tags;
  final int? likes;
  final bool? isPublic;

  Style({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
    this.createdBy,
    this.createdAt,
    this.tags,
    this.likes,
    this.isPublic = true,
  });

  // Convert Style to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'createdBy': createdBy,
      'createdAt': createdAt ?? Timestamp.now(),
      'tags': tags ?? [],
      'likes': likes ?? 0,
      'isPublic': isPublic ?? true,
    };
  }

  // Create Style from Firestore document
  factory Style.fromMap(Map<String, dynamic> map, String docId) {
    return Style(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Dresses',
      imageUrl: map['imageUrl'] ?? '',
      sellerId: map['sellerId'],
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      likes: map['likes'] ?? 0,
      isPublic: map['isPublic'] ?? true,
    );
  }

  // Create Style from Firebase DocumentSnapshot
  factory Style.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Style.fromMap(data, doc.id);
  }

  // Copy with method
  Style copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    String? sellerId,
    String? createdBy,
    DateTime? createdAt,
    List<String>? tags,
    int? likes,
    bool? isPublic,
  }) {
    return Style(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  String toString() =>
      'Style(id: $id, name: $name, category: $category, imageUrl: $imageUrl)';
}

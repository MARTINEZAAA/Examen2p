class Character {
  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.origin,
    required this.image,
    this.type = '',
  });

  final int id;
  final String name;
  final String status;
  final String species;
  final String gender;
  final String origin;
  final String image;
  final String type;

  factory Character.fromJson(Map<String, dynamic> json) {
    final originData = json['origin'];
    return Character(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sin nombre',
      status: json['status'] as String? ?? 'Desconocido',
      species: json['species'] as String? ?? 'Desconocida',
      gender: json['gender'] as String? ?? 'Desconocido',
      origin: originData is Map<String, dynamic>
          ? originData['name'] as String? ?? 'Desconocido'
          : 'Desconocido',
      image: json['image'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  Character copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? gender,
    String? origin,
    String? image,
    String? type,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      origin: origin ?? this.origin,
      image: image ?? this.image,
      type: type ?? this.type,
    );
  }
}

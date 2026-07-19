// Capa Domain: Entidades puras de negocio. 
// No dependen de ninguna librería externa (ni Flutter, ni JSON, ni APIs).

class UserEntity {
  final String id;
  final String name;

  UserEntity({required this.id, required this.name});
}

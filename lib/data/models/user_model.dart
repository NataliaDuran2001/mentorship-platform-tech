// Capa Data: Contiene los modelos que parsean la información desde/hacia JSON o la base de datos.
// Los modelos heredan o se mapean a las Entidades de la capa Domain.

class UserModel {
  final String id;
  final String name;

  UserModel({required this.id, required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

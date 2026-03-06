class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String? profileImageUrl;
  final double? dailyCarbonLimit;
  final String? dateOfBirth;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.profileImageUrl,
    this.dailyCarbonLimit,
    this.dateOfBirth,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      profileImageUrl: json['profileImageUrl'],
      dailyCarbonLimit: json['dailyCarbonLimit'] != null
          ? double.tryParse(json['dailyCarbonLimit'].toString())
          : null,
      dateOfBirth: json['dateOfBirth'],
      createdAt: json['CreatedAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'dailyCarbonLimit': dailyCarbonLimit,
      'dateOfBirth': dateOfBirth,
    };
  }
}

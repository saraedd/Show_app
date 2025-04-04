
class Show {
  final int id;
  final String title;
  final String description;
  final String category;
  final String image;

  Show({required this.id, required this.title, required this.description, required this.category, required this.image});

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      image: json['image'],
    );
  }
}

class WallpaperModel {
  final String id;
  final String imageUrl;

  WallpaperModel({
    required this.id,
    required this.imageUrl,
  });

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: json['id'].toString(),
      imageUrl: json['imageUrl'],
    );
  }
}

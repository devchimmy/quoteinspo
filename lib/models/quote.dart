class Quote {
  final int id;
  final String quote;
  bool isFavorite;

  Quote({required this.id, required this.quote, this.isFavorite = false});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      quote: json['quote'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quote': quote,
        'isFavorite': isFavorite,
      };
}

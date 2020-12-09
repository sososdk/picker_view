class District {
  final String citycode;
  final String adcode;
  final String name;
  final String center;
  final String level;
  final List<District> districts;

  District({
    this.citycode,
    this.adcode,
    this.name,
    this.center,
    this.level,
    this.districts,
  });

  factory District.fromJson(dynamic json) {
    return District(
      citycode: (json['citycode'] is String) ? json['citycode'] : null,
      adcode: json['adcode'],
      name: json['name'],
      center: json['center'],
      level: json['level'],
      districts:
          (json['districts'] as List).map((e) => District.fromJson(e)).toList(),
    );
  }
}

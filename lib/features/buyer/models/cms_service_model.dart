class CmsServiceModel {
  final String id;
  final String title;
  final String slug;
  final String shortDescription;
  final String description;
  final String heading;
  final String heroImage;
  final List<String> imageTags;
  final String icon;
  final String? videoUrl;
  final List<String> features;
  final List<String> benefits;
  final String ctaText;
  final String ctaLink;
  final bool isNew;
  final List<Map<String, String>> faqs;

  const CmsServiceModel({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription = '',
    this.description = '',
    this.heading = '',
    this.heroImage = '',
    this.imageTags = const [],
    this.icon = '',
    this.videoUrl,
    this.features = const [],
    this.benefits = const [],
    this.ctaText = 'Enquire Now',
    this.ctaLink = '',
    this.isNew = false,
    this.faqs = const [],
  });

  factory CmsServiceModel.fromJson(Map<String, dynamic> json) {
    final imageTagsRaw = json['imageTags'];
    final featuresRaw = json['features'];
    final benefitsRaw = json['benefits'];
    final faqsRaw = json['faqs'];

    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    List<Map<String, String>> parseFaqs(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map>().map((f) {
          return {
            'question': f['question']?.toString() ?? '',
            'answer': f['answer']?.toString() ?? '',
          };
        }).toList();
      }
      return [];
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? json['slug']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final slug = json['slug']?.toString() ?? '';
    final shortDesc = json['shortDescription']?.toString() ?? json['subheading']?.toString() ?? '';
    final desc = json['description']?.toString() ?? '';
    final heading = json['heading']?.toString() ??
        json['overviewHeading']?.toString() ??
        json['heroCardTitle']?.toString() ??
        title;
    final hero = json['heroImage']?.toString() ??
        json['overviewImage']?.toString() ??
        json['image']?.toString() ??
        '';
    final icon = json['icon']?.toString() ?? '';
    final video = json['videoUrl']?.toString() ?? json['video']?.toString();
    final ctaText = json['ctaText']?.toString() ?? 'Enquire Now';
    final ctaLink = json['ctaLink']?.toString() ?? '';
    final isNew = json['isNew'] == true || json['badge'] == 'New';

    return CmsServiceModel(
      id: id,
      title: title,
      slug: slug,
      shortDescription: shortDesc,
      description: desc,
      heading: heading,
      heroImage: hero,
      imageTags: parseStringList(imageTagsRaw),
      icon: icon,
      videoUrl: video,
      features: parseStringList(featuresRaw),
      benefits: parseStringList(benefitsRaw),
      ctaText: ctaText,
      ctaLink: ctaLink,
      isNew: isNew,
      faqs: parseFaqs(faqsRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'shortDescription': shortDescription,
      'description': description,
      'heading': heading,
      'heroImage': heroImage,
      'imageTags': imageTags,
      'icon': icon,
      'videoUrl': videoUrl,
      'features': features,
      'benefits': benefits,
      'ctaText': ctaText,
      'ctaLink': ctaLink,
      'isNew': isNew,
      'faqs': faqs,
    };
  }

  /// Default services (empty by default to avoid mock data)
  static List<CmsServiceModel> get defaultServices => const [];
}

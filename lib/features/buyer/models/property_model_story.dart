import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/app_image.dart';
import 'testimonial_model.dart';

enum StoryKind { property, promo, review }

class StorySpec {
  final IconData icon;
  final String text;
  const StorySpec(this.icon, this.text);
}

/// One circle in "Property Stories" (= one full-screen story with many slides).
class PropertyStoryModel {
  final String id;
  final StoryKind kind;
  final String label; // text under the circle
  final String preTitle;
  final String hlTitle; // highlighted (green) part of the title
  final String postTitle;
  final String location;
  final List<String> tagline;
  final String? price;
  final String priceNote;
  final List<StorySpec> specs;
  final List<String> images;
  final String? videoUrl;
  final List<Color> gradient;
  final IconData icon;
  final bool isNew;
  final String? propertyId;
  final String? reviewText;
  final String shareText;
  final String shareSubject;
  final String enquirySubject;
  final Map<String, dynamic>? propertyJson; // raw property (for details screen)

  const PropertyStoryModel({
    required this.id,
    required this.kind,
    required this.label,
    this.preTitle = '',
    required this.hlTitle,
    this.postTitle = '',
    this.location = '',
    this.tagline = const [],
    this.price,
    this.priceNote = '',
    this.specs = const [],
    this.images = const [],
    this.videoUrl,
    this.gradient = const [Color(0xFF0B3D33), Color(0xFF2ECC71)],
    this.icon = Icons.home_work_rounded,
    this.isNew = false,
    this.propertyId,
    this.reviewText,
    this.shareText = 'Find verified properties on DigiNiwas: https://diginiwas.com',
    this.shareSubject = 'DigiNiwas',
    this.enquirySubject = 'Property Story',
    this.propertyJson,
  });

  bool get isProperty => kind == StoryKind.property;
  bool get hasMedia => images.isNotEmpty || (videoUrl ?? '').isNotEmpty;

  /// Seen-state (grey ring) – lives only for the app session.
  static final RxSet<String> seen = <String>{}.obs;

  // ───────────── builders ─────────────

  /// [j] = BoostedPropertyItem.toJson() / RecommendedProperties.toJson()
  factory PropertyStoryModel.fromPropertyJson(Map<String, dynamic> j,
      {bool isNew = false}) {
    String s(String k) => (j[k] ?? '').toString().trim();
    final title = s('title').isNotEmpty ? s('title') : 'Featured Property';
    final parts = _splitTitle(title);

    final loc = [s('locality'), s('city')].where((e) => e.isNotEmpty).join(', ');
    final location = loc.isNotEmpty ? loc : s('address');

    final tx = s('transactionType').toLowerCase();
    final txLabel = tx.contains('rent')
        ? 'For Rent'
        : (tx.contains('sale') || tx.contains('buy') ? 'For Sale' : s('transactionType'));

    final category = s('category');
    final tagline = <String>[
      if (category.isNotEmpty) _cap(category),
      if (s('furnishing').isNotEmpty) s('furnishing'),
      if (txLabel.isNotEmpty) txLabel,
    ].take(3).toList();

    final priceNum = num.tryParse(s('price')) ?? 0;
    final perSqft = num.tryParse(s('pricePerSqft')) ?? 0;

    final beds = int.tryParse(s('bedrooms').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final baths = int.tryParse(s('bathrooms').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final specs = <StorySpec>[
      if (beds > 0) StorySpec(Icons.bed_rounded, '$beds Bedrooms'),
      if (baths > 0) StorySpec(Icons.bathtub_outlined, '$baths Bathrooms'),
      if (s('furnishing').isNotEmpty)
        StorySpec(Icons.chair_alt_rounded, s('furnishing')),
      if (perSqft > 0) StorySpec(Icons.square_foot_rounded, '₹$perSqft / Sq.Ft'),
      if (category.isNotEmpty && beds == 0)
        StorySpec(Icons.category_outlined, _cap(category)),
      if (txLabel.isNotEmpty && beds == 0)
        StorySpec(Icons.sell_outlined, txLabel),
    ].take(4).toList();

    final imgs = <String>[];
    dynamic rawImgs = j['images'];
    if (rawImgs is! List || rawImgs.isEmpty) {
      if (j['media'] is Map) {
        final media = j['media'] as Map;
        rawImgs = media['images'] ?? media['photos'];
      }
    }
    if (rawImgs is! List || rawImgs.isEmpty) {
      rawImgs = j['photos'] ?? j['gallery'];
    }

    if (rawImgs is List) {
      for (final e in rawImgs) {
        final u = e is Map
            ? (e['secure_url'] ?? e['url'] ?? e['imageUrl'] ?? e['image'] ?? e['path'])?.toString()
            : e?.toString();
        if (u != null) {
          final clean = ImageCase.sanitizeUrl(u);
          if (clean != null && clean.isNotEmpty) imgs.add(clean);
        }
      }
    }
    if (imgs.isEmpty) {
      for (final k in ['image', 'imageUrl', 'coverImage', 'thumbnail', 'photo']) {
        final single = j[k];
        if (single != null) {
          final clean = ImageCase.sanitizeUrl(single.toString());
          if (clean != null && clean.isNotEmpty) {
            imgs.add(clean);
            break;
          }
        }
      }
    }


    final priceText = priceNum > 0 ? formatPrice(priceNum) : null;
    // same id the home-screen heart uses: _id first, then propertyId
    final pid = s('_id').isNotEmpty ? s('_id') : s('propertyId');

    return PropertyStoryModel(
      id: pid.isNotEmpty ? pid : title,
      kind: StoryKind.property,
      label: _label(j),
      preTitle: parts[0],
      hlTitle: parts[1],
      postTitle: parts[2],
      location: location,
      tagline: tagline,
      price: priceText,
      priceNote: perSqft > 0 ? '₹$perSqft / sq.ft' : 'Best price',
      specs: specs,
      images: imgs,
      videoUrl: s('videoUrl').isNotEmpty ? s('videoUrl') : null,
      icon: Icons.home_work_rounded,
      isNew: isNew,
      propertyId: pid.isNotEmpty ? pid : null,
      propertyJson: j,
      shareSubject: 'Verified Property on DigiNiwas: $title',
      shareText: [
        title,
        if (location.isNotEmpty) '📍 $location',
        if (priceText != null) '💰 $priceText',
        '',
        'View on DigiNiwas: https://diginiwas.com',
        if (pid.isNotEmpty) 'Property ID: $pid',
      ].join('\n'),
      enquirySubject:
      'Property Story: $title${location.isNotEmpty ? ' ($location)' : ''}${pid.isNotEmpty ? ' [ID $pid]' : ''}${priceText != null ? ' - $priceText' : ''}',
    );
  }

  factory PropertyStoryModel.fromTestimonial(TestimonialModel t) {
    return PropertyStoryModel(
      id: 'review_${t.id}',
      kind: StoryKind.review,
      label: 'Customer Review',
      hlTitle: t.name,
      preTitle: '',
      location: t.designation,
      tagline: const ['Real review', 'Real family', 'Real home'],
      images: (t.imageUrl ?? '').isNotEmpty ? [t.imageUrl!] : const [],
      videoUrl: (t.videoLink ?? '').trim().isNotEmpty ? t.videoLink!.trim() : null,
      reviewText: t.review,
      gradient: const [Color(0xFF0B3D33), Color(0xFF2ECC71)],
      icon: Icons.format_quote_rounded,
    );
  }

  /// Shown when no boosted / AI-suggested property is available.
  static List<PropertyStoryModel> promoStories({TestimonialModel? review}) {
    const share = 'Find verified properties on DigiNiwas: https://diginiwas.com';
    PropertyStoryModel p(String id, String label, String pre, String hl,
        String post, IconData icon, List<Color> g, {bool isNew = false}) =>
        PropertyStoryModel(
          id: 'promo_$id',
          kind: StoryKind.promo,
          label: label,
          preTitle: pre,
          hlTitle: hl,
          postTitle: post,
          location: 'DigiNiwas • Verified',
          tagline: const ['Verified listings', 'Trusted sellers', 'Zero hassle'],
          gradient: g,
          icon: icon,
          isNew: isNew,
          shareText: share,
          shareSubject: 'DigiNiwas Property Search',
        );
    return [
      p('villa', 'Luxury Villa', 'Find Your ', 'Dream', ' Villa',
          Icons.villa_rounded, const [Color(0xFF0A2540), Color(0xFFE08A3C)],
          isNew: true),
      p('flat', '3BHK Flat', 'Explore ', 'Smart', ' Flats',
          Icons.apartment_rounded, const [Color(0xFF2B4A78), Color(0xFFF0B27A)]),
      p('plot', 'Plot Tour', 'Invest in ', 'Prime', ' Plots',
          Icons.landscape_rounded, const [Color(0xFF1F6FA8), Color(0xFF6BBF7A)]),
      p('comm', 'Commercial', 'Grow with ', 'Commercial', ' Spaces',
          Icons.storefront_rounded, const [Color(0xFF33415C), Color(0xFFFFB36B)]),
      review != null
          ? PropertyStoryModel.fromTestimonial(review)
          : p('review', 'Customer Review', 'Hear From ', 'Happy', ' Families',
          Icons.format_quote_rounded,
          const [Color(0xFF0B3D33), Color(0xFF2ECC71)]),
    ];
  }

  // ───────────── helpers ─────────────

  static String _cap(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

  static String _label(Map<String, dynamic> j) {
    final cat = (j['category'] ?? '').toString().trim();
    final c = cat.toLowerCase();
    final bed = int.tryParse(
        (j['bedrooms'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (c.contains('plot') || c.contains('land')) return 'Plot Tour';
    if (c.contains('commercial') || c.contains('shop') || c.contains('office')) {
      return 'Commercial';
    }
    if (c.contains('villa') || c.contains('house')) return 'Luxury Villa';
    if (bed > 0) return '${bed}BHK Flat';
    if (cat.isNotEmpty) return _cap(cat);
    final t = (j['title'] ?? '').toString().trim();
    return t.isNotEmpty ? t : 'Property';
  }

  /// Returns [pre, highlight, post]
  static List<String> _splitTitle(String title) {
    final m = RegExp(r'\d+\s*BHK', caseSensitive: false).firstMatch(title);
    if (m != null) {
      return [title.substring(0, m.start), m.group(0)!, title.substring(m.end)];
    }
    final w = title.split(RegExp(r'\s+'));
    if (w.length >= 3) {
      return ['${w[0]} ', w[1], ' ${w.sublist(2).join(' ')}'];
    }
    if (w.length == 2) return ['', w[0], ' ${w[1]}'];
    return ['', title, ''];
  }
}

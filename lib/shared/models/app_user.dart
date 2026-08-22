import 'package:equatable/equatable.dart';

import '../../core/constants/enums.dart';

/// The user *account* entity, mirroring `users/{uid}` in Firestore.
///
/// Pure domain object: no Firebase types. Dates are ISO-8601 strings in JSON so
/// the same map works for both Firestore and the offline Hive cache.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.role,
    this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
    this.onboardingComplete = false,
    this.activePregnancyId,
    this.linkedPregnancies = const [],
    this.isPremium = false,
    this.isAnonymous = false,
    this.locale = 'en',
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final bool onboardingComplete;
  final String? activePregnancyId;
  final List<String> linkedPregnancies;
  final bool isPremium;
  final bool isAnonymous;
  final String locale;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// A freshly-signed-in user whose Firestore document does not exist yet.
  factory AppUser.initial({
    required String uid,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    bool isAnonymous = false,
    UserRole role = UserRole.mother,
  }) =>
      AppUser(
        uid: uid,
        role: role,
        email: email,
        phone: phone,
        displayName: displayName,
        photoUrl: photoUrl,
        isAnonymous: isAnonymous,
      );

  AppUser copyWith({
    UserRole? role,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    bool? onboardingComplete,
    String? activePregnancyId,
    List<String>? linkedPregnancies,
    bool? isPremium,
    bool? isAnonymous,
    String? locale,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppUser(
        uid: uid,
        role: role ?? this.role,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        activePregnancyId: activePregnancyId ?? this.activePregnancyId,
        linkedPregnancies: linkedPregnancies ?? this.linkedPregnancies,
        isPremium: isPremium ?? this.isPremium,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        locale: locale ?? this.locale,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'role': role.name,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'onboardingComplete': onboardingComplete,
        'activePregnancyId': activePregnancyId,
        'linkedPregnancies': linkedPregnancies,
        'isPremium': isPremium,
        'isAnonymous': isAnonymous,
        'locale': locale,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        role: UserRole.fromName(json['role'] as String?),
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        activePregnancyId: json['activePregnancyId'] as String?,
        linkedPregnancies:
            (json['linkedPregnancies'] as List<dynamic>?)?.cast<String>() ??
                const [],
        isPremium: json['isPremium'] as bool? ?? false,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
        locale: json['locale'] as String? ?? 'en',
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        uid,
        role,
        email,
        phone,
        displayName,
        photoUrl,
        onboardingComplete,
        activePregnancyId,
        linkedPregnancies,
        isPremium,
        isAnonymous,
        locale,
      ];
}

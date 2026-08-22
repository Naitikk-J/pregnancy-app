import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/ai_assistant/domain/chat_message.dart';
import 'package:pregnancy_companion/features/baby_names/domain/baby_name.dart';
import 'package:pregnancy_companion/features/birth_plan/domain/birth_plan.dart';
import 'package:pregnancy_companion/features/birth_plan/domain/birth_plan_builder.dart';
import 'package:pregnancy_companion/features/community/domain/community_post.dart';

void main() {
  group('BirthPlanBuilder', () {
    test('includes chosen preferences and mother name', () {
      const plan = BirthPlan(
        birthType: BirthType.vaginal,
        painPreference: PainPreference.epidural,
        feeding: FeedingPreference.breast,
        companion: 'My husband',
        skinToSkin: true,
        delayedCordClamping: true,
        environmentNotes: 'Dim lights and calm music.',
        specialRequests: 'Please explain each step.',
      );
      final report = BirthPlanBuilder.build(plan, motherName: 'Asha');

      expect(report, contains('For: Asha'));
      expect(report, contains('Vaginal birth'));
      expect(report, contains('Epidural'));
      expect(report, contains('My husband'));
      expect(report, contains('Immediate skin-to-skin: Yes, please'));
      expect(report, contains('Delayed cord clamping: Yes, please'));
      expect(report, contains('Breastfeeding'));
      expect(report, contains('Dim lights and calm music.'));
      expect(report, contains('Please explain each step.'));
    });

    test('omits empty optional sections', () {
      const plan = BirthPlan();
      final report = BirthPlanBuilder.build(plan);
      expect(report, isNot(contains('ENVIRONMENT & COMFORT')));
      expect(report, isNot(contains('SPECIAL REQUESTS')));
      expect(report, isNot(contains('For:')));
      expect(report, contains('No preference'));
    });

    test('birth plan round-trips through JSON', () {
      const plan = BirthPlan(
        birthType: BirthType.cesarean,
        painPreference: PainPreference.natural,
        feeding: FeedingPreference.mixed,
        companion: 'Mom',
        delayedCordClamping: true,
        skinToSkin: false,
      );
      final restored = BirthPlan.fromJson(plan.toJson());
      expect(restored, plan);
      expect(restored.birthType, BirthType.cesarean);
      expect(restored.skinToSkin, isFalse);
    });
  });

  group('Baby names catalog', () {
    test('every entry has a name, origin and meaning', () {
      for (final n in kBabyNames) {
        expect(n.name.trim(), isNotEmpty);
        expect(n.origin.trim(), isNotEmpty);
        expect(n.meaning.trim(), isNotEmpty);
      }
    });

    test('slugs are unique and url-safe', () {
      final slugs = kBabyNames.map((n) => n.slug).toList();
      expect(slugs.toSet().length, slugs.length);
      for (final s in slugs) {
        expect(s, matches(RegExp(r'^[a-z0-9-]+$')));
      }
    });

    test('covers all three genders', () {
      final genders = kBabyNames.map((n) => n.gender).toSet();
      expect(genders, containsAll(NameGender.values));
    });

    test('FavoriteName.from + JSON round-trip preserves fields', () {
      const bn = BabyName(
        name: 'Aarav',
        gender: NameGender.boy,
        origin: 'Sanskrit',
        meaning: 'Peaceful',
      );
      final fav = FavoriteName.from(bn);
      expect(fav.id, 'aarav');
      final restored = FavoriteName.fromJson(fav.toJson());
      expect(restored.id, 'aarav');
      expect(restored.name, 'Aarav');
      expect(restored.gender, NameGender.boy);
      expect(restored.meaning, 'Peaceful');
    });
  });

  group('CommunityPost', () {
    test('likeCount derives from likedBy and membership check works', () {
      final post = CommunityPost(
        id: 'p1',
        authorUid: 'u1',
        authorName: 'Asha',
        text: 'Hello',
        createdAt: _fixedDate,
        likedBy: const ['u2', 'u3'],
      );
      expect(post.likeCount, 2);
      expect(post.likedBy_('u2'), isTrue);
      expect(post.likedBy_('u1'), isFalse);
    });

    test('round-trips through JSON', () {
      final post = CommunityPost(
        id: 'p1',
        authorUid: 'u1',
        authorName: 'Asha',
        text: 'Feeling great today',
        createdAt: _fixedDate,
        week: 20,
        likedBy: const ['u2'],
        commentCount: 3,
      );
      final restored = CommunityPost.fromJson(post.toJson());
      expect(restored, post);
      expect(restored.week, 20);
      expect(restored.commentCount, 3);
    });

    test('comment round-trips through JSON', () {
      final c = CommunityComment(
        id: 'c1',
        authorUid: 'u1',
        authorName: 'Asha',
        text: 'Congrats!',
        createdAt: _fixedDate,
      );
      final restored = CommunityComment.fromJson(c.toJson());
      expect(restored, c);
    });
  });

  group('ChatMessage', () {
    test('copyWith updates pending/error without changing identity', () {
      const msg = ChatMessage(
        id: 'm1',
        role: ChatRole.assistant,
        text: '',
        pending: true,
      );
      final done = msg.copyWith(text: 'Hi there', pending: false);
      expect(done.id, 'm1');
      expect(done.text, 'Hi there');
      expect(done.pending, isFalse);
      expect(done.isUser, isFalse);
    });

    test('user role reports isUser', () {
      const msg = ChatMessage(id: 'm2', role: ChatRole.user, text: 'Hi');
      expect(msg.isUser, isTrue);
    });
  });
}

final _fixedDate = DateTime.utc(2026, 8, 8, 10, 30);

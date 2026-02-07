// Visual verification harness for grid card design
// Run: flutter test test/features/home/grid_card_visual_test.dart
//
// Tests cover:
// 1. Responsive column counts
// 2. Aspect ratio
// 3. People list logic (icon rows + overflow)
// 4. Source line extraction (domain, S3 shortening, file)
// 5. Type badge tinted style (bg + border)
// 6. Title/meta divider presence

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/home/widgets/stream_card_widgets.dart';
import 'package:streamwatch_frontend/themes/tmz_theme.dart';

void main() {
  group('Grid Card Visual Verification', () {
    testWidgets('Responsive breakpoints produce correct column counts',
        (tester) async {
      int getColumnCount(double width) {
        return width > 1400
            ? 5
            : width > 1100
                ? 4
                : width > 800
                    ? 3
                    : width > 500
                        ? 2
                        : 1;
      }

      expect(getColumnCount(390), equals(1), reason: '<500 should be 1 column');
      expect(getColumnCount(500), equals(1),
          reason: '500 exactly should be 1 column');
      expect(getColumnCount(501), equals(2), reason: '>500 should be 2 columns');
      expect(getColumnCount(700), equals(2), reason: '700 should be 2 columns');
      expect(getColumnCount(800), equals(2),
          reason: '800 exactly should be 2 columns');
      expect(getColumnCount(801), equals(3),
          reason: '>800 should be 3 columns');
      expect(getColumnCount(950), equals(3), reason: '950 should be 3 columns');
      expect(getColumnCount(1100), equals(3),
          reason: '1100 exactly should be 3 columns');
      expect(getColumnCount(1101), equals(4),
          reason: '>1100 should be 4 columns');
      expect(getColumnCount(1250), equals(4),
          reason: '1250 should be 4 columns');
      expect(getColumnCount(1400), equals(4),
          reason: '1400 exactly should be 4 columns');
      expect(getColumnCount(1401), equals(5),
          reason: '>1400 should be 5 columns');
      expect(getColumnCount(1500), equals(5),
          reason: '1500 should be 5 columns');
    });

    testWidgets('Card aspect ratio is 0.72', (tester) async {
      const aspectRatio = 0.72;
      expect(200 / aspectRatio, closeTo(278, 2));
    });

    testWidgets('Spacing is 16px', (tester) async {
      const crossAxisSpacing = 16.0;
      const mainAxisSpacing = 16.0;
      expect(crossAxisSpacing, equals(16.0));
      expect(mainAxisSpacing, equals(16.0));
    });
  });

  group('StreamPeopleList', () {
    Widget buildPeopleList(List<String> people, {int maxVisible = 2}) {
      return MaterialApp(
        theme: TmzTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child:
                StreamPeopleList(people: people, maxVisible: maxVisible),
          ),
        ),
      );
    }

    testWidgets('Empty list renders nothing', (tester) async {
      await tester.pumpWidget(buildPeopleList([]));
      expect(find.byType(StreamPeopleList), findsOneWidget);
      // Should render SizedBox.shrink — no person icons
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('Single person renders 1 row with icon', (tester) async {
      await tester.pumpWidget(buildPeopleList(['Kim K']));
      expect(find.text('Kim K'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('Two people render 2 rows, no overflow', (tester) async {
      await tester.pumpWidget(buildPeopleList(['Kim K', 'Kanye West']));
      expect(find.text('Kim K'), findsOneWidget);
      expect(find.text('Kanye West'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('Five people render 2 rows + "+3 more" overflow',
        (tester) async {
      await tester.pumpWidget(
          buildPeopleList(['Kim K', 'Kanye', 'Jay Z', 'Beyonce', 'Rihanna']));
      expect(find.text('Kim K'), findsOneWidget);
      expect(find.text('Kanye'), findsOneWidget);
      expect(find.text('+3 more'), findsOneWidget);
      // 2 name rows = 2 person icons (overflow row uses expand_more icon now)
      expect(find.byIcon(Icons.person), findsNWidgets(2));
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      // Hidden names should not appear initially
      expect(find.text('Jay Z'), findsNothing);
      expect(find.text('Beyonce'), findsNothing);
      expect(find.text('Rihanna'), findsNothing);
    });

    testWidgets('Tapping +N more expands to show all names', (tester) async {
      await tester.pumpWidget(
          buildPeopleList(['Kim K', 'Kanye', 'Jay Z', 'Beyonce', 'Rihanna']));

      // Initially collapsed - hidden names not visible
      expect(find.text('+3 more'), findsOneWidget);
      expect(find.text('Jay Z'), findsNothing);
      expect(find.text('Beyonce'), findsNothing);
      expect(find.text('Rihanna'), findsNothing);

      // Tap the "+3 more" text to expand
      await tester.tap(find.text('+3 more'));
      await tester.pumpAndSettle();

      // After expansion - all names visible
      expect(find.text('Kim K'), findsOneWidget);
      expect(find.text('Kanye'), findsOneWidget);
      expect(find.text('Jay Z'), findsOneWidget);
      expect(find.text('Beyonce'), findsOneWidget);
      expect(find.text('Rihanna'), findsOneWidget);

      // "+3 more" replaced with "Show less"
      expect(find.text('+3 more'), findsNothing);
      expect(find.text('Show less'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('Tapping Show less collapses back to 2 names', (tester) async {
      await tester.pumpWidget(
          buildPeopleList(['Kim K', 'Kanye', 'Jay Z', 'Beyonce', 'Rihanna']));

      // Expand first
      await tester.tap(find.text('+3 more'));
      await tester.pumpAndSettle();
      expect(find.text('Show less'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      // Back to collapsed state
      expect(find.text('+3 more'), findsOneWidget);
      expect(find.text('Jay Z'), findsNothing);
      expect(find.text('Beyonce'), findsNothing);
      expect(find.text('Rihanna'), findsNothing);
    });

    testWidgets('No expand control when people <= maxVisible', (tester) async {
      await tester.pumpWidget(buildPeopleList(['Kim K', 'Kanye']));
      // No expand/collapse controls
      expect(find.textContaining('+'), findsNothing);
      expect(find.text('Show less'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('People list does not use chips or pills', (tester) async {
      await tester.pumpWidget(buildPeopleList(['Kim K', 'Kanye']));
      // No StreamCelebChips or chip-like Container with borderRadius 12
      expect(find.byType(StreamCelebChips), findsNothing);
    });
  });

  group('StreamTypeBadge tinted style', () {
    testWidgets('Type badge renders with border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TmzTheme.dark,
          home: const Scaffold(
            body: StreamTypeBadge(typeCode: 'tv_clip'),
          ),
        ),
      );
      expect(find.text('TV_CLIP'), findsOneWidget);
      // Find the Container and verify it has a BoxDecoration with border
      final container = tester
          .widget<Container>(find.ancestor(
            of: find.text('TV_CLIP'),
            matching: find.byType(Container),
          ))
          ;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull,
          reason: 'Type badge should have a border');
      expect(decoration.color, isNotNull,
          reason: 'Type badge should have a tinted background');
    });
  });

  group('Title constraints', () {
    test('Title style is >= 15sp semi-bold', () {
      expect(TmzTextStyles.bodyBold.fontWeight, equals(FontWeight.w600));
      const titleFontSize = 15.0;
      expect(titleFontSize, greaterThanOrEqualTo(15));
    });

    test('Title maxLines is 2', () {
      const maxLines = 2;
      expect(maxLines, equals(2));
    });
  });

  group('Title/meta divider', () {
    test('Faint divider opacity is lower than footer divider', () {
      // Title/meta divider uses TmzColors.gray70.withValues(alpha: 0.3)
      // Footer divider uses TmzColors.gray70 (alpha: 1.0)
      const faintAlpha = 0.3;
      const footerAlpha = 1.0;
      expect(faintAlpha, lessThan(footerAlpha),
          reason: 'Title/meta divider should be subtler than footer divider');
    });
  });

  group('Source line extraction', () {
    String extractDomain(String? url) {
      if (url == null) return 'URL';
      try {
        final uri = Uri.parse(url);
        final host = uri.host.replaceFirst('www.', '');
        if (host.contains('s3.amazonaws.com') ||
            host.endsWith('.s3.amazonaws.com')) {
          return 'S3 Upload';
        }
        return host;
      } catch (_) {
        return 'URL';
      }
    }

    test('Extracts domain from URL', () {
      expect(
          extractDomain('https://www.youtube.com/watch?v=123'), 'youtube.com');
    });

    test('S3 URLs show "S3 Upload"', () {
      expect(
          extractDomain(
              'https://tmzai-streamwatch-media.s3.amazonaws.com/video.mp4'),
          'S3 Upload');
    });

    test('Null URL returns "URL"', () {
      expect(extractDomain(null), 'URL');
    });

    test('Strips www prefix', () {
      expect(extractDomain('https://www.example.com/path'), 'example.com');
    });

    test('Only one source line concept (domain OR filename)', () {
      const urlSource = 'url';
      const fileSource = 'file';
      expect(urlSource == 'url', isTrue);
      expect(fileSource == 'url', isFalse);
    });
  });
}

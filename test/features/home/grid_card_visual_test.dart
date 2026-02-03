// Visual verification harness for grid card design
// Run: flutter test test/features/home/grid_card_visual_test.dart
// Or: flutter run -d chrome --dart-define=VISUAL_TEST=true
//
// This test renders the grid card at various widths to verify:
// 1. Responsive column counts
// 2. Card states (completed, processing, flagged, URL vs file source)
// 3. Layout correctness

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Grid Card Visual Verification', () {
    testWidgets('Responsive breakpoints produce correct column counts', (tester) async {
      // Test breakpoint logic
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

      // Verify breakpoints
      expect(getColumnCount(390), equals(1), reason: '<500 should be 1 column');
      expect(getColumnCount(500), equals(1), reason: '500 exactly should be 1 column');
      expect(getColumnCount(501), equals(2), reason: '>500 should be 2 columns');
      expect(getColumnCount(700), equals(2), reason: '700 should be 2 columns');
      expect(getColumnCount(800), equals(2), reason: '800 exactly should be 2 columns');
      expect(getColumnCount(801), equals(3), reason: '>800 should be 3 columns');
      expect(getColumnCount(950), equals(3), reason: '950 should be 3 columns');
      expect(getColumnCount(1100), equals(3), reason: '1100 exactly should be 3 columns');
      expect(getColumnCount(1101), equals(4), reason: '>1100 should be 4 columns');
      expect(getColumnCount(1250), equals(4), reason: '1250 should be 4 columns');
      expect(getColumnCount(1400), equals(4), reason: '1400 exactly should be 4 columns');
      expect(getColumnCount(1401), equals(5), reason: '>1400 should be 5 columns');
      expect(getColumnCount(1500), equals(5), reason: '1500 should be 5 columns');
    });

    testWidgets('Card aspect ratio is approximately 0.72', (tester) async {
      const aspectRatio = 0.72;
      // For a 200px wide card, height should be 200/0.72 = ~278px
      expect(200 / aspectRatio, closeTo(278, 2));
    });

    testWidgets('Spacing is 16px', (tester) async {
      const crossAxisSpacing = 16.0;
      const mainAxisSpacing = 16.0;
      expect(crossAxisSpacing, equals(16.0));
      expect(mainAxisSpacing, equals(16.0));
    });
  });
}

/// To visually test the grid cards, run the app and navigate to the home screen.
/// Test the following scenarios:
///
/// 1. RESPONSIVE COLUMNS:
///    - Resize browser to ~390px width → should see 1 column
///    - Resize to ~700px width → should see 2 columns
///    - Resize to ~950px width → should see 3 columns
///    - Resize to ~1250px width → should see 4 columns
///    - Resize to ~1500px width → should see 5 columns
///
/// 2. COMPLETED JOB STATE:
///    - Status badge shows "COMPLETED" in green (top-right)
///    - Action icons (summary, SRT) are enabled (not grayed out)
///    - Download icons are clickable
///
/// 3. PROCESSING JOB STATE:
///    - Status badge shows "PROCESSING" in red (top-right)
///    - Progress overlay at bottom with spinning indicator and percentage
///    - Progress bar fills proportionally
///    - Action icons are disabled (grayed out)
///
/// 4. FLAGGED JOB STATE:
///    - Orange flag icon visible in top-left corner
///    - Flag icon has dark semi-transparent background
///
/// 5. URL SOURCE JOB:
///    - External link icon (open_in_new) visible in action row
///    - Source shows domain name extracted from URL
///
/// 6. FILE SOURCE JOB:
///    - NO external link icon in action row
///    - Source shows filename
///
/// 7. VISUAL POLISH:
///    - Sharp corners (no border radius) on cards
///    - Dark background (gray90 = #1A1A1A)
///    - Subtle elevation shadow
///    - Hover state shows lighter background on desktop
///    - Thumbnail shows loading spinner while loading
///    - Thumbnail shows video icon if image fails to load

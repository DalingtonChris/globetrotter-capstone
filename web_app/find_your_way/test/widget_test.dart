// Basic smoke test: the app boots to the auth screen when no session is
// stored, since Phase 1 gates the whole app behind login/register.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:find_your_way/main.dart';

void main() {
  testWidgets('Shows the auth screen on first launch', (WidgetTester tester) async {
    // Avoid runtime font fetches (and the splash screen's indeterminate
    // spinner) from starving pumpAndSettle of a quiescent frame.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RootProviders());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Find Your Way'), findsOneWidget);
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Sign up'), findsOneWidget);
  });
}

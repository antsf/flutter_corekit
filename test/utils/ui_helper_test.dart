import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_corekit/src/constants/default.dart';
import 'package:flutter_corekit/src/extensions/ui_ext.dart';
import 'package:flutter_corekit/src/utils/ui_helper.dart';

void main() {
  // UiHelper's spacing/inset methods use flutter_screenutil's `.w`/`.h`
  // extensions, which require ScreenUtil to be initialized against a real
  // device/screen size — wrap each test in a widget that calls
  // ScreenUtilInit first.
  Future<void> withScreenUtil(
    WidgetTester tester,
    void Function() body,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) {
          body();
          return const SizedBox.shrink();
        },
      ),
    );
  }

  group('UiHelper', () {
    testWidgets('defaultBoxShadow has the documented offset and blur',
        (tester) async {
      final shadow = UiHelper.defaultBoxShadow;
      expect(shadow.offset, const Offset(0, 6));
      expect(shadow.blurRadius, 6.0);
    });

    group('spacing', () {
      testWidgets('returns correct width when only width is provided',
          (tester) async {
        final spacingWidget =
            UiHelper.spacing(width: 2.5) as SizedBox;
        expect(spacingWidget.width, kPadding * 2.5);
        expect(spacingWidget.height, 0);
      });

      testWidgets('returns correct height when only height is provided',
          (tester) async {
        final spacingWidget = UiHelper.spacing(height: 1) as SizedBox;
        expect(spacingWidget.width, 0);
        expect(spacingWidget.height, kPadding * 1);
      });

      testWidgets('returns zero sized box when no arguments are provided',
          (tester) async {
        final spacingWidget = UiHelper.spacing() as SizedBox;
        expect(spacingWidget.width, 0);
        expect(spacingWidget.height, 0);
      });

      test('asserts on a negative width', () {
        expect(() => UiHelper.spacing(width: -1), throwsAssertionError);
      });

      test('asserts on a negative height', () {
        expect(() => UiHelper.spacing(height: -1), throwsAssertionError);
      });
    });

    testWidgets('inset scales left/right by .w and top/bottom by .h',
        (tester) async {
      await withScreenUtil(tester, () {
        final insets = UiHelper.inset(1, 2, 3, 4);
        expect(insets.left, (kPadding * 1).w);
        expect(insets.top, (kPadding * 2).h);
        expect(insets.right, (kPadding * 3).w);
        expect(insets.bottom, (kPadding * 4).h);
      });
    });

    testWidgets('insetOn returns EdgeInsets.only for provided sides only',
        (tester) async {
      await withScreenUtil(tester, () {
        final insets =
            UiHelper.insetOn(left: 1, bottom: 2) as EdgeInsets;
        expect(insets.left, (kPadding * 1).w);
        expect(insets.bottom, (kPadding * 2).h);
        expect(insets.right, 0.0);
        expect(insets.top, 0.0);
      });
    });

    testWidgets('insetSymmetric applies horizontal/vertical multipliers',
        (tester) async {
      await withScreenUtil(tester, () {
        final insets =
            UiHelper.insetSymmetric(horizontal: 1, vertical: 0.5)
                as EdgeInsets;
        expect(insets.horizontal, (kPadding * 1).w * 2);
        expect(insets.vertical, (kPadding * 0.5).h * 2);
      });
    });

    test('insetZero returns EdgeInsets.zero', () {
      expect(UiHelper.insetZero(), EdgeInsets.zero);
    });

    testWidgets('radiusOn returns BorderRadius.only for provided corners',
        (tester) async {
      await withScreenUtil(tester, () {
        final radius = UiHelper.radiusOn(topLeft: 5, bottomRight: 10);
        expect(radius.topLeft, 5.0.cornerRadius);
        expect(radius.bottomRight, 10.0.cornerRadius);
        expect(radius.topRight, Radius.zero);
        expect(radius.bottomLeft, Radius.zero);
      });
    });

    group('visualDensity', () {
      test('returns compact defaults when no values are provided', () {
        final density = UiHelper.visualDensity();
        expect(density.horizontal, -4.0);
        expect(density.vertical, -4.0);
      });

      test('returns specified VisualDensity when values are provided', () {
        final density = UiHelper.visualDensity(horizontal: 1.5, vertical: -2.0);
        expect(density.horizontal, 1.5);
        expect(density.vertical, -2.0);
      });
    });
  });
}

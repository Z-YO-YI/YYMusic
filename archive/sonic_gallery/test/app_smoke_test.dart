import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonic_gallery/src/app.dart';

void main() {
  testWidgets('renders the compact home experience', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SonicGalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('今天听什么'), findsOneWidget);
    expect(find.text('继续播放'), findsWidgets);
    expect(find.text('资料库'), findsWidgets);
  });

  testWidgets('renders the expanded Windows shell', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SonicGalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('声场画廊'), findsOneWidget);
    expect(find.text('我的资料库'), findsOneWidget);
    expect(find.text('跨设备继续播放'), findsOneWidget);
  });
}


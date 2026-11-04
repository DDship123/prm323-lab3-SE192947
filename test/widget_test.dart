import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/widgets/ktx_button.dart';
import 'package:prm393_lab03_se192947/widgets/ktx_empty_state.dart';
import 'package:prm393_lab03_se192947/widgets/ktx_error_state.dart';
import 'package:prm393_lab03_se192947/widgets/ktx_loading_state.dart';

void main() {
  group('Design System Widgets Smoke Tests', () {
    testWidgets('KtxButton hiển thị nhãn và kích hoạt sự kiện tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KtxButton(
              label: 'Xác nhận khiếu nại',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Xác nhận khiếu nại'), findsOneWidget);
      await tester.tap(find.byType(KtxButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('KtxLoadingState hiển thị thông báo tải dữ liệu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KtxLoadingState(message: 'Đang tải ảnh lên Cloud Storage...'),
          ),
        ),
      );

      expect(find.text('Đang tải ảnh lên Cloud Storage...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('KtxEmptyState hiển thị nội dung rỗng và nút hành động', (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KtxEmptyState(
              title: 'Chưa có khiếu nại',
              message: 'Danh sách khiếu nại của bạn đang trống.',
              actionLabel: 'Tạo khiếu nại mới',
              onAction: () => actionClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Chưa có khiếu nại'), findsOneWidget);
      expect(find.text('Danh sách khiếu nại của bạn đang trống.'), findsOneWidget);
      expect(find.text('Tạo khiếu nại mới'), findsOneWidget);

      await tester.tap(find.text('Tạo khiếu nại mới'));
      await tester.pump();
      expect(actionClicked, isTrue);
    });

    testWidgets('KtxErrorState hiển thị thông báo lỗi và nút Thử lại', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KtxErrorState(
              errorMessage: 'Không thể kết nối máy chủ',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Không thể kết nối máy chủ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });
}

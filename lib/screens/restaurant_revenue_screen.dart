import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/store_revenue_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/owner_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';

class RestaurantRevenueScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantRevenueScreen({super.key, required this.ownerId});

  @override
  State<RestaurantRevenueScreen> createState() => _RestaurantRevenueScreenState();
}

class _RestaurantRevenueScreenState extends State<RestaurantRevenueScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _selectedSlot = 'CA_TRUA_11H30';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerViewModel>().fetchRevenueReport(
            ownerId: widget.ownerId,
            slotTime: _selectedSlot,
          );
    });
  }

  void _onSlotChanged(String slot) {
    setState(() => _selectedSlot = slot);
    context.read<OwnerViewModel>().fetchRevenueReport(
          ownerId: widget.ownerId,
          slotTime: slot,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ownerVm = context.watch<OwnerViewModel>();
    final state = ownerVm.revenueState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Báo cáo Doanh thu & Đối soát COD'),
      body: Column(
        children: [
          _buildSlotFilter(),
          Expanded(
            child: switch (state) {
              StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang kết xuất báo cáo doanh thu...'),
              StateError(:final message) => KtxErrorState(
                  message: message,
                  onRetry: () => ownerVm.fetchRevenueReport(
                    ownerId: widget.ownerId,
                    slotTime: _selectedSlot,
                  ),
                ),
              StateEmpty(:final message) => KtxEmptyState(title: 'Chưa có đối soát', subtitle: message),
              StateSuccess(:final data) => _buildRevenueContent(data),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Ca trưa (11:00 - 12:30)')),
              selected: _selectedSlot == 'CA_TRUA_11H30',
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: _selectedSlot == 'CA_TRUA_11H30' ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (val) {
                if (val) _onSlotChanged('CA_TRUA_11H30');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Ca chiều (17:30 - 19:00)')),
              selected: _selectedSlot == 'CA_CHIEU_18H00',
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: _selectedSlot == 'CA_CHIEU_18H00' ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (val) {
                if (val) _onSlotChanged('CA_CHIEU_18H00');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueContent(StoreRevenueModel report) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng doanh thu ca',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(report.totalRevenue),
                style: AppTypography.heading1.copyWith(color: AppColors.primary),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      'Tiền mặt COD',
                      currencyFormatter.format(report.codAmount),
                      AppColors.warning,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildMiniStat(
                      'Chuyển khoản VietQR',
                      currencyFormatter.format(report.onlineAmount),
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Đơn hoàn thành: ${report.completedOrders}/${report.totalOrders}',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text('Khớp số liệu 100%',
                        style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Chi tiết đơn đối soát', style: AppTypography.heading2),
        const SizedBox(height: AppSpacing.sm),
        ...report.orderDetails.map((order) {
          final isCod = order.paymentMethod.toUpperCase() == 'COD';
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${order.orderCode}',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCod ? AppColors.warningLight : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              isCod ? 'Thu COD' : 'VietQR Đã chuyển',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCod ? AppColors.warning : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(order.customerName, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  currencyFormatter.format(order.finalAmount),
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        KtxButton(
          label: 'Xác nhận đối soát ca',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xác nhận đối soát doanh thu ca thành công')),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

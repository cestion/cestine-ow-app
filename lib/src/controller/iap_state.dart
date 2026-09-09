import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';

/// UI state for the IAP feature (design §6 / §12).
class IapState extends Equatable {
  /// Generic loading flag (mixin-managed).
  final bool isLoading;
  final ApiError? lastError;

  /// Server-provided product catalog.
  final List<IapProduct> products;
  final bool isProductsLoading;

  /// True while the startup / login reconcile is running.
  final bool isReconciling;

  /// True while a store payment sheet is in flight (blocks re-purchase).
  final bool isPurchasing;
  final String? purchasingProductId;

  /// True while an order is `RECHARGING`（到账处理中，禁止再次购买）。
  final bool isCrediting;

  /// Set after a successful delivery so the view can toast success.
  final String? lastFulfilledProductId;

  /// 应发放 USDC 原始值（字符串），成功弹窗展示用。
  final String? lastGrantedAmount;

  /// Set when the order reached a terminal failure state
  /// (`PAY_FAILED` / `RECHARGE_FAILED` / non-retryable verify error) so the
  /// view can show the failure dialog.
  final String? lastFailedReason;

  /// Set when a foreign-account pending order was settled to release the
  /// store block (cross-account, design §12.4).
  final String? lastSettledForeignUserId;

  const IapState({
    this.isLoading = false,
    this.lastError,
    this.products = const [],
    this.isProductsLoading = false,
    this.isReconciling = false,
    this.isPurchasing = false,
    this.purchasingProductId,
    this.isCrediting = false,
    this.lastFulfilledProductId,
    this.lastGrantedAmount,
    this.lastFailedReason,
    this.lastSettledForeignUserId,
  });

  String get errorMessage => lastError?.userMessage ?? '';

  bool get hasProducts => products.isNotEmpty;

  IapProduct? productById(String productId) {
    for (final product in products) {
      if (product.productId == productId) return product;
    }
    return null;
  }

  IapState copyWith({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
    List<IapProduct>? products,
    bool? isProductsLoading,
    bool? isReconciling,
    bool? isPurchasing,
    String? purchasingProductId,
    bool clearPurchasing = false,
    bool? isCrediting,
    String? lastFulfilledProductId,
    String? lastGrantedAmount,
    bool clearFulfilledSignal = false,
    String? lastFailedReason,
    bool clearFailedReason = false,
    String? lastSettledForeignUserId,
    bool clearSettledForeign = false,
  }) {
    return IapState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      products: products ?? this.products,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
      isReconciling: isReconciling ?? this.isReconciling,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchasingProductId: clearPurchasing
          ? null
          : (purchasingProductId ?? this.purchasingProductId),
      isCrediting: isCrediting ?? this.isCrediting,
      lastFulfilledProductId: clearFulfilledSignal
          ? null
          : (lastFulfilledProductId ?? this.lastFulfilledProductId),
      lastGrantedAmount: clearFulfilledSignal
          ? null
          : (lastGrantedAmount ?? this.lastGrantedAmount),
      lastFailedReason: clearFailedReason
          ? null
          : (lastFailedReason ?? this.lastFailedReason),
      lastSettledForeignUserId: clearSettledForeign
          ? null
          : (lastSettledForeignUserId ?? this.lastSettledForeignUserId),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastError,
    products,
    isProductsLoading,
    isReconciling,
    isPurchasing,
    purchasingProductId,
    isCrediting,
    lastFulfilledProductId,
    lastGrantedAmount,
    lastFailedReason,
    lastSettledForeignUserId,
  ];
}

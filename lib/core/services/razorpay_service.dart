import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../utils/app_logger.dart';

// Outcome of a Razorpay Checkout session
class RazorpayCheckoutResult {
  const RazorpayCheckoutResult._({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.message,
  });

  const RazorpayCheckoutResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) : this._(
          success: true,
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        );

  const RazorpayCheckoutResult.failure({
    int? code,
    String? message,
  }) : this._(success: false, errorCode: code, message: message);

  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? errorCode;
  final String? message;

  // True when the user simply closed/cancelled the checkout sheet.
  bool get isCancelled => !success && errorCode == Razorpay.PAYMENT_CANCELLED;

  // Everything needed by the verify API is present.
  bool get hasVerifiableData =>
      success &&
      (paymentId?.isNotEmpty ?? false) &&
      (orderId?.isNotEmpty ?? false) &&
      (signature?.isNotEmpty ?? false);
}

class RazorpayService {
  Razorpay? _razorpay;
  Completer<RazorpayCheckoutResult>? _completer;

  // Opens Razorpay Checkout
  Future<RazorpayCheckoutResult> openCheckout({
    required String keyId,
    required String orderId,

    // Amount
    required int amountInPaise,
    String currency = 'INR',
    String name = 'DigiNiwas',
    String description = 'Credit Top-Up',
    String? contact,
    String? email,
    Map<String, dynamic>? notes,
    int timeoutInSeconds = 300,
  }) {
    // Guard against a second checkout
    final pending = _completer;
    if (pending != null && !pending.isCompleted) {
      return Future.value(
        const RazorpayCheckoutResult.failure(
          message: 'A payment is already in progress.',
        ),
      );
    }

    final completer = Completer<RazorpayCheckoutResult>();
    _completer = completer;

    final razorpay = Razorpay();
    _razorpay = razorpay;
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    final options = <String, dynamic>{
      'key': keyId,
      'order_id': orderId,
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'timeout': timeoutInSeconds,
      'retry': {'enabled': true, 'max_count': 1},
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      'theme': {'color': '#165A54'},
    };

    try {
      razorpay.open(options);
    } catch (e, st) {
      AppLogger.e('Razorpay open failed', e, st);
      _finish(
        const RazorpayCheckoutResult.failure(
          message: 'Could not open the payment screen.',
        ),
      );
    }

    return completer.future;
  }

  void _onSuccess(PaymentSuccessResponse r) {
    _finish(
      RazorpayCheckoutResult.success(
        paymentId: r.paymentId ?? '',
        orderId: r.orderId ?? '',
        signature: r.signature ?? '',
      ),
    );
  }

  void _onError(PaymentFailureResponse r) {
    AppLogger.w('Razorpay payment failed: ${r.code} ${r.message}');
    _finish(
      RazorpayCheckoutResult.failure(
        code: r.code,
        message: _readableError(r.code, r.message),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    _finish(
      RazorpayCheckoutResult.failure(
        message: 'Payment was moved to ${r.walletName ?? 'an external wallet'}. '
            'Credits will appear once the payment is confirmed.',
      ),
    );
  }

  void _finish(RazorpayCheckoutResult result) {
    final completer = _completer;
    _completer = null;
    dispose();
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  String _readableError(int? code, String? raw) {
    if (code == Razorpay.PAYMENT_CANCELLED) return 'Payment cancelled.';
    if (code == Razorpay.NETWORK_ERROR) {
      return 'Network problem during payment. Please try again.';
    }
    if (raw == null || raw.isEmpty) return 'Payment failed. Please try again.';
    final match = RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {
    }
    _razorpay = null;
  }
}

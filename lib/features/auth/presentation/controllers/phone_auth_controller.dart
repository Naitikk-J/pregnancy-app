import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

enum PhoneStep { enterNumber, enterCode }

/// State of the phone sign-in flow.
@immutable
class PhoneAuthState {
  const PhoneAuthState({
    this.step = PhoneStep.enterNumber,
    this.phoneNumber = '',
    this.verificationId,
    this.resendToken,
    this.isBusy = false,
    this.errorMessage,
    this.autoVerified = false,
  });

  final PhoneStep step;
  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final bool isBusy;
  final String? errorMessage;
  final bool autoVerified;

  PhoneAuthState copyWith({
    PhoneStep? step,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    bool? autoVerified,
  }) =>
      PhoneAuthState(
        step: step ?? this.step,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        verificationId: verificationId ?? this.verificationId,
        resendToken: resendToken ?? this.resendToken,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        autoVerified: autoVerified ?? this.autoVerified,
      );
}

class PhoneAuthController extends Notifier<PhoneAuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  PhoneAuthState build() => const PhoneAuthState();

  /// Send an OTP to [phoneNumber] (E.164, e.g. +919876543210).
  Future<void> sendCode(String phoneNumber, {bool resend = false}) async {
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      phoneNumber: phoneNumber,
    );
    try {
      final verification = await _repo.startPhoneVerification(
        phoneNumber: phoneNumber,
        resendToken: resend ? state.resendToken : null,
        onAutoVerified: () => state = state.copyWith(autoVerified: true),
      );
      state = state.copyWith(
        isBusy: false,
        step: PhoneStep.enterCode,
        verificationId: verification.verificationId,
        resendToken: verification.resendToken,
      );
    } catch (e, s) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: ErrorMapper.map(e, s).message,
      );
    }
  }

  /// Confirm the [smsCode]. Returns true on success.
  Future<bool> confirmCode(String smsCode) async {
    final id = state.verificationId;
    if (id == null) return false;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.confirmPhoneCode(verificationId: id, smsCode: smsCode);
      state = state.copyWith(isBusy: false);
      return true;
    } catch (e, s) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: ErrorMapper.map(e, s).message,
      );
      return false;
    }
  }

  void reset() => state = const PhoneAuthState();
}

final phoneAuthControllerProvider =
    NotifierProvider<PhoneAuthController, PhoneAuthState>(
        PhoneAuthController.new);

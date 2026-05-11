/// AgriSutra NE — Screen 3: Login Screen
/// =========================================
/// Phone number + OTP login. Phase 1 uses a MOCK flow:
///   - Any valid 10-digit Indian phone number is accepted
///   - Any 6-digit code passes verification
///   - Phone is saved to SharedPreferences
///   - Routes to /profile_setup (new user) or /wizard (returning user)
///
/// Phase 2: Swap _sendOtp() and _verifyOtp() bodies for real
///   Firebase Auth calls. The UI and routing logic stay unchanged.
///
/// UX priorities (manual Part 10, Screen 3):
///   - Large 18sp text in all fields — readable by 45+ year old farmers
///   - Numeric keyboard auto-shown (keyboardType: TextInputType.phone)
///   - OTP boxes auto-advance on each digit typed
///   - 30-second countdown before "Resend OTP" becomes tappable
///   - Clear error states shown inline, never as dialogs (dialogs confuse
///     low-literacy users who may not know where to tap to dismiss them)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── State ────────────────────────────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  /// True after "Send OTP" is tapped and phone is validated
  bool _otpSent    = false;
  bool _isLoading  = false;

  /// The 6 individual OTP digit controllers and focus nodes
  final List<TextEditingController> _otpCtrls  = List.generate(6, (_) => TextEditingController());
  final List<FocusNode>             _otpFocuses = List.generate(6, (_) => FocusNode());

  /// Countdown timer for "Resend OTP"
  Timer?  _countdownTimer;
  int     _secondsLeft = 30;
  bool    get _canResend => _secondsLeft == 0;

  /// Error text shown under phone / otp field
  String? _phoneError;
  String? _otpError;

  // ── Entry animation ──────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    for (final c in _otpCtrls)   c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _countdownTimer?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIC
  // ══════════════════════════════════════════════════════════════════════════

  String get _fullOtp => _otpCtrls.map((c) => c.text).join();

  bool _validatePhone() {
    final digits = _phoneCtrl.text.trim().replaceAll(' ', '');
    if (digits.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      return false;
    }
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      setState(() => _phoneError = 'Enter a valid 10-digit phone number');
      return false;
    }
    setState(() => _phoneError = null);
    return true;
  }

  Future<void> _sendOtp() async {
    if (!_validatePhone()) return;

    setState(() => _isLoading = true);

    // ── DEMO MODE: simulate 1.2s network call ────────────────────────────
    // Phase 2: replace with FirebaseAuth.instance.verifyPhoneNumber(...)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent   = true;
      _secondsLeft = 30;
    });

    _startCountdown();

    // Auto-focus first OTP box
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _otpFocuses[0].requestFocus();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    // Clear OTP boxes
    for (final c in _otpCtrls) c.clear();
    setState(() { _otpError = null; _secondsLeft = 30; });
    _startCountdown();
    _otpFocuses[0].requestFocus();
    // Phase 2: re-trigger Firebase verifyPhoneNumber here
  }

  /// Called when user taps "Verify OTP" or OTP auto-completes.
  /// DEMO: any 6-digit code passes.
  Future<void> _verifyOtp() async {
    final code = _fullOtp;
    if (code.length < 6) {
      setState(() => _otpError = 'Enter all 6 digits');
      return;
    }

    setState(() { _isLoading = true; _otpError = null; });
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // ── DEMO: any 6 digits pass ──────────────────────────────────────────
    // Phase 2: await FirebaseAuth.instance.signInWithCredential(credential)
    if (code.length == 6) {
      await _savePhoneAndNavigate();
    } else {
      setState(() {
        _isLoading = false;
        _otpError  = 'Invalid OTP. Please try again.';
      });
    }
  }

  Future<void> _savePhoneAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = '+91${_phoneCtrl.text.trim()}';
    await prefs.setString('farmer_phone', phone);

    if (!mounted) return;

    // Route based on whether profile setup is already done
    final hasProfile = prefs.getString('farmer_name') != null;
    Navigator.pushReplacementNamed(context, hasProfile ? '/wizard' : '/profile_setup');
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kGreenAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: kPaddingScreen.copyWith(top: 0),
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  kGapM,

                  // ── Phone icon ─────────────────────────────────────────
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreenPrimary.withOpacity(0.15),
                      border: Border.all(color: kGreenPrimary.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.phone_android_rounded, color: kGreenAccent, size: 36),
                  ),

                  kGapL,

                  // ── Title ─────────────────────────────────────────────
                  Text('Login with Phone', style: kStyleHeadingL, textAlign: TextAlign.center),

                  kGapS,

                  Text(
                    "We'll send you a verification code",
                    style: kStyleBodyM,
                    textAlign: TextAlign.center,
                  ),

                  kGapXL,

                  // ── Main card ─────────────────────────────────────────
                  Container(
                    padding: kPaddingCard,
                    decoration: kCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone field (always visible)
                        _buildPhoneField(),

                        // OTP section (slides in after Send OTP)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          child: _otpSent ? _buildOtpSection() : const SizedBox.shrink(),
                        ),

                        kGapL,

                        // Action button
                        _buildActionButton(),
                      ],
                    ),
                  ),

                  kGapL,

                  // ── Fine print ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: kTextSecondary),
                      const SizedBox(width: 5),
                      Text(
                        'We never share your phone number',
                        style: kStyleLabel,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PHONE FIELD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number', style: kStyleBodyM.copyWith(color: kTextPrimary)),
        kGapS,
        TextFormField(
          controller:    _phoneCtrl,
          focusNode:     _phoneFocus,
          enabled:       !_otpSent,     // lock after OTP is sent
          keyboardType:  TextInputType.phone,
          textInputAction: TextInputAction.done,
          maxLength:     10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: kStyleBodyL.copyWith(fontSize: 18, color: kTextHighlight),
          onChanged: (_) { if (_phoneError != null) setState(() => _phoneError = null); },
          onFieldSubmitted: (_) { if (!_otpSent) _sendOtp(); },
          decoration: InputDecoration(
            counterText: '',          // hide the "10/10" character counter
            hintText:    '98XXXXXXXX',
            prefixText:  '+91  ',
            prefixStyle: kStyleBodyL.copyWith(
              color: kGreenAccent,
              fontWeight: FontWeight.w600,
            ),
            errorText: _phoneError,
            errorStyle: kStyleLabel.copyWith(color: kError),
            suffixIcon: _otpSent
                ? const Icon(Icons.check_circle_rounded, color: kSuccess, size: 22)
                : null,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  OTP SECTION  (6 digit boxes + countdown + error)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        kGapL,

        // Divider with label
        Row(
          children: [
            const Expanded(child: Divider(color: kBgCardBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Enter OTP', style: kStyleBodyM),
            ),
            const Expanded(child: Divider(color: kBgCardBorder)),
          ],
        ),

        kGapM,

        // Sent-to hint
        Text(
          'Code sent to +91 ${_phoneCtrl.text.trim()}',
          style: kStyleBodyM.copyWith(color: kGreenAccent),
        ),

        kGapM,

        // 6 OTP digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _OtpBox(
            controller: _otpCtrls[i],
            focusNode:  _otpFocuses[i],
            onChanged: (val) {
              if (_otpError != null) setState(() => _otpError = null);
              if (val.length == 1 && i < 5) {
                _otpFocuses[i + 1].requestFocus();
              }
              if (val.isEmpty && i > 0) {
                _otpFocuses[i - 1].requestFocus();
              }
              // Auto-verify when all 6 digits are filled
              if (_fullOtp.length == 6) {
                Future.delayed(const Duration(milliseconds: 120), _verifyOtp);
              }
            },
          )),
        ),

        // OTP error
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _otpError != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_otpError!, style: kStyleLabel.copyWith(color: kError)),
                )
              : const SizedBox.shrink(),
        ),

        kGapM,

        // Countdown / Resend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Didn\'t get the code?  ', style: kStyleBodyM),
            _canResend
                ? GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend OTP',
                      style: kStyleBodyM.copyWith(
                        color: kGreenAccent,
                        decoration: TextDecoration.underline,
                        decorationColor: kGreenAccent,
                      ),
                    ),
                  )
                : Text(
                    'Resend in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: kStyleBodyM.copyWith(color: kTextSecondary),
                  ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION BUTTON  (toggles between "Send OTP" and "Verify OTP")
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? kGreenPrimary.withOpacity(0.5) : kGreenPrimary,
          foregroundColor: kTextHighlight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          textStyle: kStyleHeadingM,
          elevation: _isLoading ? 0 : 3,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  color: kTextHighlight,
                  strokeWidth: 2.5,
                ),
              )
            : Text(_otpSent ? 'Verify OTP ✓' : 'Send OTP →'),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  _OtpBox  — single digit input box
//  48×56px, rounded, auto-advance, backspace goes back one box.
// ════════════════════════════════════════════════════════════════════════════

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller:  controller,
        focusNode:   focusNode,
        maxLength:   1,
        textAlign:   TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: kStyleValueL.copyWith(fontSize: 22),
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: focusNode.hasFocus
              ? kGreenPrimary.withOpacity(0.18)
              : kBgDark,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusSmall),
            borderSide: const BorderSide(color: kBgCardBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusSmall),
            borderSide: const BorderSide(color: kGreenAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

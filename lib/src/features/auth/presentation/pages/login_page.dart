import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/home/dashboard_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const String _wrLogoAsset = 'assets/wr_logo_panel.png';
  static const List<String> _carouselAssets = <String>[
    'assets/dashboard_slides/carousel1.webp',
    'assets/dashboard_slides/carousel2.webp',
    'assets/dashboard_slides/carousel3.webp',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapRemembered());
  }

  Future<void> _bootstrapRemembered() async {
    final AuthLocalSnapshot snap =
        await ref.read(authLocalDataSourceProvider).readSnapshot();
    if (!mounted) {
      return;
    }
    if (snap.userId != null && snap.userId!.isNotEmpty) {
      _userIdController.text = snap.userId!;
    }
    setState(() => _rememberMe = snap.rememberMe);
    final Failure? failure =
        await ref.read(authControllerProvider.notifier).tryAutoLoginIfRemembered();
    if (!mounted) {
      return;
    }
    if (failure == null &&
        ref.read(authControllerProvider).valueOrNull != null) {
      context.goNamed(DashboardPage.routeName);
      return;
    }
    if (failure != null) {
      // Auto-login failed — stay on login without showing a dialog.
      return;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    final Failure? failure =
        await ref.read(authControllerProvider.notifier).login(
              userId: _userIdController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (failure != null) {
      await GlobalDialog.error(
        failure.message,
        title: 'Login Failed',
      );
      return;
    }
    context.goNamed(DashboardPage.routeName);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = AppTheme.brandPrimary;
    const Color onPrimary = Colors.white;
    final double topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.brandPrimary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.scaffoldLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldLight,
        body: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 14),
              decoration: const BoxDecoration(
                color: primary,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                AppConstants.welcomeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: <Widget>[
                      // 1. Logo on top
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          _wrLogoAsset,
                          width: 76,
                          height: 76,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppConstants.orgName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A2414),
                            ),
                      ),
                      const SizedBox(height: 8),
                      // 2. Sliding images
                      const _CarouselSection(
                        assets: _carouselAssets,
                      ),
                      const SizedBox(height: 16),
                      // 3. Input box and form below
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'SIGN IN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: onPrimary,
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Sign in to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: onPrimary.withValues(alpha: 0.88),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _LoginField(
                                label: 'User Name',
                                hint: 'Enter your user ID',
                                controller: _userIdController,
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.username,
                                ],
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter user name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              _LoginField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[
                                  AutofillHints.password,
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF8A5A32),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              _RememberMeCheckbox(
                                value: _rememberMe,
                                onChanged: (bool value) {
                                  setState(() => _rememberMe = value);
                                },
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: primary,
                                    disabledBackgroundColor:
                                        Colors.white.withValues(alpha: 0.7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _submitting
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: primary,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    context.pushNamed(
                                      ForgotPasswordPage.routeName,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        onPrimary.withValues(alpha: 0.92),
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RememberMeCheckbox extends StatelessWidget {
  const _RememberMeCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color primary = AppTheme.brandPrimary;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      value ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  width: 1.6,
                ),
                boxShadow: value
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: primary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'Remember me',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselSection extends StatefulWidget {
  const _CarouselSection({required this.assets});

  final List<String> assets;

  @override
  State<_CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<_CarouselSection> {
  static const int _loopMultiplier = 1000;
  static const Duration _autoSlideInterval = Duration(seconds: 3);
  static const Duration _slideDuration = Duration(milliseconds: 500);

  late final PageController _controller;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  int get _itemCount => widget.assets.length * _loopMultiplier;

  @override
  void initState() {
    super.initState();
    final int startPage = widget.assets.length * (_loopMultiplier ~/ 2);
    _controller = PageController(initialPage: startPage);
    _currentIndex = startPage % widget.assets.length;
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      if (!mounted || !_controller.hasClients || widget.assets.isEmpty) {
        return;
      }
      _controller.nextPage(
        duration: _slideDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToPage(int delta) {
    if (!_controller.hasClients || widget.assets.isEmpty) {
      return;
    }
    _autoSlideTimer?.cancel();
    _controller.animateToPage(
      (_controller.page?.round() ?? _controller.initialPage) + delta,
      duration: _slideDuration,
      curve: Curves.easeInOut,
    );
    _startAutoSlide();
  }

  void _onPageChanged(int page) {
    setState(() => _currentIndex = page % widget.assets.length);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _itemCount,
              itemBuilder: (BuildContext context, int i) {
                return Image.asset(
                  widget.assets[i % widget.assets.length],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                    alignment: Alignment.center,
                    child: const Icon(Icons.train, size: 64),
                  ),
                );
              },
            ),
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CarouselArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _goToPage(-1),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CarouselArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _goToPage(1),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(widget.assets.length, (int i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _currentIndex ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
    this.validator,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color fieldFill = Color(0xFFFFFDFB);
    const Color fieldBorder = Color(0xFFE8D4C4);
    const Color focusBorder = Color(0xFFFFFFFF);
    const Color textColor = Color(0xFF3A2414);
    const Color hintColor = Color(0xFF9A7A62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            autofillHints: widget.autofillHints,
            style: const TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppTheme.brandPrimary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: hintColor,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: fieldFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _focused
                    ? AppTheme.brandPrimary
                    : const Color(0xFF8A5A32),
                size: 22,
              ),
              suffixIcon: widget.suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: focusBorder,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB4B4)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFFB4B4),
                  width: 1.6,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFFE8E8),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

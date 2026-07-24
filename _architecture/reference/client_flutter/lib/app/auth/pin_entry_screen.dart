import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:client_flutter/app/auth/auth_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Spring-Shake physics for incorrect inputs
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Highly responsive dampening wave sequence representing physical spring
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 20.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 20.0, end: -20.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -20.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Widget _buildKey(String label, AuthState state) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(authProvider.notifier).enterDigit(label);
        },
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 26.0,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 2. Setup reactive listeners to route navigated shell or fire shake
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error) {
        _shakeController.forward(from: 0.0);
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      }
    });

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glowing lights behind card
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0.0),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30.0,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'SYSTEM ACCESS',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.0,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          const Text(
                            'Enter PIN to initialize terminal',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.0,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                        // Dynamic glowing dots representing status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final charPresent =
                                index < authState.enteredPin.length;
                            final isError = authState.status == AuthStatus.error;
                            final isSuccess =
                                authState.status == AuthStatus.authenticated;

                            Color dotColor = Colors.white24;
                            if (isSuccess) {
                              dotColor = Colors.greenAccent;
                            } else if (isError) {
                              dotColor = Colors.redAccent;
                            } else if (charPresent) {
                              dotColor = primaryColor;
                            }

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 12.0),
                              width: charPresent ? 14.0 : 12.0,
                              height: charPresent ? 14.0 : 12.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor,
                                border: Border.all(
                                  color: charPresent
                                      ? dotColor.withValues(alpha: 0.5)
                                      : Colors.white12,
                                  width: 2.0,
                                ),
                                boxShadow: charPresent
                                    ? [
                                        BoxShadow(
                                          color: dotColor.withValues(alpha: 0.6),
                                          blurRadius: 8.0,
                                          spreadRadius: 1.0,
                                        ),
                                      ]
                                    : [],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16.0),
                        // 3x4 Numpad Keypad Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 1.25,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, idx) {
                            if (idx < 9) {
                              return _buildKey('${idx + 1}', authState);
                            }
                            if (idx == 9) {
                              // Safe empty gap preserving layout balance
                              return const SizedBox();
                            }
                            if (idx == 10) {
                              return _buildKey('0', authState);
                            }
                            // Underflow delete operation button
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(authProvider.notifier)
                                      .deleteDigit();
                                },
                                customBorder: const CircleBorder(),
                                splashColor:
                                    Colors.redAccent.withValues(alpha: 0.15),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.01),
                                  ),
                                  child: const Icon(
                                    Icons.backspace_outlined,
                                    size: 22,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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

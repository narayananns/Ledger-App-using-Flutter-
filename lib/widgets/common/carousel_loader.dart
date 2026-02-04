import 'package:flutter/material.dart';
import 'dart:async';

class CarouselLoader extends StatefulWidget {
  final String? message;

  const CarouselLoader({super.key, this.message});

  @override
  State<CarouselLoader> createState() => _CarouselLoaderState();
}

class _CarouselLoaderState extends State<CarouselLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tips = [
    {
      'icon': Icons.savings_outlined,
      'title': 'Track Every Penny',
      'subtitle': 'Small savings add up to big results',
      'color': Colors.green,
    },
    {
      'icon': Icons.trending_up,
      'title': 'Monitor Your Growth',
      'subtitle': 'Watch your wealth increase over time',
      'color': Colors.blue,
    },
    {
      'icon': Icons.account_balance_wallet,
      'title': 'Budget Wisely',
      'subtitle': 'Plan your expenses, secure your future',
      'color': Colors.orange,
    },
    {
      'icon': Icons.lightbulb_outline,
      'title': 'Smart Spending',
      'subtitle': 'Make every transaction count',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pageController = PageController();

    // Auto-scroll carousel
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _tips.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A73E8).withValues(alpha: 0.05),
            Colors.white,
            const Color(0xFF1A73E8).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            _buildAnimatedLogo(),

            const SizedBox(height: 40),

            // Carousel Tips
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tips.length,
                itemBuilder: (context, index) {
                  return _buildTipCard(_tips[index]);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Page Indicator
            _buildPageIndicator(),

            const SizedBox(height: 32),

            // Loading Message
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * (0.5 - (_controller.value - 0.5).abs())),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A73E8),
                  const Color(0xFF1A73E8).withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating outer ring
                Transform.rotate(
                  angle: _controller.value * 2 * 3.14159,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Icon
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (tip['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tip['icon'] as IconData,
                size: 32,
                color: tip['color'] as Color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tip['title'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tip['subtitle'] as String,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tips.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF1A73E8)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

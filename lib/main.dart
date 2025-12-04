import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const ParticleDanceApp());
}

class ParticleDanceApp extends StatelessWidget {
  const ParticleDanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Dance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0a0a0f),
      ),
      home: const ParticleCanvas(),
    );
  }
}

class ParticleCanvas extends StatefulWidget {
  const ParticleCanvas({super.key});

  @override
  State<ParticleCanvas> createState() => _ParticleCanvasState();
}

class _ParticleCanvasState extends State<ParticleCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  Offset _mousePosition = Offset.zero;
  bool _isMouseInside = false;
  bool _isDispersing = true; // true = 拡散, false = 収束
  final int _particleCount = 800;
  Size _canvasSize = Size.zero;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
    _controller.repeat();
  }

  void _initializeParticles() {
    _particles = List.generate(_particleCount, (index) {
      return Particle(
        position: Offset(
          _random.nextDouble() * _canvasSize.width,
          _random.nextDouble() * _canvasSize.height,
        ),
        homePosition: Offset(
          _canvasSize.width / 2 + (_random.nextDouble() - 0.5) * 300,
          _canvasSize.height / 2 + (_random.nextDouble() - 0.5) * 300,
        ),
        velocity: Offset.zero,
        color: _getRandomColor(index),
        size: _random.nextDouble() * 3 + 1,
        depth: _random.nextDouble(), // 0-1 for 3D depth effect
      );
    });
  }

  Color _getRandomColor(int index) {
    final colors = [
      const Color(0xFF00f5ff), // Cyan
      const Color(0xFFff00ff), // Magenta
      const Color(0xFF00ff88), // Green
      const Color(0xFFffaa00), // Orange
      const Color(0xFF8855ff), // Purple
      const Color(0xFFff5588), // Pink
    ];
    return colors[index % colors.length];
  }

  void _updateParticles() {
    if (_particles.isEmpty || _canvasSize == Size.zero) return;

    setState(() {
      for (var particle in _particles) {
        if (_isMouseInside) {
          final dx = particle.position.dx - _mousePosition.dx;
          final dy = particle.position.dy - _mousePosition.dy;
          final distance = math.sqrt(dx * dx + dy * dy);
          final maxDistance = 250.0 * (1 + particle.depth * 0.5);

          if (distance < maxDistance) {
            final force = (1 - distance / maxDistance) * 12;
            final angle = math.atan2(dy, dx);

            if (_isDispersing) {
              // 拡散モード：マウスから離れる
              particle.velocity = Offset(
                particle.velocity.dx + math.cos(angle) * force * (1 + particle.depth),
                particle.velocity.dy + math.sin(angle) * force * (1 + particle.depth),
              );
            } else {
              // 収束モード：マウスに向かう
              particle.velocity = Offset(
                particle.velocity.dx - math.cos(angle) * force * 0.8,
                particle.velocity.dy - math.sin(angle) * force * 0.8,
              );
            }
          }
        }

        // ホームポジションに戻る力
        final homeForce = 0.02;
        particle.velocity = Offset(
          particle.velocity.dx + (particle.homePosition.dx - particle.position.dx) * homeForce,
          particle.velocity.dy + (particle.homePosition.dy - particle.position.dy) * homeForce,
        );

        // 摩擦
        particle.velocity = particle.velocity * 0.92;

        // 位置更新
        particle.position = Offset(
          particle.position.dx + particle.velocity.dx,
          particle.position.dy + particle.velocity.dy,
        );

        // 3D回転効果
        particle.rotationAngle += particle.depth * 0.05;

        // 画面境界処理
        if (particle.position.dx < 0) particle.position = Offset(0, particle.position.dy);
        if (particle.position.dx > _canvasSize.width) {
          particle.position = Offset(_canvasSize.width, particle.position.dy);
        }
        if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, 0);
        if (particle.position.dy > _canvasSize.height) {
          particle.position = Offset(particle.position.dx, _canvasSize.height);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景グラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF0a0a0f),
                ],
              ),
            ),
          ),
          // パーティクルキャンバス
          LayoutBuilder(
            builder: (context, constraints) {
              final newSize = Size(constraints.maxWidth, constraints.maxHeight);
              if (_canvasSize != newSize) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _canvasSize = newSize;
                    _initializeParticles();
                  });
                });
              }
              return MouseRegion(
                onEnter: (_) => setState(() => _isMouseInside = true),
                onExit: (_) => setState(() => _isMouseInside = false),
                onHover: (event) {
                  setState(() => _mousePosition = event.localPosition);
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isDispersing = !_isDispersing);
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: ParticlePainter(
                      particles: _particles,
                      mousePosition: _mousePosition,
                      isMouseInside: _isMouseInside,
                      isDispersing: _isDispersing,
                    ),
                  ),
                ),
              );
            },
          ),
          // UI オーバーレイ
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00f5ff), Color(0xFFff00ff)],
                    ).createShader(bounds),
                    child: const Text(
                      'PARTICLE DANCE',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      _isDispersing ? '🌀 拡散モード' : '✨ 収束モード',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isDispersing 
                          ? const Color(0xFF00f5ff) 
                          : const Color(0xFFff00ff),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 操作説明
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mouse, color: Colors.white54, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'マウスを動かして粒子を操作  •  クリックでモード切替',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset homePosition;
  Offset velocity;
  Color color;
  double size;
  double depth;
  double rotationAngle;

  Particle({
    required this.position,
    required this.homePosition,
    required this.velocity,
    required this.color,
    required this.size,
    required this.depth,
    this.rotationAngle = 0,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset mousePosition;
  final bool isMouseInside;
  final bool isDispersing;

  ParticlePainter({
    required this.particles,
    required this.mousePosition,
    required this.isMouseInside,
    required this.isDispersing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 深度でソート（奥から描画）
    final sortedParticles = List<Particle>.from(particles)
      ..sort((a, b) => a.depth.compareTo(b.depth));

    for (var particle in sortedParticles) {
      // 3D効果：深度によってサイズと透明度を変更
      final depthScale = 0.5 + particle.depth * 0.5;
      final particleSize = particle.size * depthScale * 2;
      final alpha = (0.3 + particle.depth * 0.7).clamp(0.0, 1.0);

      // マウスとの距離で発光効果
      double glowIntensity = 0.0;
      if (isMouseInside) {
        final dx = particle.position.dx - mousePosition.dx;
        final dy = particle.position.dy - mousePosition.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        glowIntensity = (1 - (distance / 300).clamp(0.0, 1.0)) * 0.8;
      }

      // グロー効果（外側の光）
      if (glowIntensity > 0) {
        final glowPaint = Paint()
          ..color = particle.color.withValues(alpha: glowIntensity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(
          particle.position,
          particleSize * 3,
          glowPaint,
        );
      }

      // パーティクル本体（グラデーション効果）
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            particle.color.withValues(alpha: alpha),
            particle.color.withValues(alpha: alpha * 0.3),
          ],
        ).createShader(
          Rect.fromCircle(center: particle.position, radius: particleSize),
        );

      canvas.drawCircle(particle.position, particleSize, paint);

      // コア（中心の明るい点）
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.8);
      canvas.drawCircle(particle.position, particleSize * 0.3, corePaint);
    }

    // マウスカーソル周りのエフェクト
    if (isMouseInside) {
      // 外側のリング
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (isDispersing 
          ? const Color(0xFF00f5ff) 
          : const Color(0xFFff00ff)).withValues(alpha: 0.3);
      canvas.drawCircle(mousePosition, 100, ringPaint);

      // 内側のグロー
      final cursorGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            (isDispersing 
              ? const Color(0xFF00f5ff) 
              : const Color(0xFFff00ff)).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: mousePosition, radius: 150),
        );
      canvas.drawCircle(mousePosition, 150, cursorGlow);
    }

    // 接続線（近い粒子同士を線で結ぶ）
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final dx = p1.position.dx - p2.position.dx;
        final dy = p1.position.dy - p2.position.dy;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < 80) {
          final opacity = (1 - distance / 80) * 0.2 * ((p1.depth + p2.depth) / 2);
          linePaint.color = p1.color.withValues(alpha: opacity);
          canvas.drawLine(p1.position, p2.position, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

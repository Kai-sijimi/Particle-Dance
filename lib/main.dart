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
  bool _isDispersing = true;
  static const int _particleCount = 300; // 800→300に削減
  Size _canvasSize = Size.zero;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 60fps
    )..addListener(_updateParticles);
    _controller.repeat();
  }

  void _initializeParticles() {
    final colors = [
      const Color(0xFF00f5ff),
      const Color(0xFFff00ff),
      const Color(0xFF00ff88),
      const Color(0xFFffaa00),
      const Color(0xFF8855ff),
      const Color(0xFFff5588),
    ];

    _particles = List.generate(_particleCount, (index) {
      final depth = _random.nextDouble();
      return Particle(
        x: _random.nextDouble() * _canvasSize.width,
        y: _random.nextDouble() * _canvasSize.height,
        homeX: _canvasSize.width / 2 + (_random.nextDouble() - 0.5) * 300,
        homeY: _canvasSize.height / 2 + (_random.nextDouble() - 0.5) * 300,
        vx: 0,
        vy: 0,
        color: colors[index % colors.length],
        size: (_random.nextDouble() * 2 + 1) * (0.5 + depth * 0.5),
        depth: depth,
      );
    });
    
    // 深度でソート（一度だけ）
    _particles.sort((a, b) => a.depth.compareTo(b.depth));
  }

  void _updateParticles() {
    if (_particles.isEmpty || _canvasSize == Size.zero) return;

    for (var p in _particles) {
      if (_isMouseInside) {
        final dx = p.x - _mousePosition.dx;
        final dy = p.y - _mousePosition.dy;
        final distSq = dx * dx + dy * dy; // sqrt を避ける
        final maxDistSq = 200.0 * 200.0;

        if (distSq < maxDistSq && distSq > 0) {
          final dist = math.sqrt(distSq);
          final force = (1 - dist / 200) * 8;
          final nx = dx / dist;
          final ny = dy / dist;

          if (_isDispersing) {
            p.vx += nx * force;
            p.vy += ny * force;
          } else {
            p.vx -= nx * force * 0.6;
            p.vy -= ny * force * 0.6;
          }
        }
      }

      // ホームに戻る力
      p.vx += (p.homeX - p.x) * 0.02;
      p.vy += (p.homeY - p.y) * 0.02;

      // 摩擦
      p.vx *= 0.92;
      p.vy *= 0.92;

      // 位置更新
      p.x += p.vx;
      p.y += p.vy;

      // 境界処理
      p.x = p.x.clamp(0, _canvasSize.width);
      p.y = p.y.clamp(0, _canvasSize.height);
    }

    setState(() {});
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
          // 背景（静的なのでconstに）
          const _Background(),
          
          // パーティクルキャンバス
          LayoutBuilder(
            builder: (context, constraints) {
              final newSize = Size(constraints.maxWidth, constraints.maxHeight);
              if (_canvasSize != newSize) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _canvasSize = newSize;
                  _initializeParticles();
                });
              }
              return MouseRegion(
                onEnter: (_) => _isMouseInside = true,
                onExit: (_) => _isMouseInside = false,
                onHover: (event) => _mousePosition = event.localPosition,
                child: GestureDetector(
                  onTap: () => setState(() => _isDispersing = !_isDispersing),
                  child: RepaintBoundary(
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
                ),
              );
            },
          ),
          
          // UI（静的要素をRepaintBoundaryで分離）
          RepaintBoundary(
            child: _buildUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return Stack(
      children: [
        // タイトル
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
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
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
                color: Colors.black54,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mouse, color: Colors.white54, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'マウスを動かして粒子を操作  •  クリックでモード切替',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 背景を分離（再描画を避ける）
class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1a1a2e), Color(0xFF0a0a0f)],
        ),
      ),
    );
  }
}

// シンプルなパーティクルクラス（メモリ効率化）
class Particle {
  double x, y;
  double homeX, homeY;
  double vx, vy;
  final Color color;
  final double size;
  final double depth;

  Particle({
    required this.x,
    required this.y,
    required this.homeX,
    required this.homeY,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.depth,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset mousePosition;
  final bool isMouseInside;
  final bool isDispersing;

  // Paintオブジェクトを再利用
  final Paint _particlePaint = Paint();
  final Paint _corePaint = Paint()..color = Colors.white70;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  ParticlePainter({
    required this.particles,
    required this.mousePosition,
    required this.isMouseInside,
    required this.isDispersing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // パーティクル描画（シンプル化）
    for (var p in particles) {
      final alpha = (0.4 + p.depth * 0.6).clamp(0.0, 1.0);
      
      // メイン粒子
      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 2, _particlePaint);

      // コア（白い中心点）
      _corePaint.color = Colors.white.withValues(alpha: alpha * 0.6);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5, _corePaint);
    }

    // マウスカーソル周りのエフェクト（シンプル化）
    if (isMouseInside) {
      _ringPaint.color = (isDispersing
              ? const Color(0xFF00f5ff)
              : const Color(0xFFff00ff))
          .withValues(alpha: 0.4);
      canvas.drawCircle(mousePosition, 80, _ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

import 'dart:math';

import 'package:elastic_collision/particle.dart';
import 'package:elastic_collision/quadtree.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with SingleTickerProviderStateMixin {
  List<Particle> particles = [];
  Size canvasSize = Size.zero;
  late Ticker ticker;
  double energy = 0;
  Duration lastTick = Duration.zero;
  double second = 0;
  int frames = 0;
  double massConstant = 2;
  Set<String> checkedParticles = {};
  double fps = 0;
  late QuadTree<Particle> quadTree;
  bool debug = false;
  int quadTreeMaxPoints = 10;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(update);
    ticker.start();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        particles = List.generate(
          3000,
          (index) => Particle.random(
            canvasSize,
            massConstant,
            index,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  update(Duration dt) {
    second += (dt.inMilliseconds - lastTick.inMilliseconds) / 1000;
    if (second > 1) {
      fps = frames / second;
      second = 0;
      frames = 0;
    }
    energy = 0;
    quadTree = QuadTree<Particle>(
      bounds: canvasSize,
      anchor: Offset.zero,
      maxPoints: quadTreeMaxPoints,
    );
    quadTree.addAll(
      particles
          .map(
            (e) => QuadTreePoint<Particle>(
              position: e.position.toOffset,
              data: e,
            ),
          )
          .toList(),
    );
    checkedParticles.clear();
    for (var particle in particles) {
      final neighboors = quadTree.query(
        particle.position.toOffset,
        11 * massConstant,
      );
      for (final other in neighboors) {
        if (particle.id != other.data.id) {
          final pair =
              '${min(particle.id, other.data.id)}:${max(particle.id, other.data.id)}';

          if (!checkedParticles.contains(pair)) {
            particle.collide(
              other.data,
              massConstant,
            );

            checkedParticles.add(pair);
          }
        }
      }
      particle.update(
        (dt.inMilliseconds - lastTick.inMilliseconds) / 100,
        canvasSize,
        massConstant,
      );
      energy += particle.kinect();
    }
    lastTick = dt;
    frames++;
    if (mounted) {
      setState(() {});
    }
  }

  updateCanvasSize(Size newSize) {
    if (newSize != canvasSize) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          setState(() {
            canvasSize = newSize;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                updateCanvasSize(
                  Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      color: Colors.white,
                      child: CustomPaint(
                        painter: ParticlePainter(
                          particles: particles,
                          rpm: massConstant,
                        ),
                      ),
                    ),
                    if (debug)
                      CustomPaint(
                        painter: QuadTreePainter(
                          quadTree,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.amber,
              boxShadow: kElevationToShadow[4],
            ),
            child: Wrap(
              spacing: 50,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            final quantity =
                                (particles.length / 10).floor() + 1;
                            setState(() {
                              particles.addAll(
                                List.generate(
                                  quantity,
                                  (index) => Particle.random(
                                    canvasSize,
                                    massConstant,
                                    particles.length + index,
                                  ),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            final quantity =
                                (particles.length / 10).floor() + 1;
                            setState(() {
                              particles.removeRange(0, quantity);
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                    const Text('Partículas:'),
                    Text(particles.length.toString()),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            for (var particle in particles) {
                              particle.velocity.scale(1.1);
                            }
                            setState(() {});
                          },
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            for (var particle in particles) {
                              particle.velocity.scale(0.9);
                            }
                            setState(() {});
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                    const Text('Energia:'),
                    Text('${(energy / 1000).toStringAsFixed(2)}KJ'),
                    const SizedBox(
                      height: 10,
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Temperatura:'),
                        SizedBox(
                          width: 5,
                        ),
                        Tooltip(
                          message: 'Considerando a constante da água',
                          child: Icon(
                            Icons.info_outline,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                    Text(
                        '${(energy * 0.0005265606684073).toStringAsFixed(2)}°C'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              massConstant += 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            if (massConstant > 1) {
                              setState(() {
                                massConstant -= 1;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                    const Text('Raio por Massa:'),
                    Text(massConstant.toStringAsFixed(2)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              quadTreeMaxPoints +=
                                  (quadTreeMaxPoints / 10).ceil();
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            if (quadTreeMaxPoints > 1) {
                              setState(() {
                                quadTreeMaxPoints -=
                                    (quadTreeMaxPoints / 10).ceil();
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                    const Text('QuadTree max points:'),
                    Text(quadTreeMaxPoints.toString()),
                  ],
                ),
                Column(
                  children: [
                    const Text('FPS:'),
                    Text((fps).toStringAsFixed(2)),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text('Quadtree:'),
                    Switch(
                      value: debug,
                      onChanged: (value) {
                        setState(() {
                          debug = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuadTreePainter extends CustomPainter {
  QuadTreePainter(this.quadTree);

  final QuadTree quadTree;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final quads = quadTree.paint();
    for (final quad in quads) {
      canvas.drawRect(
        Rect.fromLTWH(
          quad.$1.dx,
          quad.$1.dy,
          quad.$2.width,
          quad.$2.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(QuadTreePainter oldDelegate) =>
      oldDelegate.quadTree != quadTree;

  @override
  bool shouldRebuildSemantics(QuadTreePainter oldDelegate) => false;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double rpm;

  ParticlePainter({
    required this.particles,
    required this.rpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()..color = particle.color;
      canvas.drawCircle(
        particle.position.toOffset,
        particle.calcRadius(rpm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      oldDelegate.particles != particles;

  @override
  bool shouldRebuildSemantics(ParticlePainter oldDelegate) => false;
}

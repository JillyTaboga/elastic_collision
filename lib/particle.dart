import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

class Particle {
  Color color;
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;
  double mass;
  double calcRadius(double rpm) => sqrt(mass) * rpm;
  double kinect() => velocity.length * 0.5 * mass;
  int id;

  Particle({
    required this.color,
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.mass,
    required this.id,
  });

  update(double dt, Size canvasSize, rpm) {
    velocity = velocity + acceleration;
    position = position + (velocity * dt);
    acceleration = Vector2.zero();
    final radius = calcRadius(rpm);
    if (position.x + radius >= canvasSize.width) {
      velocity.x *= -1;
      position = Vector2(
        canvasSize.width - radius,
        position.y,
      );
    } else if (position.x - radius <= 0) {
      velocity.x *= -1;
      position = Vector2(
        radius,
        position.y,
      );
    }
    if (position.y + radius >= canvasSize.height) {
      velocity.y *= -1;
      position = Vector2(
        position.x,
        canvasSize.height - radius,
      );
    } else if (position.y - radius <= 0) {
      velocity.y *= -1;
      position = Vector2(
        position.x,
        radius,
      );
    }
  }

  collide(Particle other, double rpm) {
    final radius = calcRadius(rpm);
    final otherRadius = other.calcRadius(rpm);
    var pointOfImpact = other.position - position;
    var distance = pointOfImpact.length;
    if (distance <= radius + otherRadius) {
      var impactDirection = pointOfImpact.clone();
      final overlap = distance - (radius + otherRadius);
      impactDirection.length = (overlap * 0.5);
      position.add(impactDirection);
      other.position.sub(impactDirection);
      distance = radius + otherRadius;
      pointOfImpact.length = distance;

      final massSum = mass + other.mass;
      final velocityDif = other.velocity - velocity;
      final double numA = velocityDif.dot(pointOfImpact);
      final divA = distance * distance;
      final result = numA / divA;

      //Particle1
      final multA = 2 * other.mass / massSum;
      final scaleA = result * multA;
      final aCalc = pointOfImpact * scaleA;

      //Particle2
      final multB = -2 * mass / massSum;
      final scaleB = multB * result;
      final bCalc = pointOfImpact * scaleB;

      other.velocity += bCalc;
      velocity += aCalc;
    }
  }

  factory Particle.random(Size canvasSize, double rpm, int id) {
    final random = Random();
    final mass = random.nextInt(10) * random.nextDouble() + 1;
    final randomX = (random.nextDouble() * canvasSize.width);
    final realX = randomX < mass * rpm
        ? mass * rpm
        : randomX > canvasSize.width - mass * rpm
            ? canvasSize.width - mass * rpm
            : randomX;
    final randomY = (random.nextDouble() * canvasSize.height);
    final realY = randomY < 0
        ? mass * 5
        : randomY > canvasSize.height - mass * rpm
            ? canvasSize.height - mass * rpm
            : randomY;
    return Particle(
      acceleration: Vector2.zero(),
      id: id,
      color: Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      ),
      mass: mass,
      position: Vector2(
        realX,
        realY,
      ),
      velocity: Vector2.random()..scale(10 * (random.nextBool() ? 1 : -1)),
    );
  }
}

extension Vector2R on Vector2 {
  Offset get toOffset => Offset(x, y);
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';
import 'dart:ui' as ui;

import 'package:lemon_math/src.dart';
import 'package:lemon_watch/src.dart';

void main() {
  late final ui.Image atlas;
  const cannonRadius = 60.0;
  const cannonLength = 120.0;
  const rocketSpeed = 20.0;
  const earthRadius = 50.0;
  const keyboardRotateSpeed = pi * 0.05;
  const asteroidSpeedVariation = 10.0;
  const asteroidSpawnRadius = 1000.0;

  var cannonAngle = 0.0;
  var nextAsteroid = 0;
  var spawnDuration = 75;

  final gameOver = Watch(false);
  final rockets = <Rocket>[];
  final asteroids = <Asteroid>[];
  final points = Watch(0);

  void fireRocket() {

    for (final rocket in rockets) {
      if (rocket.active) continue;
      rocket.x = adj(cannonAngle, cannonLength);
      rocket.y = opp(cannonAngle, cannonLength);
      rocket.setVelocity(cannonAngle, rocketSpeed);
      rocket.active = true;
      return;
    }

    rockets.add(Rocket(
      x: adj(cannonAngle, cannonLength),
      y: opp(cannonAngle, cannonLength),
      rotation: cannonAngle,
      speed: rocketSpeed,
    ));
  }

  void spawnAsteroid() {
    final asteroidAngle = randomAngle();

    final x = adj(asteroidAngle, asteroidSpawnRadius);
    final y = opp(asteroidAngle, asteroidSpawnRadius);

    asteroids.add(Asteroid(
      x,
      y,
      randomBetween(-asteroidSpeedVariation, asteroidSpeedVariation),
      randomBetween(-asteroidSpeedVariation, asteroidSpeedVariation),
    ));
  }

  void restart() {
    points.value = 0;
    asteroids.clear();
    rockets.clear();
    gameOver.value = false;
  }

  Engine.run(
    backgroundColor: const Color.fromARGB(255, 64, 80, 16),
    init: (sharedPreferences) async {
      atlas = await Engine.loadImageAsset('images/atlas.png');
      Engine.zoom = 0.4;
      Engine.targetZoom = 0.4;
    },
    onMouseMoved: (double x, double y) {
      cannonAngle = angleBetween(
        x,
        y,
        Engine.screenCenterX,
        Engine.screenCenterY,
      );
    },
    onLeftClicked: fireRocket,
    onRightClicked: () {},
    onKeyPressed: (int keyCode) {
      switch (keyCode) {
        case KeyCode.Space:
          fireRocket();
          break;
      }
    },
    update: () {
      if (gameOver.value) return;

      nextAsteroid--;

      if (nextAsteroid <= 0) {
        spawnAsteroid();
        nextAsteroid = spawnDuration;
        if (spawnDuration > 10) {
          spawnDuration--;
        }
      }

      for (final rocket in rockets) {
        rocket.update();
      }

      for (final asteroid in asteroids) {
        asteroid.update();
        if (asteroid.distance < earthRadius) {
          gameOver.value = true;
        }
      }

      // collision detection
      for (var i = 0; i < rockets.length; i++) {
        final rocket = rockets[i];
        if (!rocket.active) continue;
        for (var j = 0; j < asteroids.length; j++) {
          final asteroid = asteroids[j];
          if (!asteroid.active) continue;
          const collisionRadius = 20.0;
          final distanceX = (asteroid.x - rocket.x).abs();
          if (distanceX > collisionRadius) continue;
          final distanceY = (asteroid.y - rocket.y).abs();
          if (distanceY > collisionRadius) continue;
          asteroid.active = false;
          rocket.active = false;
          points.value++;
          break;
        }
      }

      if (Engine.keyPressed(KeyCode.Arrow_Left)) {
        cannonAngle -= keyboardRotateSpeed;
      }
      if (Engine.keyPressed(KeyCode.Arrow_Right)) {
        cannonAngle += keyboardRotateSpeed;
      }
    },
    render: (Canvas canvas, Size size) {
      Engine.cameraX = ((Engine.screenCenterX * 0.01) / Engine.zoom);
      Engine.cameraY = ((Engine.screenCenterY * 0.01) / Engine.zoom);

      // render planet
      Engine.renderSprite(
        image: atlas,
        srcX: 0,
        srcY: 0,
        srcWidth: 126,
        srcHeight: 126,
        dstX: 0,
        dstY: 0,
      );

      // render cannon
      Engine.renderSpriteRotated(
        image: atlas,
        srcX: 129,
        srcY: 1,
        srcWidth: 51,
        srcHeight: 32,
        dstX: adj(cannonAngle, cannonRadius),
        dstY: opp(cannonAngle, cannonRadius),
        anchorX: 0,
        rotation: cannonAngle,
      );

      // render rockets
      for (var rocket in rockets) {
        if (!rocket.active) continue;
        Engine.renderSpriteRotated(
          image: atlas,
          srcX: 208,
          srcY: 9,
          srcWidth: 32,
          srcHeight: 16,
          dstX: rocket.x,
          dstY: rocket.y,
          rotation: rocket.rotation,
          anchorX: 0,
        );
      }

      for (final asteroid in asteroids) {
        if (!asteroid.active) continue;
        Engine.renderSprite(
          image: atlas,
          srcX: 143,
          srcY: 48,
          srcWidth: 47,
          srcHeight: 46,
          dstX: asteroid.x,
          dstY: asteroid.y,
        );
      }
    },
    buildUI: (BuildContext context) => WatchBuilder(gameOver, (bool gameOver) {
      return Stack(
        children: [
          Positioned(
              top: 8,
              left: 8,
              child: WatchBuilder(
                  points,
                  (int points) => Text(
                        "Points: $points",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 20),
                      ))),
          if (gameOver)
            Container(
              width: Engine.screen.width,
              height: Engine.screen.height,
              alignment: Alignment.center,
              child: Engine.buildOnPressed(action: restart,
              child: const Text(
                "GAME OVER - RESTART",
                style: TextStyle(color: Colors.white70, fontSize: 40),
              ),
            ),
            )
        ],
      );
    }),
  );
}

class Asteroid {
  double x;
  double y;

  double vx;
  double vy;

  var distance = 0.0;

  var active = true;

  Asteroid(this.x, this.y, this.vx, this.vy);

  void update() {
    if (!active) return;

    const earthMass = 10000.0;
    distance = hyp(x, y);
    final distanceSquared = max(1, distance * distance);
    final angleToEarth = angle(x, y);
    vx -= adj(angleToEarth, earthMass / distanceSquared);
    vy -= opp(angleToEarth, earthMass / distanceSquared);
    x += vx;
    y += vy;
  }
}

class Rocket {
  double x;
  double y;
  double rotation;

  var active = true;
  var velocityX = 0.0;
  var velocityY = 0.0;
  var lifetime = 1000;

  Rocket({
    required this.x,
    required this.y,
    required this.rotation,
    double speed = 1.0,
  }) {
    setVelocity(rotation, speed);
  }

  void setVelocity(double rotation, double speed){
    this.rotation = rotation;
    velocityX = adj(rotation, speed);
    velocityY = opp(rotation, speed);
    lifetime = 1000;
  }

  void update() {
    if (!active) return;
    x += velocityX;
    y += velocityY;
    lifetime--;
    if (lifetime <= 0) {
      active = false;
    }
  }
}

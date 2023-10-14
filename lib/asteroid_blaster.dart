import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';

import 'dart:ui' as ui;
import 'package:lemon_math/src.dart';
import 'package:lemon_watch/src.dart';

class AsteroidGameWidget extends LemonEngine {
  late final ui.Image atlas;
  final game = AsteroidGame();
  final keyboardRotateSpeed = pi * 0.05;

  AsteroidGameWidget() : super(backgroundColor: const Color.fromARGB(255, 64, 80, 16));

  @override
  Future onInit(sharedPreferences) async {
    atlas = await loadAssetImage('images/atlas.png');
  }

  @override
  void onUpdate(double delta) {
    cameraCenter(0, 0);
    handleKeyboardInput();
    game.update(delta);
  }

  void handleKeyboardInput() {
    if (keyPressed(KeyCode.Arrow_Left)) {
      game.cannonAngle -= keyboardRotateSpeed;
    }
    if (keyPressed(KeyCode.Arrow_Right)) {
      game.cannonAngle += keyboardRotateSpeed;
    }
  }

  @override
  void onDrawCanvas(Canvas canvas, Size size) {
    renderPlanet();
    renderCannon();
    renderRockets();
    renderAsteroids();
  }


  @override
  void onLeftClicked() {
    game.fireRocket();
  }

  @override
  void onRightClicked() {
    game.fireRocket();
  }

  @override
  void onKeyPressed(int keyCode) {
    switch (keyCode) {
      case KeyCode.Space:
        game.fireRocket();
        break;
    }
  }

  @override
  void onMouseMoved(double x, double y) {
    game.cannonAngle = angleBetween(
      x,
      y,
      screenCenterX,
      screenCenterY,
    );
  }


  void renderAsteroids() {
    for (final asteroid in game.asteroids) {
      if (!asteroid.active) continue;
      renderSprite(
        image: atlas,
        srcX: 143,
        srcY: 48,
        srcWidth: 47,
        srcHeight: 46,
        dstX: asteroid.x,
        dstY: asteroid.y,
      );
    }
  }

  void renderRockets() {
    for (var rocket in game.rockets) {
      if (!rocket.active) continue;
      renderSpriteRotated(
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
  }

  void renderCannon() {
    final cannonAngle = game.cannonAngle;
    final cannonRadius = game.cannonRadius;

    renderSpriteRotated(
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
  }

  void renderPlanet() {
    renderSprite(
      image: atlas,
      srcX: 0,
      srcY: 0,
      srcWidth: 126,
      srcHeight: 126,
      dstX: 0,
      dstY: 0,
    );
  }

  @override
  void onDispose() {
    // TODO: implement onDispose
  }

  @override
  Widget buildUI() =>
      WatchBuilder(game.gameOver, (bool gameOver) => Stack(
        children: [
          Positioned(
              top: 8,
              left: 8,
              child: WatchBuilder(
                  game.points,
                      (int points) => Text(
                    "Points: $points",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 20),
                  ))),
          if (gameOver)
            Container(
              width: screen.width,
              height: screen.height,
              alignment: Alignment.center,
              child: TextButton(
                onPressed: game.restart,
                child: const Text(
                  "GAME OVER - RESTART",
                  style: TextStyle(color: Colors.white70, fontSize: 40),
                ),
              ),
            )
        ],
      ));
}

/// contains the business logic for the game.
/// it has no awareness of the lemon engine and should be able to be plugged into
/// any other game engine just as easily
class AsteroidGame {
  var cannonRadius = 60.0;
  var cannonLength = 120.0;
  var rocketSpeed = 20.0;
  var earthRadius = 50.0;
  var asteroidSpeedVariation = 10.0;
  var asteroidSpawnRadius = 1000.0;
  var gameOver = Watch(false);
  var rockets = <Rocket>[];
  var asteroids = <Asteroid>[];
  var points = Watch(0);
  var cannonAngle = 0.0;
  var nextAsteroid = 0;
  var spawnDuration = 75;

  void update(double delta) {
    if (gameOver.value) return;
    updateSpawnAsteroids();
    updateRockets();
    updateAsteroids();
    updateCollisionDetection();
  }

  void updateSpawnAsteroids() {
    nextAsteroid--;
    if (nextAsteroid <= 0) {
      spawnAsteroid();
      nextAsteroid = spawnDuration;
      if (spawnDuration > 10) {
        spawnDuration--;
      }
    }
  }

  void updateRockets() {
    for (final rocket in rockets) {
      rocket.update();
    }
  }

  void updateAsteroids() {
    for (final asteroid in asteroids) {
      asteroid.update();
      if (asteroid.distance < earthRadius) {
        gameOver.value = true;
      }
    }
  }

  void updateCollisionDetection() {
    for (final rocket in rockets) {
      if (!rocket.active) continue;
      for (final asteroid in asteroids) {
        if (!asteroid.active) continue;
        if (distanceBetween(
            asteroid.x, asteroid.y, rocket.x, rocket.y) >
            25) continue;
        asteroid.active = false;
        rocket.active = false;
        points.value++;
        break;
      }
    }
  }

  void fireRocket() {
    rockets.add(Rocket(
      x: adj(cannonAngle, cannonLength),
      y: opp(cannonAngle, cannonLength),
      rotation: cannonAngle,
      speed: rocketSpeed,
    ));
  }

  void spawnAsteroid() {
    final asteroidAngle = randomAngle();
    asteroids.add(Asteroid(
      adj(asteroidAngle, asteroidSpawnRadius),
      opp(asteroidAngle, asteroidSpawnRadius),
      randomBetween(-asteroidSpeedVariation, asteroidSpeedVariation),
      randomBetween(-asteroidSpeedVariation, asteroidSpeedVariation),
    ));
  }

  void restart() {
    asteroids.clear();
    rockets.clear();
    points.value = 0;
    gameOver.value = false;
    spawnDuration = 75;
  }
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
    velocityX = adj(rotation, speed);
    velocityY = opp(rotation, speed);
  }

  void update() {
    if (!active) return;
    x += velocityX;
    y += velocityY;
    if (lifetime-- <= 0) {
      active = false;
    }
  }
}

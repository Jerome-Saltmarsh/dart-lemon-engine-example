import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';
import 'dart:ui' as ui;


void main() {

  late final ui.Image atlas;

  var playerX = 200.0;
  var playerY = 200.0;
  var playerTargetX = 0.0;
  var playerTargetY = 0.0;
  var playerRotation = 0.0;
  var playerFrame = 0;

  const playerSpeed = 2.0;
  const frameSize = 64.0;
  const playerFrames = 4;

  void restartPlayer(){
    playerX = 200;
    playerY = 200;
    playerTargetX = playerX;
    playerTargetY = playerY;
  }

  Engine.run(
      init: (sharedPreferences) async {
        atlas = await Engine.loadImageAsset('images/atlas.png');
        restartPlayer();
      },
      onLeftClicked: (){
          playerTargetX = Engine.mouseWorldX;
          playerTargetY = Engine.mouseWorldY;
      },
      onRightClicked: (){
          playerX = Engine.mouseWorldX;
          playerY = Engine.mouseWorldY;
          playerTargetX = playerX;
          playerTargetY = playerY;
      },

      update: () {

        if (Engine.keyPressed(KeyCode.Space)){
          restartPlayer();
        }
        final distanceFromTarget = Engine.calculateDistance(
            playerX,
            playerY,
            playerTargetX,
            playerTargetY,
        );
        if (distanceFromTarget < 10) {
          playerFrame = 0;
          return;
        }
        if (Engine.paintFrame % 3 == 0){
          playerFrame++;
          playerFrame %= playerFrames;
        }

        playerRotation = Engine.calculateAngleBetween(
          playerTargetX,
          playerTargetY,
          playerX,
          playerY,
        );
        playerX += Engine.calculateAdjacent(playerRotation, playerSpeed);
        playerY += Engine.calculateOpposite(playerRotation, playerSpeed);

      },
      render: (Canvas canvas, Size size) {
        Engine.renderSpriteRotated(
            image: atlas,
            srcX: playerFrame * frameSize,
            srcY: 0,
            srcWidth: frameSize,
            srcHeight: frameSize,
            dstX: playerX,
            dstY: playerY,
            rotation: playerRotation,
        );
      },
      buildUI: (BuildContext context) => Stack(
          children: [
            const Positioned(
              top: 16,
              left: 16,
              child: Text("left click to move",
                  style: TextStyle(color: Colors.white70, fontSize: 20))
            ),
            Positioned(
                bottom: 16,
                right: 16,
                child: Engine.buildOnPressed(
                  child: const Text(
                    "RESET",
                    style: TextStyle(color: Colors.white70, fontSize: 60),
                  ),
                  action: restartPlayer,
                )),
          ],
        ));
}
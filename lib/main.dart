import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';
import 'dart:ui' as ui;

void main() {

  late final ui.Image imageCharacterLeft;
  late final ui.Image imageCharacterRight;
  late final ui.Image imagePath;

  const characterAnimationIdle    = [0];
  const characterAnimationRun     = [1, 2, 3, 4];
  const characterAnimationAttack  = [5];
  const characterFrameRate = 6;
  const characterSpeed = 2.0;
  const frameWidth = 100.0;
  const frameHeight = 64.0;


  var characterX = 200.0;
  var characterY = 200.0;
  var characterStateDuration = 0;
  var characterAnimationFrame = 0;
  var characterState = CharacterState.idle;
  var characterStateNext = CharacterState.idle;
  var characterAnimation = characterAnimationIdle;
  var characterDirection = CharacterDirection.right;

  Engine.run(
      init: (sharedPreferences) async {
        imageCharacterLeft = await Engine.loadImageAsset('images/character-left.png');
        imageCharacterRight = await Engine.loadImageAsset('images/character-right.png');
        imagePath = await Engine.loadImageAsset('images/path.png');
      },
      onLeftClicked: (){

      },
      onRightClicked: (){
          characterX = Engine.mouseWorldX;
          characterY = Engine.mouseWorldY;
      },
      onKeyPressed: (int keyCode){
        switch (keyCode){
          case KeyCode.Arrow_Left:
            characterStateNext = CharacterState.running;
            characterDirection = CharacterDirection.left;
            break;
          case KeyCode.Arrow_Right:
            characterStateNext = CharacterState.running;
            characterDirection = CharacterDirection.right;
            break;
        }
      },
      onKeyUp: (int keyCode){
        switch (keyCode){
          case KeyCode.Arrow_Left:
            characterStateNext = CharacterState.idle;
            break;
          case KeyCode.Arrow_Right:
            characterStateNext = CharacterState.idle;
            break;
        }
      },
      update: () {

        Engine.cameraFollow(characterX, characterY, 0.00075);
        characterStateDuration++;

        if (characterStateNext != characterState) {
          characterState = characterStateNext;
          characterStateDuration = 0;
          characterAnimationFrame = 0;
          switch (characterState) {
            case CharacterState.idle:
              characterAnimation = characterAnimationIdle;
              break;
            case CharacterState.running:
              characterAnimation = characterAnimationRun;
              break;
            case CharacterState.attacking:
              characterAnimation = characterAnimationAttack;
              break;
          }
        }

        characterAnimationFrame = characterAnimation[
          characterStateDuration ~/
              characterFrameRate % characterAnimation.length
        ];

        switch (characterState) {
          case CharacterState.idle:
            break;
          case CharacterState.running:
            characterX += characterDirection == CharacterDirection.left
                ? -characterSpeed
                : characterSpeed;
            break;
          case CharacterState.attacking:
            // TODO: Handle this case.
            break;
        }
      },
      render: (Canvas canvas, Size size) {
        for (var i = 0; i < 100; i++) {
          Engine.renderSprite(
            image: imagePath,
            srcX: 0,
            srcY: 0,
            srcWidth: 256,
            srcHeight: 256,
            dstX: i * 256,
            dstY: 190,
          );
        }

        Engine.renderSprite(
            image: characterDirection == CharacterDirection.left
                ? imageCharacterLeft
                : imageCharacterRight,
            srcX: characterAnimationFrame * frameWidth,
            srcY: 0,
            srcWidth: frameWidth,
            srcHeight: frameHeight,
            dstX: characterX,
            dstY: characterY,
        );
      },
      buildUI: (BuildContext context) => Stack(
          children: const [
            Positioned(
              top: 16,
              left: 16,
              child: Text("left click to move",
                  style: TextStyle(color: Colors.white70, fontSize: 20))
            ),
          ],
        ));
}

enum CharacterState {
  idle,
  running,
  attacking,
}

enum CharacterDirection {
  left,
  right,
}
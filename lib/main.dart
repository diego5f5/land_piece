import 'dart:async';
import 'package:a_star_algorithm/a_star_algorithm.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: 'Land Piece',
    size: Size(1280, 720),
    minimumSize: Size(640, 360),
    center: true,
    // fullScreen: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(GameWidget(game: LandPieceGame()));
}

class LandPieceGame extends FlameGame with TapDetector {
  final Vector2 viewportResolution = Vector2(640, 360);
  final double srcTileSize = 32;

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(viewportResolution);
    camera.speed = 1;

    add(Map(srcTileSize: srcTileSize));

    add(Player(srcTileSize: srcTileSize));

    // FPS Counter
    add(FpsTextComponent(position: Vector2(0, size.y - 24)));
  }

  Vector2 getCoordsByPosition(Vector2 pos) {
    return Vector2(
      (pos.x / srcTileSize).floorToDouble(),
      (pos.y / srcTileSize).floorToDouble(),
    );
  }

  @override
  void onTapDown(TapDownInfo info) {
    Iterable<Offset> result = AStar(
      rows: 20,
      columns: 20,
      start: const Offset(0, 0),
      end: getCoordsByPosition(info.eventPosition.game).toOffset(),
      barriers: const [
        Offset(10, 5),
        Offset(10, 6),
        Offset(10, 7),
        Offset(10, 8),
      ],
      withDiagonal: false,
    ).findThePath();

    print(result);
  }
}

class Map extends SpriteBatchComponent with HasGameRef<LandPieceGame> {
  final double srcTileSize;

  Map({required this.srcTileSize});

  static const double size = 20 * 32;
  static const Rect bounds = Rect.fromLTWH(0, 0, size, size);

  @override
  Future<void> onLoad() async {
    SpriteBatch spriteBatch = await gameRef.loadSpriteBatch('tile.png');
    this.spriteBatch = spriteBatch;

    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 20; j++) {
        spriteBatch.add(
          source: Rect.fromLTWH(0, 0, srcTileSize, srcTileSize),
          offset: Vector2(j * srcTileSize, i * srcTileSize),
        );
      }
    }
  }
}

class Player extends SpriteAnimationComponent with HasGameRef<LandPieceGame> {
  final double srcTileSize;

  Player({
    required this.srcTileSize,
  });

  final double speed = 200;
  late SpriteAnimationComponent playerAnimationComponent;
  late Iterable<Vector2> pathToMove;

  @override
  Future<void> onLoad() async {
    pathToMove = [
      Vector2(0, 0),
      Vector2(0, 1),
      Vector2(0, 2),
      Vector2(0, 3),
      Vector2(0, 4),
      Vector2(1, 4),
      Vector2(2, 4),
      Vector2(3, 4),
      Vector2(4, 4),
      Vector2(5, 4),
      Vector2(6, 4),
      Vector2(6, 5),
      Vector2(6, 6),
      Vector2(6, 7),
      Vector2(6, 8),
      Vector2(6, 9),
      Vector2(6, 10),
      Vector2(6, 11),
      Vector2(6, 12),
    ];

    SpriteSheet playerSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('player.png'),
      srcSize: Vector2.all(srcTileSize),
    );

    final playerAnimation = playerSpriteSheet.createAnimation(
      row: 0,
      stepTime: 0.2,
    );

    playerAnimationComponent = SpriteAnimationComponent(
      animation: playerAnimation,
      position: Vector2.all(0),
      size: Vector2.all(srcTileSize),
    );

    add(playerAnimationComponent);

    gameRef.camera.followComponent(
      playerAnimationComponent,
      worldBounds: Map.bounds,
    );
  }

  late int pathConcluded = 0;
  late Vector2? currentTarget = pathToMove.first;

  double distanceToTarget(Vector2 current, Vector2 target) {
    return (target - current).length;
  }

  double maxDistancePerFrame(double speed, double dt) {
    return speed * dt;
  }

  void playerMoveByPath(double dt) {
    if (pathConcluded >= pathToMove.length) {
      return;
    }

    final currentPos =
        Vector2(playerAnimationComponent.x, playerAnimationComponent.y);
    final targetPos = currentTarget! * srcTileSize;

    final distanceToMove = maxDistancePerFrame(speed, dt);

    final displacement = (targetPos - currentPos).normalized() * distanceToMove;

    if (distanceToTarget(currentPos, targetPos) <= distanceToMove) {
      playerAnimationComponent.x = targetPos.x;
      playerAnimationComponent.y = targetPos.y;

      pathConcluded++;
      if (pathConcluded < pathToMove.length) {
        currentTarget = pathToMove.elementAt(pathConcluded);
      }
    } else {
      playerAnimationComponent.x += displacement.x;
      playerAnimationComponent.y += displacement.y;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    playerMoveByPath(dt);
  }
}

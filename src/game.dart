import "dart:async";
import "dart:html";
import "dart:math";

import "assets.dart";
import "graphics.dart";
import "input_handler.dart";
import "metrics.dart";
import "world.dart";

const num DT = 1000 / 60;
const int RENDER_DISTANCE = 20;

void startGame() async {
    setupInputHandler((KeyboardEvent e) {
        if (e.keyCode == M_KEY) {
            level.backgroundMusic.toggle();
        }
    }, (e) {});
    setupGraphics("#game");

    await Assets.load();

    level = Assets.levels[0];
    level.backgroundMusic.play(loop: true);

    window.onResize.listen((Event e) {
        resizeCanvas();
    });
    resizeCanvas();

    // Update and Render
    Timer updateTimer = new Timer.periodic(new Duration(microseconds: (1000.0 * DT).round()), update);
    window.animationFrame.then(render);
}

num jumpTimer = 0;
void update(Timer timer) {
    jumpTimer += DT;

    // Running
    level.player.velocity.x = 0;
    if (isKeyPressed(A_KEY)) {
        level.player.moveLeft();
    }
    if (isKeyPressed(D_KEY)) {
        level.player.moveRight();
    }

    // Jumping
    if (level.player.grounded && (isKeyPressed(SPACEBAR_KEY) || isKeyPressed(W_KEY)) && jumpTimer > 100) {
        level.player.jump();
        jumpTimer = 0;
    }

    // Attacking
    if (isKeyPressed(LEFT_KEY)) {
        level.player.attack(Direction.LEFT);
    }
    if (isKeyPressed(UP_KEY)) {
        level.player.attack(Direction.UP);
    }
    if (isKeyPressed(RIGHT_KEY)) {
        level.player.attack(Direction.RIGHT);
    }
    if (isKeyPressed(DOWN_KEY)) {
        level.player.attack(Direction.DOWN);
    }

    // Updating
    for (Entity e in level.entities) {
        e.update(DT);
    }
    for (Entity e in level.entitiesPendingRemoval) {
        level.entities.remove(e);
    }
    level.entitiesPendingRemoval.clear();
}

Vector offset = new Vector.zero();
Tile pt;
void render(num timestamp) {
    // Clear
    ctx.save();
    ctx.fillStyle = "#00C6FF";
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.restore();

    if (level.player.boundingBox.cx < scaledCanvasWidth() / 2) {
        offset.x = 0;
    } else if (level.player.boundingBox.cx > worldWidth() - scaledCanvasWidth() / 2) {
        offset.x = scaledCanvasWidth() - worldWidth();
    } else {
        offset.x = scaledCanvasWidth() / 2 - level.player.boundingBox.cx;
    }
    offset.y = 0;

    pt = level.player.tile != null ? level.player.tile : pt;
    for (int r = max(pt.row - RENDER_DISTANCE, 0); r <= min(pt.row + RENDER_DISTANCE, level.map.length - 1); r++) {
        for (int c = max(pt.col - RENDER_DISTANCE, 0); c <= min(pt.col + RENDER_DISTANCE, level.map[r].length - 1); c++) {
            level.map[r][c].render(offset);
        }
    }

    for (Entity e in level.entities) {
        e.render(offset);
    }

    window.animationFrame.then(render);
}

bool isKeyPressed(int keyCode) {
    // Cannot just return keys[keyCode] because it may be null.
    return keys[keyCode] == true;
}

void resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    num s = canvas.height / worldHeight();
    ctx.scale(s, s);
}


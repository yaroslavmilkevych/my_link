import test from "node:test";
import assert from "node:assert/strict";

import {
  createFoodPosition,
  createInitialState,
  setDirection,
  stepGame,
} from "./snake-logic.js";

test("snake moves one cell in the active direction", () => {
  const started = setDirection(createInitialState(8), "right");
  const next = stepGame(started);

  assert.deepEqual(next.snake[0], { x: 5, y: 4 });
  assert.equal(next.snake.length, 3);
});

test("snake grows and score increases after eating food", () => {
  const started = setDirection(createInitialState(8), "right");
  const state = {
    ...started,
    food: { x: 5, y: 4 },
  };
  const next = stepGame(state, () => 0);

  assert.equal(next.score, 1);
  assert.equal(next.snake.length, 4);
  assert.deepEqual(next.snake[0], { x: 5, y: 4 });
  assert.notDeepEqual(next.food, { x: 5, y: 4 });
});

test("wall collisions end the game", () => {
  const state = {
    ...setDirection(createInitialState(4), "right"),
    snake: [
      { x: 3, y: 2 },
      { x: 2, y: 2 },
      { x: 1, y: 2 },
    ],
  };
  const next = stepGame(state);

  assert.equal(next.gameOver, true);
});

test("self collisions end the game", () => {
  const state = {
    ...setDirection(createInitialState(6), "up"),
    direction: "up",
    queuedDirection: "left",
    snake: [
      { x: 2, y: 2 },
      { x: 1, y: 2 },
      { x: 1, y: 3 },
      { x: 2, y: 3 },
      { x: 3, y: 3 },
      { x: 3, y: 2 },
    ],
    started: true,
  };
  const next = stepGame(state);

  assert.equal(next.gameOver, true);
});

test("food placement skips occupied snake cells", () => {
  const food = createFoodPosition(
    2,
    [
      { x: 0, y: 0 },
      { x: 1, y: 0 },
      { x: 0, y: 1 },
    ],
    () => 0,
  );

  assert.deepEqual(food, { x: 1, y: 1 });
});

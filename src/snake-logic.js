export const GRID_SIZE = 16;
const START_LENGTH = 3;

const DIRECTIONS = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
};

const OPPOSITES = {
  up: "down",
  down: "up",
  left: "right",
  right: "left",
};

function toKey(point) {
  return `${point.x}:${point.y}`;
}

function pointsEqual(a, b) {
  return a.x === b.x && a.y === b.y;
}

export function createInitialState(size = GRID_SIZE) {
  const center = Math.floor(size / 2);
  const snake = Array.from({ length: START_LENGTH }, (_, index) => ({
    x: center - index,
    y: center,
  }));

  return {
    size,
    snake,
    direction: "right",
    queuedDirection: "right",
    food: createFoodPosition(size, snake),
    score: 0,
    started: false,
    paused: false,
    gameOver: false,
  };
}

export function createFoodPosition(size, snake, random = Math.random) {
  const occupied = new Set(snake.map(toKey));
  const freeCells = [];

  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      const point = { x, y };
      if (!occupied.has(toKey(point))) {
        freeCells.push(point);
      }
    }
  }

  if (freeCells.length === 0) {
    return null;
  }

  const index = Math.floor(random() * freeCells.length);
  return freeCells[index];
}

export function setDirection(state, nextDirection) {
  if (!DIRECTIONS[nextDirection] || state.gameOver) {
    return state;
  }

  const blockedDirection = OPPOSITES[state.direction];
  if (nextDirection === blockedDirection && state.started) {
    return state;
  }

  return {
    ...state,
    queuedDirection: nextDirection,
    started: true,
    paused: false,
  };
}

export function togglePause(state) {
  if (!state.started || state.gameOver) {
    return state;
  }

  return {
    ...state,
    paused: !state.paused,
  };
}

export function restartGame(size = GRID_SIZE) {
  return createInitialState(size);
}

export function stepGame(state, random = Math.random) {
  if (!state.started || state.paused || state.gameOver) {
    return state;
  }

  const direction = state.queuedDirection;
  const delta = DIRECTIONS[direction];
  const head = state.snake[0];
  const nextHead = { x: head.x + delta.x, y: head.y + delta.y };
  const snakeWithoutTail = state.snake.slice(0, -1);
  const hitWall =
    nextHead.x < 0 ||
    nextHead.y < 0 ||
    nextHead.x >= state.size ||
    nextHead.y >= state.size;
  const hitSelf = snakeWithoutTail.some((segment) => pointsEqual(segment, nextHead));

  if (hitWall || hitSelf) {
    return {
      ...state,
      direction,
      gameOver: true,
      paused: false,
    };
  }

  const ateFood = state.food && pointsEqual(nextHead, state.food);
  const nextSnake = [nextHead, ...state.snake];

  if (!ateFood) {
    nextSnake.pop();
  }

  return {
    ...state,
    snake: nextSnake,
    direction,
    food: ateFood ? createFoodPosition(state.size, nextSnake, random) : state.food,
    score: ateFood ? state.score + 1 : state.score,
  };
}

export function getStatusMessage(state) {
  if (state.gameOver) {
    return "Game over. Press Restart to try again.";
  }

  if (!state.started) {
    return "Press an arrow key or WASD to begin.";
  }

  if (state.paused) {
    return "Paused. Press space or Pause to continue.";
  }

  return "Collect food and avoid the walls or your tail.";
}

export function getCellType(state, point) {
  const head = state.snake[0];

  if (state.food && pointsEqual(state.food, point)) {
    return "food";
  }

  if (pointsEqual(head, point)) {
    return "head";
  }

  if (state.snake.some((segment) => pointsEqual(segment, point))) {
    return "snake";
  }

  return "empty";
}

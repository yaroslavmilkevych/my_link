import {
  GRID_SIZE,
  createInitialState,
  getCellType,
  getStatusMessage,
  restartGame,
  setDirection,
  stepGame,
  togglePause,
} from "./snake-logic.js";

const TICK_MS = 140;

function buildBoard(boardElement, size) {
  const fragment = document.createDocumentFragment();

  for (let index = 0; index < size * size; index += 1) {
    const cell = document.createElement("div");
    cell.className = "cell";
    cell.setAttribute("role", "gridcell");
    fragment.appendChild(cell);
  }

  boardElement.replaceChildren(fragment);
}

function renderBoard(boardElement, state) {
  const cells = boardElement.children;

  for (let y = 0; y < state.size; y += 1) {
    for (let x = 0; x < state.size; x += 1) {
      const cell = cells[y * state.size + x];
      const type = getCellType(state, { x, y });

      cell.className = "cell";

      if (type === "snake") {
        cell.classList.add("cell--snake");
      }

      if (type === "head") {
        cell.classList.add("cell--snake", "cell--head");
      }

      if (type === "food") {
        cell.classList.add("cell--food");
      }
    }
  }
}

function createRenderer(initialState) {
  const boardElement = document.querySelector("#board");
  const scoreElement = document.querySelector("#score");
  const statusElement = document.querySelector("#status");
  const pauseButton = document.querySelector("#pause-button");

  buildBoard(boardElement, initialState.size);

  return function render(state) {
    scoreElement.textContent = String(state.score);
    statusElement.textContent = getStatusMessage(state);
    pauseButton.textContent = state.paused ? "Resume" : "Pause";
    renderBoard(boardElement, state);
  };
}

function directionFromKey(key) {
  const value = key.toLowerCase();

  if (value === "arrowup" || value === "w") return "up";
  if (value === "arrowdown" || value === "s") return "down";
  if (value === "arrowleft" || value === "a") return "left";
  if (value === "arrowright" || value === "d") return "right";
  return null;
}

function mountGame() {
  let state = createInitialState(GRID_SIZE);
  const render = createRenderer(state);
  const restartButton = document.querySelector("#restart-button");
  const pauseButton = document.querySelector("#pause-button");
  const controlButtons = document.querySelectorAll("[data-direction]");

  render(state);

  document.addEventListener("keydown", (event) => {
    const nextDirection = directionFromKey(event.key);

    if (nextDirection) {
      event.preventDefault();
      state = setDirection(state, nextDirection);
      render(state);
      return;
    }

    if (event.code === "Space") {
      event.preventDefault();
      state = togglePause(state);
      render(state);
    }
  });

  restartButton.addEventListener("click", () => {
    state = restartGame(GRID_SIZE);
    render(state);
  });

  pauseButton.addEventListener("click", () => {
    state = togglePause(state);
    render(state);
  });

  controlButtons.forEach((button) => {
    button.addEventListener("click", () => {
      state = setDirection(state, button.dataset.direction);
      render(state);
    });
  });

  window.setInterval(() => {
    state = stepGame(state);
    render(state);
  }, TICK_MS);
}

if (typeof document !== "undefined") {
  mountGame();
}

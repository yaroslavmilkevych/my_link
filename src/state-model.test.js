import test from "node:test";
import assert from "node:assert/strict";

import {
  buildQuizQuestion,
  createDefaultProgress,
  summarizeProgress,
  upsertWordProgress,
} from "./state-model.js";

const sampleWords = [
  { id: "one", polish: "cześć", russian: "привет" },
  { id: "two", polish: "kawa", russian: "кофе" },
  { id: "three", polish: "sklep", russian: "магазин" },
];

test("default progress marks every word as new", () => {
  const progress = createDefaultProgress(sampleWords);

  assert.equal(progress.one.status, "new");
  assert.equal(progress.two.correctAnswers, 0);
});

test("archiving a word increments review counters", () => {
  const next = upsertWordProgress({}, "one", "archived");

  assert.equal(next.one.status, "archived");
  assert.equal(next.one.correctAnswers, 1);
  assert.ok(next.one.lastReviewedAt);
});

test("summary counts new and archived words", () => {
  const progress = {
    one: { wordId: "one", status: "archived" },
    two: { wordId: "two", status: "learning" },
    three: { wordId: "three", status: "new" },
  };

  const summary = summarizeProgress(sampleWords, progress);

  assert.deepEqual(summary, { newWords: 2, archived: 1 });
});

test("quiz question uses archived word translations as options", () => {
  const question = buildQuizQuestion(sampleWords, () => 0);

  assert.equal(question.prompt, 'Как переводится слово "cześć"?');
  assert.equal(question.correctAnswer, "привет");
  assert.equal(question.options.length, 3);
});

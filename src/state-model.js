export function createDefaultProgress(words) {
  return Object.fromEntries(
    words.map((word) => [
      word.id,
      {
        wordId: word.id,
        status: "new",
        correctAnswers: 0,
        lastReviewedAt: null,
      },
    ]),
  );
}

export function mergeWordsWithProgress(words, progressMap) {
  return words.map((word) => ({
    ...word,
    progress: progressMap[word.id] ?? {
      wordId: word.id,
      status: "new",
      correctAnswers: 0,
      lastReviewedAt: null,
    },
  }));
}

export function upsertWordProgress(progressMap, wordId, nextStatus) {
  const current = progressMap[wordId] ?? {
    wordId,
    status: "new",
    correctAnswers: 0,
    lastReviewedAt: null,
  };

  const correctAnswers =
    nextStatus === "archived"
      ? current.correctAnswers + 1
      : current.correctAnswers;

  return {
    ...progressMap,
    [wordId]: {
      ...current,
      status: nextStatus,
      correctAnswers,
      lastReviewedAt: new Date().toISOString(),
    },
  };
}

export function summarizeProgress(words, progressMap) {
  return words.reduce(
    (summary, word) => {
      const status = progressMap[word.id]?.status ?? "new";

      if (status === "archived") {
        summary.archived += 1;
      } else {
        summary.newWords += 1;
      }

      return summary;
    },
    { newWords: 0, archived: 0 },
  );
}

export function buildQuizQuestion(archivedWords, random = Math.random) {
  if (archivedWords.length < 2) {
    return null;
  }

  const answerIndex = Math.floor(random() * archivedWords.length);
  const answerWord = archivedWords[answerIndex];
  const distractors = archivedWords.filter((word) => word.id !== answerWord.id).slice(0, 3);
  const options = [answerWord.russian, ...distractors.map((word) => word.russian)];

  return {
    wordId: answerWord.id,
    prompt: `Как переводится слово "${answerWord.polish}"?`,
    correctAnswer: answerWord.russian,
    options: shuffle(options, random),
  };
}

export function shuffle(items, random = Math.random) {
  const clone = [...items];

  for (let index = clone.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [clone[index], clone[swapIndex]] = [clone[swapIndex], clone[index]];
  }

  return clone;
}

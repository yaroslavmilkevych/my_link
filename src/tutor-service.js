const DIALOGUE_SCENARIOS = [
  {
    id: "cafe",
    title: "Кафе",
    starter: "Dzień dobry! Co chcesz zamówić w kawiarni?",
    hintsRu: "Ответь коротко на польском, например: Chcę kawę i herbatę.",
    prompts: [
      "Dzień dobry! Co chcesz zamówić w kawiarni?",
      "Świetnie. Czy napój ma być duży czy mały?",
      "Dobrze. A czy to ma być na miejscu czy na wynos?",
    ],
    replies: [
      "Brzmi dobrze. A czy chcesz coś słodkiego do tego?",
      "Dobrze to brzmi. Możesz odpowiedzieć pełnym zdaniem i dodać rozmiar napoju.",
      "Bardzo dobrze. Jeszcze jedna krótka odpowiedź i zamówienie będzie gotowe.",
    ],
  },
  {
    id: "shop",
    title: "Магазин",
    starter: "Cześć! Szukasz czegoś konkretnego w sklepie?",
    hintsRu: "Можно ответить: Szukam chleba i mleka.",
    prompts: [
      "Cześć! Szukasz czegoś konkretnego w sklepie?",
      "Rozumiem. W jakiej ilości tego potrzebujesz?",
      "Dobrze. Czy chcesz też zapytać o cenę po polsku?",
    ],
    replies: [
      "Rozumiem. W jakiej ilości tego potrzebujesz?",
      "Dobrze. Spróbuj dodać liczebnik albo ilość, na przykład dwa litry.",
      "Bardzo dobrze. Możesz jeszcze zapytać, gdzie to stoi.",
    ],
  },
  {
    id: "transport",
    title: "Дорога",
    starter: "Dobry wieczór! Jak mogę dojść na dworzec?",
    hintsRu: "Попробуй ответить простым направлением: Idź prosto, potem w lewo.",
    prompts: [
      "Dobry wieczór! Jak mogę dojść na dworzec?",
      "Dobrze. A co dalej po skręcie?",
      "Super. Na koniec powiedz, czy to daleko czy blisko.",
    ],
    replies: [
      "Dobrze. Użyj prostych słów kierunku: prosto, w lewo, w prawo.",
      "Super. Jeszcze jedno zdanie, żeby dokończyć wskazówki.",
      "Świetnie. Takie krótkie instrukcje są bardzo naturalne w rozmowie.",
    ],
  },
];

const TRANSLATION_EXERCISES = [
  {
    id: "tr-1",
    promptRu: "Переведи на польский: Я хочу кофе.",
    accepted: ["chcę kawę", "ja chcę kawę"],
    suggestedPolish: "Chcę kawę.",
    explanationRu: "Для базовой фразы достаточно конструкции 'Chcę + винительный падеж'.",
    commonMistakes: [
      {
        pattern: /ja chce kawa/i,
        correction: "Нужно 'chcę' с ę и 'kawę' в форме винительного падежа.",
      },
      {
        pattern: /chce/i,
        correction: "В польском 1-е лицо: 'chcę', а не 'chce'.",
      },
    ],
  },
  {
    id: "tr-2",
    promptRu: "Переведи на польский: Сегодня я иду в магазин.",
    accepted: ["dzisiaj idę do sklepu", "dziś idę do sklepu"],
    suggestedPolish: "Dzisiaj idę do sklepu.",
    explanationRu: "Для направления к месту обычно используется 'do' + родительный падеж.",
    commonMistakes: [
      {
        pattern: /na sklep/i,
        correction: "Для движения в магазин лучше 'do sklepu', а не 'na sklep'.",
      },
    ],
  },
  {
    id: "tr-3",
    promptRu: "Переведи на польский: Добрый вечер, где вокзал?",
    accepted: ["dobry wieczór, gdzie jest dworzec", "dobry wieczór gdzie jest dworzec"],
    suggestedPolish: "Dobry wieczór, gdzie jest dworzec?",
    explanationRu: "В вопросе полезно сохранить связку 'gdzie jest ...'.",
    commonMistakes: [
      {
        pattern: /gdzie dworzec/i,
        correction: "Лучше использовать полную форму вопроса: 'gdzie jest dworzec?'.",
      },
    ],
  },
  {
    id: "tr-4",
    promptRu: "Переведи на польский: Мне нужен маленький чай.",
    accepted: ["potrzebuję małej herbaty", "chcę małą herbatę"],
    suggestedPolish: "Potrzebuję małej herbaty.",
    explanationRu:
      "После 'potrzebuję' существительное обычно идет в родительном падеже, поэтому 'herbaty'.",
    commonMistakes: [
      {
        pattern: /mała herbata/i,
        correction:
          "После 'potrzebuję' лучше использовать форму 'małej herbaty'.",
      },
      {
        pattern: /potrzebuję mała/i,
        correction:
          "При 'potrzebuję' прилагательное и существительное нужно согласовать: 'małej herbaty'.",
      },
    ],
  },
];

function normalize(value) {
  return value
    .toLowerCase()
    .replace(/[.!?,]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export class TutorService {
  constructor() {
    this.dialogueScenarioIndex = 0;
    this.dialoguePromptIndex = 0;
    this.translationStep = 0;
  }

  getExercise(mode) {
    if (mode === "dialogue") {
      const scenario = DIALOGUE_SCENARIOS[this.dialogueScenarioIndex];
      return {
        mode,
        title: scenario.title,
        prompt: scenario.prompts[this.dialoguePromptIndex],
        helpText: scenario.hintsRu,
      };
    }

    const exercise =
      TRANSLATION_EXERCISES[this.translationStep % TRANSLATION_EXERCISES.length];
    return {
      mode,
      title: "Перевод с исправлением",
      prompt: exercise.promptRu,
      helpText: "Напиши свой вариант на польском, и ассистент подскажет, что улучшить.",
    };
  }

  advance(mode) {
    if (mode === "dialogue") {
      this.dialogueScenarioIndex =
        (this.dialogueScenarioIndex + 1) % DIALOGUE_SCENARIOS.length;
      this.dialoguePromptIndex = 0;
      return this.getExercise("dialogue");
    }

    this.translationStep =
      (this.translationStep + 1) % TRANSLATION_EXERCISES.length;
    return this.getExercise("translation");
  }

  respond(mode, userInput) {
    if (mode === "dialogue") {
      return this.respondToDialogue(userInput);
    }

    return this.respondToTranslation(userInput);
  }

  respondToDialogue(userInput) {
    const scenario = DIALOGUE_SCENARIOS[this.dialogueScenarioIndex];
    const reply = scenario.replies[this.dialoguePromptIndex];
    const userText = normalize(userInput);
    const looksDirectional =
      /prosto|lewo|prawo|dworzec|sklep|kawa|herbata|chcę|szukam|poproszę/.test(
        userText,
      );
    const corrections = [
      looksDirectional
        ? "Хорошо: ты используешь полезные польские слова по теме разговора."
        : "Попробуй добавить ключевые слова по теме, например napój, sklep, prosto, w lewo.",
    ];

    this.dialoguePromptIndex += 1;
    const finishedScenario = this.dialoguePromptIndex >= scenario.prompts.length;

    if (finishedScenario) {
      this.dialoguePromptIndex = 0;
      this.dialogueScenarioIndex =
        (this.dialogueScenarioIndex + 1) % DIALOGUE_SCENARIOS.length;
    }

    return {
      mode: "dialogue",
      replyText: finishedScenario
        ? `${reply} Сценарий завершен, можно перейти к следующей теме.`
        : reply,
      corrections,
      explanationRu:
        "Диалоговый режим поощряет простые польские ответы по теме и плавно ведет разговор дальше.",
      suggestedPolish: buildDialogueSuggestion(userText, scenario.id),
    };
  }

  respondToTranslation(userInput) {
    const exercise =
      TRANSLATION_EXERCISES[this.translationStep % TRANSLATION_EXERCISES.length];
    const normalized = normalize(userInput);
    const corrections = [];
    const isAccepted = exercise.accepted.some(
      (candidate) => normalize(candidate) === normalized,
    );

    if (!isAccepted) {
      exercise.commonMistakes.forEach((mistake) => {
        if (mistake.pattern.test(userInput)) {
          corrections.push(mistake.correction);
        }
      });
    }

    if (corrections.length === 0) {
      corrections.push(
        isAccepted
          ? "Отлично: конструкция звучит естественно для уровня A1."
          : "Близко по смыслу, но стоит проверить форму слов и порядок слов в предложении.",
      );
    }

    this.translationStep += 1;

    return {
      mode: "translation",
      replyText: isAccepted
        ? "Хороший перевод. Можно двигаться дальше."
        : "Вот как можно сделать фразу более естественной.",
      corrections,
      explanationRu: exercise.explanationRu,
      suggestedPolish: exercise.suggestedPolish,
    };
  }
}

function buildDialogueSuggestion(userText, scenarioId) {
  if (scenarioId === "cafe") {
    return userText.includes("kawa")
      ? "Poproszę małą kawę, na miejscu."
      : "Chcę kawę i herbatę.";
  }

  if (scenarioId === "shop") {
    return userText.includes("szukam")
      ? "Szukam chleba i mleka."
      : "Poproszę dwa litry mleka.";
  }

  return userText.includes("prosto")
    ? "Idź prosto, potem w lewo."
    : "Dworzec jest blisko. Idź prosto.";
}

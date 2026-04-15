# Polly Word

PWA для изучения польского языка с четырьмя основными разделами:

- `Новые слова` — стартовый словарь польских слов с темами, переводом и примерами
- `Игра со словами` — карточки-стикеры, которые переворачиваются по клику
- `Архив слов` — изученные слова, повторение и мини-тест
- `Общение с ИИ` — учебный rule-based ассистент для диалога и исправления перевода

## Что уже реализовано

- мобильный интерфейс с нижней навигацией
- экран входа и регистрации
- локальный демо-режим без внешних ключей
- архитектура под `Supabase Auth` и таблицы прогресса
- сохранение прогресса, архива, повторений и чата
- `manifest.webmanifest` и `service worker` для PWA

## Быстрый запуск

В проекте нет обязательной сборки. Достаточно открыть статический сервер из корня:

```bash
python3 -m http.server 4173
```

Затем открыть [http://localhost:4173](http://localhost:4173).

Перед локальным запуском можно сгенерировать runtime-конфиг:

```bash
npm run build
```

## Подключение Supabase

По умолчанию приложение работает в локальном режиме и хранит данные в `localStorage`.
Чтобы перейти на `Supabase`, нужно:

1. Создать проект в Supabase.
2. Выполнить SQL из [supabase/schema.sql](/Users/dell/Documents/New%20project/supabase/schema.sql).
3. Затем выполнить seed из [supabase/seed.sql](/Users/dell/Documents/New%20project/supabase/seed.sql).
4. Перед деплоем или локальным запуском передать переменные окружения:

```bash
SUPABASE_URL=https://your-project.supabase.co \
SUPABASE_ANON_KEY=your-anon-key \
npm run build
```

После этого приложение попытается использовать `Supabase Auth`, подтянет слова из таблицы `words` и будет создавать запись в `profiles` при регистрации или входе. Если сеть или SDK недоступны, интерфейс автоматически останется в локальном режиме.

## Публикация в интернет

Самый простой путь сейчас — `Netlify` или `Vercel`.

### Netlify

1. Подключить репозиторий или загрузить проект.
2. Build command: `npm run build`
3. Publish directory: `.`
4. В переменные окружения добавить:
   `SUPABASE_URL`
   `SUPABASE_ANON_KEY`

### Vercel

1. Импортировать проект как `Other`.
2. Build command: `npm run build`
3. Output directory: `.`
4. В Environment Variables добавить:
   `SUPABASE_URL`
   `SUPABASE_ANON_KEY`

При каждом деплое будет автоматически генерироваться [config.local.js](/Users/dell/Documents/New%20project/config.local.js) с нужными значениями. Если переменные не заданы, приложение остается в локальном режиме, но все равно публикуется и работает.

## Структура

- [index.html](/Users/dell/Documents/New%20project/index.html) — каркас приложения
- [styles.css](/Users/dell/Documents/New%20project/styles.css) — визуальный стиль и адаптивность
- [src/app.js](/Users/dell/Documents/New%20project/src/app.js) — основная логика интерфейса
- [src/storage.js](/Users/dell/Documents/New%20project/src/storage.js) — local storage и адаптер под Supabase
- [src/tutor-service.js](/Users/dell/Documents/New%20project/src/tutor-service.js) — учебный ассистент
- [src/words-data.js](/Users/dell/Documents/New%20project/src/words-data.js) — стартовый словарь
- [sw.js](/Users/dell/Documents/New%20project/sw.js) — офлайн-кэш PWA

## Тесты

В репозитории подготовлены:

- `Playwright`-сценарии для регистрации, карточек, архива и чата
- `node:test`-тесты для логики прогресса и tutor-сервиса

В текущей среде у меня не было доступных `node`, `npm` и браузера Playwright, поэтому автоматический прогон был ограничен.

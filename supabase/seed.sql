insert into words (id, polish, russian, topic, level, example)
values
  ('dom-czesc', 'cześć', 'привет', 'Знакомство', 'A1', 'Cześć, miło cię widzieć.'),
  ('dom-dziekuje', 'dziękuję', 'спасибо', 'Знакомство', 'A1', 'Dziękuję za pomoc.'),
  ('dom-prosze', 'proszę', 'пожалуйста', 'Знакомство', 'A1', 'Proszę, usiądź tutaj.'),
  ('kawiarnia-kawa', 'kawa', 'кофе', 'Кафе', 'A1', 'Poproszę dużą kawę.'),
  ('kawiarnia-herbata', 'herbata', 'чай', 'Кафе', 'A1', 'Lubię zieloną herbatę.'),
  ('zakupy-sklep', 'sklep', 'магазин', 'Покупки', 'A1', 'Ten sklep jest blisko domu.'),
  ('zakupy-cena', 'cena', 'цена', 'Покупки', 'A1', 'Jaka jest cena tej książki?'),
  ('miasto-droga', 'droga', 'дорога', 'Город', 'A1', 'To jest długa droga do szkoły.'),
  ('miasto-dworzec', 'dworzec', 'вокзал', 'Город', 'A1', 'Dworzec jest po lewej stronie.'),
  ('codzienne-rano', 'rano', 'утром', 'Быт', 'A1', 'Rano piję kawę i czytam.'),
  ('codzienne-wieczor', 'wieczór', 'вечер', 'Быт', 'A1', 'Wieczór spędzam z rodziną.'),
  ('czas-dzisiaj', 'dzisiaj', 'сегодня', 'Время', 'A1', 'Dzisiaj mam lekcję polskiego.')
on conflict (id) do update
set
  polish = excluded.polish,
  russian = excluded.russian,
  topic = excluded.topic,
  level = excluded.level,
  example = excluded.example;

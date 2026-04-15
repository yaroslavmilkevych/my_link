create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  interface_language text not null default 'ru',
  created_at timestamptz not null default now()
);

create table if not exists words (
  id text primary key,
  polish text not null,
  russian text not null,
  topic text not null,
  level text not null,
  example text not null
);

create table if not exists user_word_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  word_id text not null references words(id) on delete cascade,
  status text not null check (status in ('new', 'learning', 'archived')),
  correct_answers integer not null default 0,
  last_reviewed_at timestamptz,
  primary key (user_id, word_id)
);

create table if not exists review_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  score integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('assistant', 'user')),
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table user_word_progress enable row level security;
alter table review_sessions enable row level security;
alter table chat_messages enable row level security;

create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id);

create policy "progress_own_all"
  on user_word_progress for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "review_sessions_own_all"
  on review_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "chat_messages_own_all"
  on chat_messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "words_read_all"
  on words for select
  using (true);

import { APP_STORAGE_KEY, SUPABASE_CONFIG } from "./config.js";
import { WORDS } from "./words-data.js";

const STORAGE_KEYS = {
  accounts: `${APP_STORAGE_KEY}:accounts`,
  session: `${APP_STORAGE_KEY}:session`,
  progress: `${APP_STORAGE_KEY}:progress`,
  reviews: `${APP_STORAGE_KEY}:reviews`,
  chats: `${APP_STORAGE_KEY}:chats`,
};

function readJson(key, fallback) {
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}

function writeJson(key, value) {
  window.localStorage.setItem(key, JSON.stringify(value));
}

class LocalAuthService {
  async register(email, password) {
    const accounts = readJson(STORAGE_KEYS.accounts, []);

    if (accounts.some((account) => account.email === email)) {
      throw new Error("Пользователь с таким email уже существует.");
    }

    const user = {
      id: `local-${crypto.randomUUID()}`,
      email,
      password,
      createdAt: new Date().toISOString(),
    };

    accounts.push(user);
    writeJson(STORAGE_KEYS.accounts, accounts);
    writeJson(STORAGE_KEYS.session, { userId: user.id, email: user.email });
    return sanitizeUser(user);
  }

  async login(email, password) {
    const accounts = readJson(STORAGE_KEYS.accounts, []);
    const user = accounts.find(
      (account) => account.email === email && account.password === password,
    );

    if (!user) {
      throw new Error("Неверный email или пароль.");
    }

    writeJson(STORAGE_KEYS.session, { userId: user.id, email: user.email });
    return sanitizeUser(user);
  }

  async logout() {
    window.localStorage.removeItem(STORAGE_KEYS.session);
  }

  async getCurrentUser() {
    const session = readJson(STORAGE_KEYS.session, null);

    if (!session?.userId) {
      return null;
    }

    const accounts = readJson(STORAGE_KEYS.accounts, []);
    const user = accounts.find((account) => account.id === session.userId);
    return user ? sanitizeUser(user) : null;
  }

  getModeLabel() {
    return "Локальный режим: данные аккаунта и прогресс сохраняются в браузере.";
  }
}

class LocalProgressRepository {
  async load(userId) {
    return readJson(`${STORAGE_KEYS.progress}:${userId}`, {});
  }

  async save(userId, progress) {
    writeJson(`${STORAGE_KEYS.progress}:${userId}`, progress);
  }
}

class LocalWordsRepository {
  async list() {
    return WORDS;
  }
}

class LocalReviewService {
  async list(userId) {
    return readJson(`${STORAGE_KEYS.reviews}:${userId}`, []);
  }

  async add(userId, review) {
    const reviews = readJson(`${STORAGE_KEYS.reviews}:${userId}`, []);
    reviews.unshift(review);
    writeJson(`${STORAGE_KEYS.reviews}:${userId}`, reviews);
    return reviews;
  }
}

class LocalChatRepository {
  async list(userId) {
    return readJson(`${STORAGE_KEYS.chats}:${userId}`, []);
  }

  async save(userId, messages) {
    writeJson(`${STORAGE_KEYS.chats}:${userId}`, messages);
  }
}

class SupabaseFacade {
  constructor(client) {
    this.client = client;
  }

  async register(email, password) {
    const { data, error } = await this.client.auth.signUp({ email, password });
    if (error) throw error;
    await this.ensureProfile(data.user);
    return sanitizeSupabaseUser(data.user);
  }

  async login(email, password) {
    const { data, error } = await this.client.auth.signInWithPassword({ email, password });
    if (error) throw error;
    await this.ensureProfile(data.user);
    return sanitizeSupabaseUser(data.user);
  }

  async logout() {
    await this.client.auth.signOut();
  }

  async getCurrentUser() {
    const { data } = await this.client.auth.getUser();
    await this.ensureProfile(data.user);
    return sanitizeSupabaseUser(data.user);
  }

  getModeLabel() {
    return "Supabase подключен: auth и прогресс синхронизируются между устройствами.";
  }

  async ensureProfile(user) {
    if (!user?.id || !user?.email) {
      return;
    }

    await this.client.from("profiles").upsert(
      {
        id: user.id,
        email: user.email,
        interface_language: "ru",
      },
      { onConflict: "id" },
    );
  }

  wordsRepository() {
    return {
      list: async () => {
        const { data, error } = await this.client
          .from("words")
          .select("*")
          .order("topic")
          .order("polish");

        if (error) {
          throw error;
        }

        return (data ?? []).map((row) => ({
          id: row.id,
          polish: row.polish,
          russian: row.russian,
          topic: row.topic,
          level: row.level,
          example: row.example,
        }));
      },
    };
  }

  progressRepository() {
    return {
      load: async (userId) => {
        const { data, error } = await this.client
          .from("user_word_progress")
          .select("*")
          .eq("user_id", userId);

        if (error) {
          throw error;
        }

        return Object.fromEntries(
          (data ?? []).map((row) => [
            row.word_id,
            {
              wordId: row.word_id,
              status: row.status,
              correctAnswers: row.correct_answers,
              lastReviewedAt: row.last_reviewed_at,
            },
          ]),
        );
      },
      save: async (userId, progress) => {
        const rows = Object.values(progress).map((item) => ({
          user_id: userId,
          word_id: item.wordId,
          status: item.status,
          correct_answers: item.correctAnswers,
          last_reviewed_at: item.lastReviewedAt,
        }));

        const { error } = await this.client
          .from("user_word_progress")
          .upsert(rows, { onConflict: "user_id,word_id" });

        if (error) {
          throw error;
        }
      },
    };
  }

  reviewService() {
    return {
      list: async (userId) => {
        const { data, error } = await this.client
          .from("review_sessions")
          .select("*")
          .eq("user_id", userId)
          .order("created_at", { ascending: false });

        if (error) {
          throw error;
        }

        return data ?? [];
      },
      add: async (userId, review) => {
        const payload = { ...review, user_id: userId };
        const { error } = await this.client.from("review_sessions").insert(payload);
        if (error) {
          throw error;
        }

        return this.reviewService().list(userId);
      },
    };
  }

  chatRepository() {
    return {
      list: async (userId) => {
        const { data, error } = await this.client
          .from("chat_messages")
          .select("*")
          .eq("user_id", userId)
          .order("created_at", { ascending: true });

        if (error) {
          throw error;
        }

        return (data ?? []).map((message) => ({
          id: message.id,
          role: message.role,
          title: message.title,
          body: message.body,
          createdAt: message.created_at,
        }));
      },
      save: async (userId, messages) => {
        const { error: deleteError } = await this.client
          .from("chat_messages")
          .delete()
          .eq("user_id", userId);

        if (deleteError) {
          throw deleteError;
        }

        if (messages.length === 0) {
          return;
        }

        const rows = messages.map((message) => ({
          user_id: userId,
          role: message.role,
          title: message.title,
          body: message.body,
          created_at: message.createdAt,
        }));
        const { error } = await this.client.from("chat_messages").insert(rows);
        if (error) {
          throw error;
        }
      },
    };
  }
}

function sanitizeUser(user) {
  return {
    id: user.id,
    email: user.email,
    createdAt: user.createdAt,
  };
}

function sanitizeSupabaseUser(user) {
  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    createdAt: user.created_at ?? new Date().toISOString(),
  };
}

export async function createServices() {
  const hasSupabaseConfig =
    SUPABASE_CONFIG.url.trim() !== "" && SUPABASE_CONFIG.anonKey.trim() !== "";

  if (!hasSupabaseConfig) {
    return {
      authService: new LocalAuthService(),
      wordsRepository: new LocalWordsRepository(),
      progressRepository: new LocalProgressRepository(),
      reviewService: new LocalReviewService(),
      chatRepository: new LocalChatRepository(),
      syncMode: "local",
    };
  }

  try {
    const { createClient } = await import(
      "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm"
    );
    const client = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
    const facade = new SupabaseFacade(client);

    return {
      authService: facade,
      wordsRepository: facade.wordsRepository(),
      progressRepository: facade.progressRepository(),
      reviewService: facade.reviewService(),
      chatRepository: facade.chatRepository(),
      syncMode: "supabase",
    };
  } catch {
    return {
      authService: new LocalAuthService(),
      wordsRepository: new LocalWordsRepository(),
      progressRepository: new LocalProgressRepository(),
      reviewService: new LocalReviewService(),
      chatRepository: new LocalChatRepository(),
      syncMode: "local",
    };
  }
}

const runtimeConfig =
  typeof window !== "undefined" && window.POLLY_WORD_CONFIG
    ? window.POLLY_WORD_CONFIG
    : {};

export const SUPABASE_CONFIG = {
  url: runtimeConfig.supabaseUrl ?? "",
  anonKey: runtimeConfig.supabaseAnonKey ?? "",
};

export const APP_STORAGE_KEY = "polly-word";

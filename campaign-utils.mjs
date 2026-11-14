export function normalizeJoinCode(value) {
  return String(value ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 10);
}

export function getErrorMessage(error, fallback = "Ocorreu um erro inesperado.") {
  if (error && typeof error.message === "string" && error.message.trim()) {
    return error.message.trim();
  }
  return fallback;
}

export function isValidCampaignName(value) {
  return typeof value === "string" && value.trim().length > 0 && value.trim().length <= 80;
}

import test from "node:test";
import assert from "node:assert/strict";
import { getErrorMessage, isValidCampaignName, normalizeJoinCode } from "../src/lib/campaign-utils.mjs";

test("normaliza código de convite sem aceitar caracteres inesperados", () => {
  assert.equal(normalizeJoinCode(" ab-cd 123! "), "ABCD123");
  assert.equal(normalizeJoinCode("123456789012"), "1234567890");
  assert.equal(normalizeJoinCode(null), "");
});

test("valida nome de campanha considerando espaços e limite", () => {
  assert.equal(isValidCampaignName("  Aventura  "), true);
  assert.equal(isValidCampaignName("   "), false);
  assert.equal(isValidCampaignName("a".repeat(81)), false);
});

test("extrai mensagem segura de erro e usa fallback", () => {
  assert.equal(getErrorMessage({ message: " Falha no banco " }), "Falha no banco");
  assert.equal(getErrorMessage({}, "Falha genérica"), "Falha genérica");
  assert.equal(getErrorMessage(null), "Ocorreu um erro inesperado.");
});

// stamp.ts: --stamp takes a language (bun test).
import { expect, test } from "bun:test";
import { stampLocales } from "./stamp";

const T = ["frFR", "deDE", "esES", "esMX"];

test("no --stamp stamps nothing", () => {
  expect(stampLocales(["--check"], T)).toEqual([]);
});

test("a language stamps that language only", () => {
  expect(stampLocales(["--stamp", "frFR"], T)).toEqual(["frFR"]);
  expect(stampLocales(["--stamp", "frFR", "esES", "--check"], T)).toEqual(["frFR", "esES"]);
});

test("a bare --stamp, an unknown language and a mixed 'all' are refused", () => {
  expect(stampLocales(["--stamp"], T)).toContain("takes a language");
  expect(stampLocales(["--check", "--stamp"], T)).toContain("takes a language");
  expect(stampLocales(["--stamp", "enUS"], T)).toContain("enUS is not a translated language");
  expect(stampLocales(["--stamp", "all", "frFR"], T)).toContain("stands alone");
});

test("'all' is every translated language, said", () => {
  expect(stampLocales(["--stamp", "all"], T)).toEqual(T);
});

import crypto from "node:crypto";

export function generateVerificationCode(): string {
  const value = crypto
    .randomBytes(4)
    .toString("hex")
    .toUpperCase();

  return `NDH-${value}`;
}

export function generateQrToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

export function buildVerificationUrl(
  verificationCode: string
): string {
  const base =
    process.env.NUSA_DHIPA_VERIFY_URL ||
    "http://localhost:3010/verify";

  return `${base}/${encodeURIComponent(
    verificationCode
  )}`;
}

export const VERIFICATION_STATUSES = [
  "unverified",
  "in_process",
  "verified",
  "suspended",
  "expired",
] as const;

export type VerificationStatus =
  (typeof VERIFICATION_STATUSES)[number];

export type LegalForm =
  | "none"
  | "pt_perorangan"
  | "cv"
  | "pt"
  | "koperasi"
  | "other";

export type LegalStatus =
  | "unregistered"
  | "in_process"
  | "registered";

export interface BusinessVerification {
  id: string;

  business_id: string;

  status: VerificationStatus;

  verification_level: "basic" | "legal";

  verified: boolean;

  business_name: string;

  legal_form: LegalForm;

  legal_status: LegalStatus;

  kbli_code: string | null;

  kbli_name: string | null;

  nib: string | null;

  ahu_number: string | null;

  verification_source:
    | "manual"
    | "document"
    | "oss"
    | "ahu"
    | "admin"
    | "system";

  verification_code: string;

  qr_token: string;

  public_url: string;

  verified_at: string | null;

  expires_at: string | null;

  verified_by: string | null;

  created_at: string;

  updated_at: string;
}

export interface PublicBusinessVerification {
  verification_code: string;

  status: "verified";

  verified: true;

  business_name: string;

  legal_form: LegalForm;

  legal_status: "registered";

  kbli_code: string | null;

  kbli_name: string | null;

  verified_at: string | null;

  public_url: string;
}

export function isVerified(
  verification: BusinessVerification | null | undefined
): boolean {
  return Boolean(
    verification &&
    verification.status === "verified" &&
    verification.verified === true
  );
}

export function getVerificationLabel(
  status: VerificationStatus
): string {
  switch (status) {
    case "verified":
      return "NUSA-DHIPA VERIFIED";

    case "in_process":
      return "LEGALITAS DALAM PROSES";

    case "suspended":
      return "VERIFIKASI DITANGGUHKAN";

    case "expired":
      return "VERIFIKASI KEDALUWARSA";

    default:
      return "BELUM TERVERIFIKASI";
  }
}

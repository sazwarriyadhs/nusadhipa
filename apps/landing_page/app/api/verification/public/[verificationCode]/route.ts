import { NextResponse } from "next/server";

export async function GET(
  _request: Request,
  {
    params,
  }: {
    params: Promise<{
      verificationCode: string;
    }>;
  }
) {
  const { verificationCode } = await params;

  if (!verificationCode) {
    return NextResponse.json(
      {
        success: false,
        message: "Verification code is required",
      },
      { status: 400 }
    );
  }

  /*
   * DATABASE INTEGRATION POINT
   *
   * Nanti query:
   *
   * SELECT
   *   verification_code,
   *   status,
   *   verified,
   *   business_name,
   *   legal_form,
   *   legal_status,
   *   kbli_code,
   *   kbli_name,
   *   verified_at,
   *   public_url
   * FROM public_business_verifications
   * WHERE verification_code = $1;
   *
   * Jangan expose NIB, AHU, NPWP,
   * identitas owner, alamat pribadi,
   * atau dokumen legal.
   */

  return NextResponse.json(
    {
      success: false,
      message:
        "Verification database integration is not connected yet",
      verification_code: verificationCode,
    },
    { status: 503 }
  );
}
import { NextResponse } from "next/server";

const API_BASE =
  process.env.NEXT_PUBLIC_MARKETPLACE_API_URL ||
  "http://localhost:8300";

export async function GET() {
  try {
    const response = await fetch(
      `${API_BASE}/api/v1/marketplace/businesses`,
      {
        cache: "no-store",
      }
    );

    const data = await response.json();

    return NextResponse.json(data, {
      status: response.status,
    });
  } catch {
    return NextResponse.json(
      {
        success: false,
        error: "Marketplace API unavailable",
      },
      { status: 503 }
    );
  }
}

import { NextResponse } from "next/server";

export async function GET() {
  const apiUrl =
    process.env.NUSA_DHIPA_API_URL ||
    "http://localhost:8300";

  const started = Date.now();

  try {
    const response = await fetch(
      `${apiUrl}/`,
      {
        cache: "no-store",
      }
    );

    return NextResponse.json({
      ok: response.ok,
      status: response.status,
      latency_ms: Date.now() - started,
      backend: apiUrl,
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        status: 0,
        latency_ms: Date.now() - started,
        backend: apiUrl,
        error:
          error instanceof Error
            ? error.message
            : "Unknown error",
      },
      {
        status: 503,
      }
    );
  }
}

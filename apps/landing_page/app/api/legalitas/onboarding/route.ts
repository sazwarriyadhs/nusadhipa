const LEGAL_URL =
  process.env.NUSA_DHIPA_LEGAL_URL ||
  "http://localhost:8327";

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const response = await fetch(
      `${LEGAL_URL}/api/v1/legal/public/setup-requests`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(body),
        cache: "no-store",
      }
    );

    const text = await response.text();

    let data: unknown;

    try {
      data = JSON.parse(text);
    } catch {
      data = {
        success: false,
        message: text || "Legal service returned invalid JSON",
      };
    }

    return Response.json(data, {
      status: response.status,
    });
  } catch (error) {
    return Response.json(
      {
        success: false,
        message: "Legal service unavailable",
        error:
          error instanceof Error
            ? error.message
            : "Unknown error",
      },
      {
        status: 502,
      }
    );
  }
}
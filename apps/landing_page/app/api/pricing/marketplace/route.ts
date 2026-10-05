import { readFile } from "node:fs/promises";
import path from "node:path";

export async function GET() {
  try {
    const filePath = path.join(
      process.cwd(),
      "..",
      "..",
      "..",
      "config",
      "pricing",
      "mobile_price.json"
    );

    const raw = await readFile(filePath, "utf8");
    const config = JSON.parse(raw);

    return Response.json({
      success: true,
      data: config,
    });
  } catch (error) {
    return Response.json(
      {
        success: false,
        message: "Pricing configuration unavailable",
        error:
          error instanceof Error
            ? error.message
            : "Unknown error",
      },
      { status: 500 }
    );
  }
}


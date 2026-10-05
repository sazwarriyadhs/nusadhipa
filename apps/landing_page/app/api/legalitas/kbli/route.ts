import { NextResponse } from "next/server";
import fs from "node:fs";
import path from "node:path";

type KbliRecord = {
  code: string;
  name: string;
  description: string;
  level: number;
};

type IntentProfile = {
  name: string;
  canonicalTerms: string[];
  synonyms: string[];
  negativeTerms: string[];
};

type ScoredKbliRecord = KbliRecord & {
  score: number;
  match_type: string;
  intent: string;
  matched_terms: string[];
};

const INTENTS: IntentProfile[] = [
  {
    name: "hair_barber",
    canonicalTerms: [
      "pangkas rambut",
      "penataan rambut",
      "potong rambut",
      "tata rambut",
      "pencukuran",
    ],
    synonyms: [
      "barber",
      "barbershop",
      "barber shop",
      "haircut",
      "hair cut",
      "hair salon",
      "salon rambut",
      "pangkas",
      "cukur rambut",
      "potong rambut",
      "potong",
      "cukur",
      "styling rambut",
      "stylist rambut",
    ],
    negativeTerms: [
      "mobil",
      "motor",
      "kendaraan",
      "car",
      "otomotif",
      "bengkel",
      "cuci mobil",
      "cuci motor",
    ],
  },

  {
    name: "beauty_salon",
    canonicalTerms: [
      "perawatan kecantikan",
      "salon kecantikan",
      "perawatan tubuh",
      "kecantikan",
    ],
    synonyms: [
      "salon",
      "beauty salon",
      "salon kecantikan",
      "beauty",
      "facial",
      "make up",
      "makeup",
      "rias",
      "perawatan wajah",
      "perawatan kulit",
      "skincare",
      "manicure",
      "pedicure",
    ],
    negativeTerms: [
      "mobil",
      "motor",
      "kendaraan",
      "otomotif",
      "bengkel",
    ],
  },
];

function cleanHeader(value: string): string {
  return value
    .replace(/^\uFEFF/, "")
    .replace(/^["']|["']$/g, "")
    .trim()
    .toLowerCase();
}

function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = "";
  let quoted = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      if (quoted && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        quoted = !quoted;
      }

      continue;
    }

    if (char === "," && !quoted) {
      result.push(current.trim());
      current = "";
      continue;
    }

    current += char;
  }

  result.push(current.trim());

  return result;
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function tokenize(value: string): string[] {
  return normalize(value)
    .split(" ")
    .filter((token) => token.length >= 3);
}

function codeLevel(code: string): number {
  const clean = code.trim();

  if (/^\d{5}$/.test(clean)) {
    return 5;
  }

  if (/^\d{4}$/.test(clean)) {
    return 4;
  }

  if (/^\d{3}$/.test(clean)) {
    return 3;
  }

  if (/^\d{2}$/.test(clean)) {
    return 2;
  }

  return 0;
}

function readKbli(): KbliRecord[] {
  const csvPath = path.resolve(
    process.cwd(),
    "..",
    "..",
    "data",
    "kbli",
    "kbli_2025.csv"
  );

  if (!fs.existsSync(csvPath)) {
    throw new Error(
      `KBLI dataset not found: ${csvPath}`
    );
  }

  const content = fs.readFileSync(
    csvPath,
    "utf8"
  );

  const lines = content
    .replace(/^\uFEFF/, "")
    .split(/\r?\n/)
    .filter(
      (line) => line.trim().length > 0
    );

  if (lines.length < 2) {
    return [];
  }

  const headers = parseCSVLine(lines[0])
    .map(cleanHeader);

  const codeIndex = headers.findIndex(
    (header) => header === "code"
  );

  const titleIndex = headers.findIndex(
    (header) => header === "title"
  );

  const descriptionIndex =
    headers.findIndex(
      (header) =>
        header === "description"
    );

  if (
    codeIndex === -1 ||
    titleIndex === -1
  ) {
    throw new Error(
      [
        "KBLI CSV columns not recognized.",
        `codeIndex=${codeIndex}`,
        `titleIndex=${titleIndex}`,
        `descriptionIndex=${descriptionIndex}`,
        `Headers: ${headers.join(", ")}`,
      ].join(" ")
    );
  }

  return lines
    .slice(1)
    .map((line) => {
      const columns =
        parseCSVLine(line);

      const code =
        (columns[codeIndex] || "")
          .replace(
            /^["']|["']$/g,
            ""
          )
          .trim();

      const name =
        (columns[titleIndex] || "")
          .replace(
            /^["']|["']$/g,
            ""
          )
          .trim();

      const description =
        descriptionIndex >= 0
          ? (columns[
              descriptionIndex
            ] || "")
              .replace(
                /^["']|["']$/g,
                ""
              )
              .trim()
          : "";

      return {
        code,
        name,
        description,
        level: codeLevel(code),
      };
    })
    .filter(
      (item) =>
        item.code.length > 0 &&
        item.name.length > 0
    );
}

function detectIntent(
  query: string
): {
  intent: IntentProfile | null;
  expandedTerms: string[];
  negativeTerms: string[];
} {
  const normalizedQuery =
    normalize(query);

  let bestIntent:
    | IntentProfile
    | null = null;

  let bestScore = 0;

  for (const intent of INTENTS) {
    let score = 0;

    for (const term of [
      ...intent.canonicalTerms,
      ...intent.synonyms,
    ]) {
      const normalizedTerm =
        normalize(term);

      if (
        normalizedQuery ===
        normalizedTerm
      ) {
        score += 100;
      } else if (
        normalizedQuery.includes(
          normalizedTerm
        )
      ) {
        score += 60;
      } else if (
        normalizedTerm.includes(
          normalizedQuery
        )
      ) {
        score += 25;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestIntent = intent;
    }
  }

  if (!bestIntent) {
    return {
      intent: null,
      expandedTerms: [],
      negativeTerms: [],
    };
  }

  return {
    intent: bestIntent,
    expandedTerms: [
      ...bestIntent.canonicalTerms,
      ...bestIntent.synonyms,
    ],
    negativeTerms:
      bestIntent.negativeTerms,
  };
}

function scoreRecord(
  record: KbliRecord,
  query: string,
  intent: IntentProfile | null,
  expandedTerms: string[],
  negativeTerms: string[]
): ScoredKbliRecord | null {
  const normalizedQuery =
    normalize(query);

  const title =
    normalize(record.name);

  const description =
    normalize(record.description);

  const text =
    `${title} ${description}`;

  const tokens =
    tokenize(query);

  let score = 0;

  let matchType =
    "token_match";

  const matchedTerms: string[] = [];

  /*
   * =========================================================
   * EXACT QUERY
   * =========================================================
   */

  if (
    title === normalizedQuery
  ) {
    score += 1200;
    matchType = "exact_title";
    matchedTerms.push(
      normalizedQuery
    );
  } else if (
    title.includes(
      normalizedQuery
    )
  ) {
    score += 850;
    matchType =
      "title_phrase";

    matchedTerms.push(
      normalizedQuery
    );
  }

  if (
    description.includes(
      normalizedQuery
    )
  ) {
    score += 250;

    if (
      matchType ===
      "token_match"
    ) {
      matchType =
        "description_phrase";
    }
  }

  /*
   * =========================================================
   * QUERY TOKENS
   * =========================================================
   */

  let titleTokenMatches = 0;

  for (const token of tokens) {
    if (title.includes(token)) {
      titleTokenMatches++;
      score += 180;

      matchedTerms.push(
        token
      );
    } else if (
      description.includes(
        token
      )
    ) {
      score += 8;
    }
  }

  if (
    tokens.length > 1 &&
    titleTokenMatches ===
      tokens.length
  ) {
    score += 300;

    if (
      matchType ===
      "token_match"
    ) {
      matchType =
        "all_title_tokens";
    }
  }

  /*
   * =========================================================
   * INTENT EXPANSION
   * =========================================================
   */

  if (intent) {
    let intentTitleHits = 0;
    let intentDescriptionHits = 0;

    for (
      const term of expandedTerms
    ) {
      const normalizedTerm =
        normalize(term);

      if (
        normalizedTerm.length < 3
      ) {
        continue;
      }

      if (
        title.includes(
          normalizedTerm
        )
      ) {
        intentTitleHits++;

        score += 90;

        if (
          !matchedTerms.includes(
            normalizedTerm
          )
        ) {
          matchedTerms.push(
            normalizedTerm
          );
        }
      } else if (
        description.includes(
          normalizedTerm
        )
      ) {
        intentDescriptionHits++;

        score += 25;
      }
    }

    if (
      intentTitleHits > 0
    ) {
      score += 180;
    }

    if (
      intentDescriptionHits >
      0
    ) {
      score += 20;
    }
  }

  /*
   * =========================================================
   * NEGATIVE CONTEXT
   * =========================================================
   */

  for (
    const negativeTerm of
      negativeTerms
  ) {
    const normalizedNegative =
      normalize(
        negativeTerm
      );

    if (
      text.includes(
        normalizedNegative
      )
    ) {
      score -= 500;

      if (
        title.includes(
          normalizedNegative
        )
      ) {
        score -= 400;
      }
    }
  }

  /*
   * =========================================================
   * KBLI SPECIFICITY
   * =========================================================
   */

  if (
    record.level === 5
  ) {
    score += 80;
  } else if (
    record.level === 4
  ) {
    score += 35;
  } else if (
    record.level === 3
  ) {
    score += 15;
  } else if (
    record.level === 2
  ) {
    score += 5;
  }

  /*
   * =========================================================
   * DESCRIPTION-ONLY NOISE GUARD
   * =========================================================
   */

  if (
    titleTokenMatches === 0 &&
    !title.includes(
      normalizedQuery
    ) &&
    !intent
  ) {
    if (
      !description.includes(
        normalizedQuery
      )
    ) {
      return null;
    }
  }

  /*
   * =========================================================
   * FINAL RELEVANCE GUARD
   * =========================================================
   */

  const hasQueryMatch =
    title.includes(
      normalizedQuery
    ) ||
    description.includes(
      normalizedQuery
    ) ||
    titleTokenMatches > 0;

  const hasIntentMatch =
    intent !== null &&
    expandedTerms.some(
      (term) => {
        const normalizedTerm =
          normalize(term);

        return (
          title.includes(
            normalizedTerm
          ) ||
          description.includes(
            normalizedTerm
          )
        );
      }
    );

  if (
    !hasQueryMatch &&
    !hasIntentMatch
  ) {
    return null;
  }

  if (score <= 0) {
    return null;
  }

  if (
    matchType ===
      "token_match" &&
    intent
  ) {
    matchType =
      "intent_match";
  }

  return {
    ...record,
    score,
    match_type: matchType,
    intent:
      intent?.name ||
      "general",
    matched_terms:
      [...new Set(
        matchedTerms
      )],
  };
}

export async function GET(
  request: Request
) {
  const { searchParams } =
    new URL(request.url);

  const query =
    searchParams
      .get("q")
      ?.trim() || "";

  const requestedLimit =
    Number(
      searchParams.get(
        "limit"
      ) || "10"
    );

  const limit =
    Number.isFinite(
      requestedLimit
    )
      ? Math.min(
          Math.max(
            requestedLimit,
            1
          ),
          20
        )
      : 10;

  if (query.length < 2) {
    return NextResponse.json({
      success: true,
      data: {
        items: [],
        total: 0,
        query,
        limit,
        intent: null,
      },
    });
  }

  try {
    const records =
      readKbli();

    const {
      intent,
      expandedTerms,
      negativeTerms,
    } =
      detectIntent(query);

    const scored =
      records
        .map((record) =>
          scoreRecord(
            record,
            query,
            intent,
            expandedTerms,
            negativeTerms
          )
        )
        .filter(
          (
            record
          ): record is ScoredKbliRecord =>
            record !== null
        )
        .sort((a, b) => {
          if (
            b.score !== a.score
          ) {
            return (
              b.score -
              a.score
            );
          }

          if (
            b.level !==
            a.level
          ) {
            return (
              b.level -
              a.level
            );
          }

          return a.name.localeCompare(
            b.name,
            "id"
          );
        })
        .slice(0, limit);

    return NextResponse.json({
      success: true,
      data: {
        items: scored.map(
          (record) => ({
            code:
              record.code,

            name:
              record.name,

            description:
              record.description,

            level:
              record.level,

            score:
              record.score,

            match_type:
              record.match_type,

            intent:
              record.intent,

            matched_terms:
              record.matched_terms,
          })
        ),

        total:
          scored.length,

        query,

        limit,

        intent:
          intent?.name ||
          "general",
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        success: false,

        message:
          "KBLI dataset unavailable",

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
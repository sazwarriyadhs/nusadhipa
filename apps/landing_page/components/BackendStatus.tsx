"use client";

import { useEffect, useState } from "react";

type Health = {
  ok: boolean;
  latency_ms?: number;
};

export default function BackendStatus() {
  const [health, setHealth] = useState<Health | null>(null);

  useEffect(() => {
    let mounted = true;

    const check = async () => {
      try {
        const response = await fetch("/api/health", {
          cache: "no-store",
        });

        const data = await response.json();

        if (mounted) {
          setHealth(data);
        }
      } catch {
        if (mounted) {
          setHealth({
            ok: false,
          });
        }
      }
    };

    check();

    const timer = setInterval(check, 10000);

    return () => {
      mounted = false;
      clearInterval(timer);
    };
  }, []);

  if (!health) {
    return (
      <span className="inline-flex items-center gap-2 text-xs font-bold text-[#68707d]">
        <span className="h-2 w-2 rounded-full bg-[#cfd3d9]" />
        Connecting...
      </span>
    );
  }

  if (!health.ok) {
    return (
      <span className="inline-flex items-center gap-2 text-xs font-bold text-[#c91621]">
        <span className="h-2 w-2 rounded-full bg-[#c91621]" />
        Backend Offline
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-2 text-xs font-bold text-[#202329]">
      <span className="h-2 w-2 rounded-full bg-green-500" />
      NUSA-DHIPA Online
      {typeof health.latency_ms === "number" && (
        <span className="text-[#68707d]">
          · {health.latency_ms}ms
        </span>
      )}
    </span>
  );
}

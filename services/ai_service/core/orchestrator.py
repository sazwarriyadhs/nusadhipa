from typing import Any, Dict, List
import json

from core.config import normalize_business_type
from core.llm_provider import OllamaProvider
from router.agent_router import resolve_agents


class CopilotOrchestrator:
    def __init__(self):
        self.llm = OllamaProvider()

    def resolve(
        self,
        business_type: str,
        capabilities: List[str],
    ) -> Dict[str, Any]:
        mode = normalize_business_type(business_type)

        agents = resolve_agents(
            business_type=mode,
            capabilities=capabilities,
        )

        return {
            "business_mode": mode,
            "agents": agents,
        }

    def _build_prompt(
        self,
        business_mode: str,
        agents: List[str],
        message: str,
        context: Dict[str, Any],
        business_id: str | None = None,
        kbli_code: str | None = None,
        kbli_name: str | None = None,
    ) -> str:
        context_json = json.dumps(
            context or {},
            ensure_ascii=False,
            default=str,
        )

        return f"""
Anda adalah AI Copilot untuk UMKM.

Jawab dalam Bahasa Indonesia.
Berikan jawaban praktis, singkat, dan langsung ke inti.
Gunakan hanya data yang tersedia.
Jangan mengarang angka atau data bisnis.
Jika data tidak tersedia, katakan dengan jelas.
Jangan mengklaim melakukan tindakan yang belum dilakukan.

MODE BISNIS:
{business_mode}

KBLI:
{kbli_code or "-"} - {kbli_name or "-"}

AGENT:
{", ".join(agents)}

DATA BISNIS:
{context_json}

PERTANYAAN:
{message}

Berikan maksimal 5 poin.
""".strip()

    def run(
        self,
        business_type: str,
        capabilities: List[str],
        message: str,
        intent: str | None = None,
        context: Dict[str, Any] | None = None,
        business_id: str | None = None,
        kbli_code: str | None = None,
        kbli_name: str | None = None,
    ) -> Dict[str, Any]:
        context = context or {}

        resolved = self.resolve(
            business_type=business_type,
            capabilities=capabilities,
        )

        business_mode = resolved["business_mode"]
        agents = resolved["agents"]

        prompt = self._build_prompt(
            business_mode=business_mode,
            agents=agents,
            message=message,
            context=context,
            business_id=business_id,
            kbli_code=kbli_code,
            kbli_name=kbli_name,
        )

        llm_connected = self.llm.health()

        if not llm_connected:
            return {
                "business_mode": business_mode,
                "intent": intent or "general",
                "agents": agents,
                "response": (
                    f"AI Copilot aktif untuk business mode "
                    f"'{business_mode}'. "
                    f"Agent yang tersedia: {', '.join(agents)}. "
                    "Ollama belum terhubung."
                ),
                "data": {
                    "context_received": bool(context),
                    "llm_connected": False,
                    "llm_provider": "ollama",
                    "model": self.llm.model,
                },
            }

        try:
            result = self.llm.generate(prompt)

            response_text = result.get("response", "").strip()

            if not response_text:
                response_text = (
                    "AI engine terhubung, tetapi belum menghasilkan jawaban."
                )

            return {
                "business_mode": business_mode,
                "intent": intent or "general",
                "agents": agents,
                "response": response_text,
                "data": {
                    "context_received": bool(context),
                    "llm_connected": True,
                    "llm_provider": "ollama",
                    "model": result.get("model", self.llm.model),
                    "done": result.get("done", False),
                    "total_duration": result.get("total_duration"),
                    "eval_count": result.get("eval_count"),
                },
            }

        except Exception as error:
            return {
                "business_mode": business_mode,
                "intent": intent or "general",
                "agents": agents,
                "response": (
                    "AI Copilot berhasil menentukan business mode dan agent, "
                    "tetapi terjadi masalah ketika menghubungi model AI. "
                    "Silakan coba kembali."
                ),
                "data": {
                    "context_received": bool(context),
                    "llm_connected": True,
                    "llm_provider": "ollama",
                    "model": self.llm.model,
                    "llm_error": str(error),
                },
            }

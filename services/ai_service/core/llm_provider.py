from typing import Any, Dict, Optional

import httpx


class OllamaProvider:
    def __init__(
        self,
        base_url: str = "http://localhost:11434",
        model: str = "qwen3:1.7b",
        timeout: float = 90.0,
    ):
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.timeout = timeout

    def health(self) -> bool:
        try:
            response = httpx.get(
                f"{self.base_url}/api/tags",
                timeout=5.0,
            )
            return response.status_code == 200
        except Exception:
            return False

    def generate(
        self,
        prompt: str,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        selected_model = model or self.model

        payload = {
            "model": selected_model,
            "prompt": prompt,
            "stream": False,
            "think": False,
            "options": {
                "temperature": 0.2,
                "num_predict": 128,
            },
        }

        response = httpx.post(
            f"{self.base_url}/api/generate",
            json=payload,
            timeout=self.timeout,
        )

        response.raise_for_status()

        data = response.json()

        return {
            "response": data.get("response", "").strip(),
            "model": data.get("model", selected_model),
            "done": data.get("done", False),
            "total_duration": data.get("total_duration"),
            "eval_count": data.get("eval_count"),
        }

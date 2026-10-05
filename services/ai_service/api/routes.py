from fastapi import APIRouter, Header, HTTPException

from core.business_context import BusinessContextResolver
from core.orchestrator import CopilotOrchestrator
from models.requests import CopilotRequest, CopilotResponse


router = APIRouter(
    prefix="/api/v1/ai",
    tags=["AI Copilot"],
)

orchestrator = CopilotOrchestrator()
context_resolver = BusinessContextResolver()


@router.get("/status")
def ai_status():
    llm_connected = orchestrator.llm.health()

    return {
        "service": "nusa-dhipa-ai",
        "status": "ready",
        "engine": "universal-copilot",
        "llm_provider": "ollama",
        "llm_connected": llm_connected,
        "model": orchestrator.llm.model,
    }


@router.post(
    "/copilot",
    response_model=CopilotResponse,
)
def copilot(
    request: CopilotRequest,
    authorization: str | None = Header(
        default=None,
    ),
):
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Authorization header is required",
        )

    try:
        business_context = context_resolver.resolve(
            business_id=request.business_id,
            authorization=authorization,
        )
    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail=(
                "Failed to resolve business context: "
                f"{error}"
            ),
        ) from error

    business = business_context.get(
        "business",
        {},
    )

    capabilities = business_context.get(
        "capabilities",
        [],
    )

    result = orchestrator.run(
        business_type=business.get(
            "business_type",
            "general",
        ),
        capabilities=capabilities,
        message=request.message,
        intent=request.intent,
        context=business_context,
        business_id=request.business_id,
        kbli_code=business.get("kbli_code"),
        kbli_name=business.get("kbli_name"),
    )

    return {
        "success": True,
        **result,
    }

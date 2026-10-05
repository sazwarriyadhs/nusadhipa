from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class CopilotRequest(BaseModel):
    business_id: str

    message: str = Field(
        min_length=1,
        max_length=12000,
    )

    # Deprecated client hints.
    # AI tidak menganggap field ini sebagai sumber authoritative.
    business_type: Optional[str] = None
    kbli_code: Optional[str] = None
    kbli_name: Optional[str] = None
    capabilities: List[str] = Field(
        default_factory=list
    )
    intent: Optional[str] = None

    # Deprecated client context.
    # Context aktual akan diambil server-side.
    context: Dict[str, Any] = Field(
        default_factory=dict
    )


class CopilotResponse(BaseModel):
    success: bool
    business_mode: str
    intent: str
    agents: List[str]
    response: str
    data: Dict[str, Any] = Field(
        default_factory=dict
    )

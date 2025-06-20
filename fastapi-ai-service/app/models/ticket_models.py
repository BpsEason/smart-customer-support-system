from pydantic import BaseModel
from typing import Optional

class TicketAnalysisRequest(BaseModel):
    ticket_id: int
    message: str
    customer_id: Optional[int] = None
    existing_ticket_status: Optional[str] = 'pending' # Current status of the ticket

class TicketAnalysisResponse(BaseModel):
    ticket_id: int
    sentiment: str
    sentiment_confidence: float
    intent: str
    intent_confidence: float
    ai_reply: Optional[str] = None
    suggested_agent_id: Optional[int] = None # Suggested agent ID for dispatch
    suggested_priority: Optional[str] = None # Suggested priority: low, normal, high, urgent
    knowledge_base_answer: Optional[str] = None # Answer found in KB if any

class TicketDispatchResponse(BaseModel):
    ticket_id: int
    intent: str
    intent_confidence: float
    sentiment: str
    sentiment_confidence: float
    suggested_agent_id: Optional[int] = None
    suggested_priority: Optional[str] = None

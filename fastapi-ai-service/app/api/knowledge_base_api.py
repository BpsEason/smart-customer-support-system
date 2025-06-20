from fastapi import APIRouter, status
from pydantic import BaseModel
import logging
from typing import List, Dict, Any
from app.services.knowledge_base_service import knowledge_base_service # 導入服務實例
from app.services.exceptions import InvalidInputError, APIException, ResourceNotFoundError

router = APIRouter()
logger = logging.getLogger(__name__)

class KnowledgeSearchRequest(BaseModel):
    query: str
    top_n: int = 3

class KnowledgeMatch(BaseModel):
    id: int
    question: str
    answer: str
    score: float

class KnowledgeSearchResponse(BaseModel):
    matches: List[KnowledgeMatch]

@router.post("/", response_model=KnowledgeSearchResponse)
async def get_knowledge_recommendations(request: KnowledgeSearchRequest):
    """
    分析客戶問題，從知識庫中查找最相關的 FAQ 或解決方案。
    """
    if not request.query or not request.query.strip():
        raise InvalidInputError(detail="Query text cannot be empty or just whitespace.")
    if request.top_n <= 0:
        raise InvalidInputError(detail="top_n must be a positive integer.")

    try:
        matches = knowledge_base_service.search_knowledge_base(request.query, request.top_n)
        return KnowledgeSearchResponse(matches=matches)
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Unexpected error in knowledge base API.")
        raise APIException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, message="Failed to search knowledge base.", code="KB_SEARCH_ERROR")

@router.post("/refresh", status_code=status.HTTP_200_OK)
async def refresh_knowledge_base():
    """
    Refresh (reload and re-vectorize) the knowledge base.
    This can be used after updating the knowledge_base.json file.
    """
    try:
        knowledge_base_service.refresh_knowledge_base()
        return {"message": "Knowledge base refreshed successfully."}
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Failed to refresh knowledge base.")
        raise APIException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, message="Failed to refresh knowledge base.", code="KB_REFRESH_ERROR")

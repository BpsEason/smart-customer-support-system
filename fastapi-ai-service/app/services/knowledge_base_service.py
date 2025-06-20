import os
import json
import logging
from typing import Optional, List, Dict

logger = logging.getLogger(__name__)

class KnowledgeBaseService:
    def __init__(self):
        self.kb_path = os.getenv("KNOWLEDGE_BASE_PATH", "/app/knowledge_data/knowledge_base.json")
        self.knowledge_base_data: List[Dict] = []
        self.load_knowledge_base()

    def load_knowledge_base(self):
        """Loads the knowledge base from a JSON file."""
        try:
            if os.path.exists(self.kb_path):
                with open(self.kb_path, 'r', encoding='utf-8') as f:
                    self.knowledge_base_data = json.load(f)
                logger.info(f"Knowledge base loaded successfully from {self.kb_path} with {len(self.knowledge_base_data)} entries.")
            else:
                logger.warning(f"Knowledge base file not found at {self.kb_path}. Please ensure it's copied to the volume.")
                self.knowledge_base_data = []
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding knowledge base JSON from {self.kb_path}: {e}")
            self.knowledge_base_data = []
        except Exception as e:
            logger.error(f"Error loading knowledge base from {self.kb_path}: {e}")
            self.knowledge_base_data = []

    def is_kb_loaded(self):
        return len(self.knowledge_base_data) > 0

    def search_knowledge_base(self, query: str, intent: Optional[str] = None) -> Optional[str]:
        """
        Searches the knowledge base for a relevant answer based on the query and optional intent.
        This is a very simple keyword-based search. For production, consider using
        vector embeddings, Elasticsearch, or a proper RAG (Retrieval-Augmented Generation) system.
        """
        if not self.is_kb_loaded():
            return None

        # Normalize query for search
        query_lower = query.lower()

        # Prioritize exact intent match if provided
        if intent and intent != "unknown":
            for entry in self.knowledge_base_data:
                if entry.get("intent_keyword", "").lower() == intent.lower():
                    logger.info(f"KB match by intent '{intent}' for query: '{query}'")
                    return entry.get("answer")

        # Fallback to keyword search across questions/keywords
        for entry in self.knowledge_base_data:
            keywords = [entry.get("question", "").lower()] + [kw.lower() for kw in entry.get("keywords", [])]
            for keyword in keywords:
                if keyword in query_lower or query_lower in keyword:
                    logger.info(f"KB match by keyword '{keyword}' for query: '{query}'")
                    return entry.get("answer")

        return None

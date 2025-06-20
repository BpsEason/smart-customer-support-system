import logging
import json
import os
from typing import List, Dict, Any, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from app.services.exceptions import ModelLoadingError, PredictionError, ResourceNotFoundError

logger = logging.getLogger(__name__)

class KnowledgeBaseService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(KnowledgeBaseService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.kb_path = os.getenv("KNOWLEDGE_BASE_PATH", "/app/data/knowledge_base.json")
            self.knowledge_base_data: List[Dict[str, Any]] = []
            self.vectorizer = None
            self.kb_vectors = None
            self._load_and_process_knowledge_base()
            self._is_initialized = True

    def _load_and_process_knowledge_base(self):
        """
        Load knowledge base data from JSON and vectorize it.
        This method handles initial loading and can be extended for refresh logic.
        """
        try:
            if not os.path.exists(self.kb_path):
                # 如果文件不存在，可以選擇創建一個空文件或拋出錯誤
                logger.warning(f"Knowledge base file not found at {self.kb_path}. Creating an empty one.")
                os.makedirs(os.path.dirname(self.kb_path), exist_ok=True)
                with open(self.kb_path, 'w', encoding='utf-8') as f:
                    json.dump([], f, ensure_ascii=False, indent=4)
                self.knowledge_base_data = [] # 確保數據為空列表
                return
            
            with open(self.kb_path, 'r', encoding='utf-8') as f:
                self.knowledge_base_data = json.load(f)
            
            if not self.knowledge_base_data:
                logger.warning("Knowledge base data is empty. Search functionality will return no matches.")
                return

            # 使用問題和關鍵詞來訓練向量器
            texts_to_vectorize = [item['question'] + " ".join(item.get('keywords', [])) for item in self.knowledge_base_data]
            
            self.vectorizer = TfidfVectorizer()
            self.kb_vectors = self.vectorizer.fit_transform(texts_to_vectorize)
            logger.info(f"Knowledge base loaded and vectorized successfully from {self.kb_path}.")

        except json.JSONDecodeError as e:
            logger.error(f"Error decoding knowledge base JSON from {self.kb_path}: {e}. Please check file format.")
            raise ModelLoadingError(model_name="Knowledge Base", detail=f"Invalid JSON format: {e}")
        except Exception as e:
            logger.error(f"Unexpected error loading knowledge base from {self.kb_path}: {e}")
            raise ModelLoadingError(model_name="Knowledge Base", detail=f"Loading failed: {e}")

    def search_knowledge_base(self, query: str, top_n: int = 3) -> List[Dict[str, Any]]:
        """
        Searches the knowledge base for the most relevant answers based on query.
        """
        if not self.knowledge_base_data:
            logger.info("Knowledge base is empty, returning no matches.")
            return []
        if not self.vectorizer or self.kb_vectors is None:
            # 如果因為某些原因模型未初始化，嘗試重新加載
            logger.warning("Knowledge base vectorizer or vectors not initialized. Attempting to reload.")
            self._load_and_process_knowledge_base()
            if not self.vectorizer or self.kb_vectors is None: # 如果重新加載仍然失敗
                raise ModelLoadingError(model_name="Knowledge Base Search", detail="Knowledge base system not ready.")
        
        if not query.strip():
            logger.warning("Query for knowledge base search is empty, returning no matches.")
            return []

        try:
            query_vector = self.vectorizer.transform([query])
            similarities = cosine_similarity(query_vector, self.kb_vectors).flatten()
            
            # 根據相似度排序
            sorted_indices = similarities.argsort()[::-1]
            
            matches = []
            for idx in sorted_indices:
                score = float(similarities[idx])
                # 設定一個相似度閾值，可調，避免返回不相關的結果
                if score > 0.2: 
                    item = self.knowledge_base_data[idx]
                    matches.append({
                        "id": item['id'],
                        "question": item['question'],
                        "answer": item['answer'],
                        "score": round(score, 4)
                    })
                if len(matches) >= top_n:
                    break
            
            logger.debug(f"Knowledge base search for '{query}': found {len(matches)} matches.")
            return matches
        except Exception as e:
            raise PredictionError(model_name="Knowledge Base Search", detail=f"Search failed: {e}")

    def refresh_knowledge_base(self):
        """
        Refreshes the knowledge base by reloading data and re-vectorizing.
        This could be called periodically or via an admin API endpoint.
        """
        logger.info("Refreshing knowledge base...")
        self.knowledge_base_data = [] # Clear existing data
        self.vectorizer = None
        self.kb_vectors = None
        self._load_and_process_knowledge_base()
        logger.info("Knowledge base refresh complete.")

# 實例化服務 (單例模式)
knowledge_base_service = KnowledgeBaseService()

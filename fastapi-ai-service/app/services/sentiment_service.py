import os
import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
from typing import Tuple
import logging
from app.utils.model_loader import load_model_from_path

logger = logging.getLogger(__name__)

class SentimentService:
    def __init__(self):
        self.model_path = os.getenv("MODEL_PATH_SENTIMENT", "/app/models_data/trained_sentiment_model.joblib")
        self.pipeline = None
        self.sentiment_labels = []
        self.load_model()

    def is_model_loaded(self):
        return self.pipeline is not None and len(self.sentiment_labels) > 0

    def _train_and_save_model(self, texts: list, labels: list, output_path: str):
        """
        Internal method to train and save a simple sentiment analysis model.
        This is for initial setup/demonstration. In a real scenario, training would be
        more sophisticated and done offline.
        """
        logger.info("Training sentiment model...")
        if not texts or not labels or len(texts) != len(labels):
            logger.error("Invalid training data provided for sentiment model.")
            return

        # Simple pipeline for text classification
        pipeline = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=1000)),
            ('clf', LinearSVC()) # Linear Support Vector Classification
        ])

        pipeline.fit(texts, labels)
        joblib.dump(pipeline, output_path)
        self.pipeline = pipeline
        self.sentiment_labels = pipeline.named_steps.clf.classes_.tolist()
        logger.info(f"Sentiment model trained and saved to {output_path}")

    def analyze_sentiment(self, text: str) -> Tuple[str, float]:
        """Analyzes the sentiment of a given text."""
        if not self.is_model_loaded():
            return "neutral", 0.0 # Default to neutral if model not loaded

        try:
            # Predict the class index
            predicted_idx = self.pipeline.predict([text])[0]
            sentiment = self.sentiment_labels[predicted_idx]

            # Get decision function scores for confidence
            decision_scores = self.pipeline.decision_function([text])
            confidence = 0.0
            if len(decision_scores[0]) == 1: # Binary classification
                 confidence = float(1 / (1 + np.exp(-decision_scores[0][0]))) # Sigmoid for binary SVM
            else: # Multi-class classification
                 confidence = float(np.max(decision_scores)) # Max score for multi-class

            # Further normalize or map confidence if needed
            return sentiment, confidence
        except Exception as e:
            logger.error(f"Error analyzing sentiment for text '{text}': {e}")
            return "neutral", 0.0

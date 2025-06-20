import os
import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
from typing import Tuple, Dict
import logging
from app.utils.model_loader import load_model_from_path

logger = logging.getLogger(__name__)

class ChatbotService:
    def __init__(self):
        self.model_path = os.getenv("MODEL_PATH_CHATBOT", "/app/models_data/trained_chatbot_model.joblib")
        self.pipeline = None
        self.intent_labels = []
        self.load_model()
        self.rule_based_replies = self._load_rule_based_replies()

    def load_model(self):
        """Loads the chatbot model from the specified path."""
        try:
            # For demonstration, we'll try to load, but it might not exist initially
            self.pipeline = load_model_from_path(self.model_path)
            # Assuming the pipeline's last step (LinearSVC) has a classes_ attribute
            if hasattr(self.pipeline.named_steps.clf, 'classes_'):
                self.intent_labels = self.pipeline.named_steps.clf.classes_.tolist()
            logger.info(f"Chatbot model loaded successfully from {self.model_path}")
        except FileNotFoundError:
            logger.warning(f"Chatbot model file not found at {self.model_path}. Model will be trained on first run or needs manual training.")
            self.pipeline = None
            self.intent_labels = []
        except Exception as e:
            logger.error(f"Error loading chatbot model from {self.model_path}: {e}")
            self.pipeline = None
            self.intent_labels = []

    def is_model_loaded(self):
        return self.pipeline is not None and len(self.intent_labels) > 0

    def _train_and_save_model(self, texts: list, labels: list, output_path: str):
        """
        Internal method to train and save a simple chatbot intent recognition model.
        This is for initial setup/demonstration. In a real scenario, training would be
        more sophisticated and done offline.
        """
        logger.info("Training chatbot model...")
        if not texts or not labels or len(texts) != len(labels):
            logger.error("Invalid training data provided for chatbot model.")
            return

        # Simple pipeline for text classification
        pipeline = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=1000)),
            ('clf', LinearSVC()) # Linear Support Vector Classification
        ])

        pipeline.fit(texts, labels)
        joblib.dump(pipeline, output_path)
        self.pipeline = pipeline
        self.intent_labels = pipeline.named_steps.clf.classes_.tolist()
        logger.info(f"Chatbot model trained and saved to {output_path}")

    def predict_intent(self, message: str) -> Tuple[str, float]:
        """Predicts the intent of a given message."""
        if not self.is_model_loaded():
            # Fallback for when model is not loaded
            return "unknown", 0.0 # Default to unknown intent

        try:
            prediction_proba = self.pipeline.decision_function([message]) # Get scores for each class
            predicted_idx = np.argmax(prediction_proba)
            intent = self.intent_labels[predicted_idx]
            confidence = float(np.max(prediction_proba)) # Use max score as confidence

            # Normalize confidence if needed, or use a threshold
            # For LinearSVC, higher score means higher confidence for that class
            # A more robust confidence would involve Platt scaling or probability calibration
            if confidence < 0: # If score is negative, implies low confidence
                confidence = 0.0

            return intent, confidence
        except Exception as e:
            logger.error(f"Error predicting intent for message '{message}': {e}")
            return "unknown", 0.0

    def _load_rule_based_replies(self) -> Dict[str, str]:
        """
        Loads simple rule-based replies based on detected intents.
        In a real system, this would be more complex, potentially drawing from a database
        or more advanced NLU.
        """
        return {
            "greeting": "Hello! How can I assist you today?",
            "password_reset": "To reset your password, please visit our website and click on 'Forgot Password'.",
            "order_status": "Please provide your order number, and I'll check its status for you.",
            "technical_support": "For technical issues, please describe your problem in detail, and I will try to help or connect you with a specialist.",
            "billing_inquiry": "For billing inquiries, please provide your account details. You can also check your billing history in your account portal.",
            "product_inquiry": "What product are you interested in? I can provide more details.",
            "thanks": "You're welcome! Is there anything else I can help you with?",
            "goodbye": "Goodbye! Have a great day.",
            "unknown": "I'm sorry, I don't understand. Could you please rephrase your question or provide more details?",
            # Add more intents and their replies here
        }

    def get_reply(self, intent: str, original_message: str) -> str:
        """Retrieves a reply based on the detected intent."""
        # Prioritize knowledge base answers if applicable (handled in main.py)
        # For now, just return rule-based replies
        reply = self.rule_based_replies.get(intent, self.rule_based_replies["unknown"])

        # Add some dynamic elements based on original message if needed
        # e.g., if "order_status" intent, extract order number from original_message

        return reply

    def get_all_intents(self) -> list:
        """Returns a list of all supported intents."""
        return list(self.rule_based_replies.keys())

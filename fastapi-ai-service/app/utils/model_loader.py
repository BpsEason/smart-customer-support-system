import joblib
import os
import logging

logger = logging.getLogger(__name__)

def load_model_from_path(model_path: str):
    """
    Loads a machine learning model from a given file path using joblib.
    Raises FileNotFoundError if the file does not exist.
    """
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")
    
    try:
        model = joblib.load(model_path)
        logger.info(f"Model loaded successfully from {model_path}")
        return model
    except Exception as e:
        logger.error(f"Error loading model from {model_path}: {e}")
        raise

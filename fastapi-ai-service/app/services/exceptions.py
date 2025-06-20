from fastapi import HTTPException

class APIException(HTTPException):
    """Base custom exception for API errors."""
    def __init__(self, status_code: int, message: str, code: str = "API_ERROR"):
        super().__init__(status_code=status_code, detail=message)
        self.message = message
        self.code = code

class ModelLoadingError(APIException):
    def __init__(self, model_name: str = "AI Model", detail: str = "Failed to load model."):
        super().__init__(status_code=500, message=f"{model_name} loading error: {detail}", code="MODEL_LOAD_ERROR")

class PredictionError(APIException):
    def __init__(self, model_name: str = "AI Model", detail: str = "Failed to make prediction."):
        super().__init__(status_code=500, message=f"{model_name} prediction error: {detail}", code="PREDICTION_ERROR")

class InvalidInputError(APIException):
    def __init__(self, detail: str = "Invalid input provided."):
        super().__init__(status_code=400, message=f"Invalid input: {detail}", code="INVALID_INPUT")

class ResourceNotFoundError(APIException):
    def __init__(self, resource_name: str = "Resource", detail: str = "Not found."):
        super().__init__(status_code=404, message=f"{resource_name} not found: {detail}", code="RESOURCE_NOT_FOUND")

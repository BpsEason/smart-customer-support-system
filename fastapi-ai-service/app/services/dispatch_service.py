import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

class DispatchService:
    def __init__(self):
        # In a real application, agent IDs would come from a database.
        # For this example, we'll use placeholder IDs and a simple mapping.
        self.agent_skills = {
            1: {"name": "John Doe", "skills": ["technical_support", "billing_inquiry"]},
            2: {"name": "Jane Smith", "skills": ["order_status", "product_inquiry"]},
            3: {"name": "Admin User", "skills": ["all"]} # Admin can handle anything
        }

        # Define priority mapping based on sentiment
        self.sentiment_priority_map = {
            "negative": "urgent",
            "positive": "low",
            "neutral": "normal"
        }

    def suggest_dispatch(
        self,
        intent: str,
        sentiment: str,
        current_status: Optional[str] = 'pending'
    ) -> Tuple[Optional[int], str]:
        """
        Suggests an agent and priority based on intent, sentiment, and current ticket status.
        """
        suggested_agent_id = None
        suggested_priority = self.sentiment_priority_map.get(sentiment, "normal")

        # Basic intent-based agent assignment
        for agent_id, agent_info in self.agent_skills.items():
            if intent in agent_info["skills"] or "all" in agent_info["skills"]:
                suggested_agent_id = agent_id
                break # Assign to the first matching agent found

        # If no specific agent, maybe default to a general queue or a specific agent
        if suggested_agent_id is None:
            # Fallback to an admin or a general agent
            suggested_agent_id = 3 # Default to Admin User

        # If ticket is already in progress or replied, don't downgrade priority significantly
        if current_status in ['in_progress', 'replied'] and suggested_priority in ['low', 'normal']:
             suggested_priority = 'normal' # Maintain at least normal priority for active tickets

        logger.info(f"Dispatch suggestion - Intent: {intent}, Sentiment: {sentiment}, Suggested Agent: {suggested_agent_id}, Suggested Priority: {suggested_priority}")

        return suggested_agent_id, suggested_priority


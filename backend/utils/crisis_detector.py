from langchain_core.prompts import ChatPromptTemplate
from langchain_huggingface import ChatHuggingFace, HuggingFaceEndpoint
import json
import os

# Keywords
CRISIS_KEYWORDS = [
    "suicide", "kill myself", "end my life", "want to die", "don't want to live",
    "self harm", "self-harm", "cut myself", "hurt myself", "no reason to live",
    "better off dead", "can't go on", "give up on life", "overdose", "hang myself"
]

# LLM setup
llm = HuggingFaceEndpoint(
    repo_id='meta-llama/Llama-3.1-8B-Instruct',
    huggingfacehub_api_token=os.getenv("HUGGINGFACEHUB_API_TOKEN"),
    task="text-generation",
    max_new_tokens=256,
)

model = ChatHuggingFace(llm=llm)

# fast keyword scan
def keyword_check(text: str) -> bool:
    lower = text.lower()
    return any(kw in lower for kw in CRISIS_KEYWORDS)

# LLM risk assessment
async def llm_crisis_check(text: str) -> bool:
    """Returns True if LLM judges the message as a crisis-level risk."""
    
    prompt = ChatPromptTemplate.from_template("""
You are a mental health safety classifier.

Assess the risk level of the following message from a user talking to a mental health chatbot.
Return ONLY a JSON object in this exact format:

{{
  "risk_level": "none | mild | moderate | severe",
  "reasoning": "one sentence explanation"
}}

Risk levels:
- none: no distress signals
- mild: some sadness or frustration, no danger
- moderate: significant distress, possible self-harm ideation
- severe: explicit suicidal ideation, self-harm intent, or immediate danger

Message: {text}
""")
    
    
    chain = prompt | model
    response = await chain.ainvoke({"text": text})
    
    try:
        parsed = json.loads(response.content)
        risk = parsed.get("risk_level", "none")
        return risk in ("moderate", "severe")
    except Exception:
        return False  



# Main entry point
async def detect_crisis(text: str) -> dict:
    """
    Returns:
        {
            "is_crisis": bool,
            "method": "keyword" | "llm" | "none"
        }
    """
    
    if keyword_check(text):
        return {"is_crisis": True, "method": "keyword"}
    
    # if not in keywords
    is_crisis = await llm_crisis_check(text)
    return {
        "is_crisis": is_crisis,
        "method": "llm" if is_crisis else "none"
    }
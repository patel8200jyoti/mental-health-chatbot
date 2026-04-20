from langchain_huggingface import ChatHuggingFace, HuggingFaceEndpoint
from langchain_core.messages import HumanMessage
import os

HF_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")

llm = HuggingFaceEndpoint(
    repo_id="meta-llama/Llama-3.1-8B-Instruct",
    huggingfacehub_api_token=HF_TOKEN,
    task="text-generation",
    max_new_tokens=512,
)
model = ChatHuggingFace(llm=llm)


async def summarize_journal(entry: str) -> str:
    """Summarize a single journal entry for mood, emotions, and concerns."""
    prompt = f"""You are a concise assistant. Summarize this journal entry covering:
- Mood
- Key emotions
- Any recurring concerns

Journal: {entry}

Summary:"""

    response = await model.ainvoke([HumanMessage(content=prompt)])
    return response.content.strip()


async def summarize_chats(chats: list[str], chunk_size: int = 10) -> list[str]:
    """
    Summarize chat messages in chunks.
    chats: list of raw message strings (user messages only)
    chunk_size: how many messages to summarize together
    Returns a list of summary strings.
    """
    if not chats:
        return []

    summaries = []
    for i in range(0, len(chats), chunk_size):
        chunk_text = " | ".join(chats[i : i + chunk_size])
        prompt = f"""You are a concise assistant. Summarize the emotional tone and key points from these messages:

Messages: {chunk_text}

Summary:"""
        response = await model.ainvoke([HumanMessage(content=prompt)])
        summaries.append(response.content.strip())

    return summaries





async def generate_final_report(
    username: str,
    chat_summaries: list[str],
    journal_summaries: list[str],
    moods: list[dict],
) -> str:
    """
    Combine chat summaries, journal summaries, and mood history
    into a friendly mental health progress report.

    moods: list of mood docs from MongoDB.
           Each doc is expected to have a "value" field (int 1–5)
           matching ApiService.moodValues: sad=1, okay=2, calm=3, happy=4, great=5
    """
    # ── Average mood ──────────────────────────────────────────────────────
    mood_scores = [m.get("value", m.get("score", 3)) for m in moods if m]
    avg_mood = round(sum(mood_scores) / len(mood_scores), 2) if mood_scores else None

    # Map numeric avg back to a label for the prompt
    mood_label = "unknown"
    if avg_mood is not None:
        if avg_mood < 1.5:
            mood_label = "sad"
        elif avg_mood < 2.5:
            mood_label = "okay"
        elif avg_mood < 3.5:
            mood_label = "calm"
        elif avg_mood < 4.5:
            mood_label = "happy"
        else:
            mood_label = "great"

    # ── Build context ─────────────────────────────────────────────────────
    chat_context = (
        "\n".join(f"- {s}" for s in chat_summaries)
        if chat_summaries
        else "No chat history available."
    )
    journal_context = (
        "\n".join(f"- {s}" for s in journal_summaries)
        if journal_summaries
        else "No journal entries available."
    )

    prompt = f"""You are a compassionate mental health support assistant.

User: {username}
Average mood score: {avg_mood}/5 ({mood_label})

Chat summaries:
{chat_context}

Journal summaries:
{journal_context}

Generate a warm, detailed, and encouraging mental health progress report for this user. Structure it clearly with these sections:
1. Overall Mood Trend
2. Emotional Patterns Observed
3. Positive Progress & Strengths
4. Areas for Gentle Attention
5. Personalized Advice & Reflections

Keep the tone supportive, non-clinical, and empowering. Address the user directly as "{username}".
"""

    response = await model.ainvoke([HumanMessage(content=prompt)])
    return response.content.strip()
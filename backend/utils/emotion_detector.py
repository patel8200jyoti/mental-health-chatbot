from langchain_huggingface import ChatHuggingFace,HuggingFaceEndpoint
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage
import json
import os

HF_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")
llm = HuggingFaceEndpoint(repo_id='meta-llama/Llama-3.1-8B-Instruct',
                          huggingfacehub_api_token=HF_TOKEN,
                          task="text-generation",
                          max_new_tokens=512,
                          )
model = ChatHuggingFace(llm=llm)

async def analyse_journal(content : str):
    prompt= ChatPromptTemplate.from_template("""
        You are an emotional analysis assistant.
        
        1. Detect emotional mood (sad, okay, calm, happy, great)
        2. Give sentiment score between 0 and 1
        3. Write short supportive reflection (2 sentences)
        
        Analyze this journal entry and return your response STRICTLY in JSON format like this:

        {{
        "mood": "sad | okay | calm | happy | great",
        "sentiment_score": 0.0,
        "reflection": "short supportive reflection (2 sentences)"
        }}
        Journal:
        {text}
        """
        )

    chain = prompt | model 
    response = chain.invoke({"text" : content})
    
    try : 
        parsed = json.loads(response.content)
        
        mood = parsed['mood']
        sentiment_score = float(parsed['sentiment_score'])
        reflection = parsed['reflection']
        
        return {
            'mood_detected': mood,
            'sentiment_score': sentiment_score,
            'reflection' : reflection
        }
    except Exception as e :
        return {
            'mood' : 'unknown',
            'sentiment': 0.5,
            'reflection' : "Thank you for sharing your thoughts. I'm here with you."
        }
        
        
async def analyse_chats(chats : str):
    
    prompt = ChatPromptTemplate.from_template("""
        You are an emotional analysis assistant.
            1. Detect emotional mood
            
        Analyze this journal entry and return your response STRICTLY in JSON format like this:
        {{
            "emotion": "detect emotional mood"
        }}
        Chat:
        {text}
        """)    
    
    chain = prompt | model
    response = await chain.ainvoke({"text" : chats})
    
    if isinstance(response, dict) and "content" in response:
        content = response["content"]
    else:
        content = str(response)
        
    try :
        parsed = json.loads(content)
        mood = parsed.get('emotion','unknown')
        
        return mood
    except json.JSONDecodeError:
        return 'unknown'
    
    
    
# import asyncio

# async def test():
#     response = await model.ainvoke([
#         HumanMessage(content="Hello")
#     ])
#     print(response.content)

# if __name__ == "__main__":
#     asyncio.run(test())
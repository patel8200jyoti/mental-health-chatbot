from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    MONGODB_URL : str
    DATABASE_NAME : str = 'mhc'
    
    SECRET_KEY : str
    ALGORITHM : str
    ACCESS_TOKEN_EXPIRE_HOURS : int = 84
    
    HUGGINGFACEHUB_API_TOKEN : str
    HUGGING_FACE_MODEL : str = 'mistralai/Mistral-7B-Instruct-v0.2'
    
    CORS_ORIGINS : List= ['http://127.0.0.1:8080/','http://localhost:3000']
    
    class Config :
        env_file = ".env"
        
settings = Settings()
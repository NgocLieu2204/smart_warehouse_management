from fastapi import APIRouter
from pydantic import BaseModel
from ..agent import agent

router = APIRouter()

class Query(BaseModel):
    question: str

@router.post("/ask")
def ask_agent(query: Query):
    response = agent.run(query.question)
    return {"answer": response}

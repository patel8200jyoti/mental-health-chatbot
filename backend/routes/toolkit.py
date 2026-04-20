from fastapi import APIRouter, Depends, HTTPException
from routes.auth import get_current_user
from services.toolkit_services import get_all_tools, get_tools_by_category, get_tool_by_id

app = APIRouter(prefix="/toolkit", tags=["Toolkit"])


@app.get("/")
async def list_tools(user=Depends(get_current_user)):
    """All tool cards for the grid view."""
    return get_all_tools()


@app.get("/grouped")
async def list_tools_grouped(user=Depends(get_current_user)):
    """Tools grouped by category — for Flutter section headers."""
    return get_tools_by_category()


@app.get("/{tool_id}")
async def get_tool(tool_id: str, user=Depends(get_current_user)):
    """Full tool content when user taps a card."""
    tool = get_tool_by_id(tool_id)
    if not tool:
        raise HTTPException(status_code=404, detail="Tool not found")
    return tool
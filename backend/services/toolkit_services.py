from data.toolkit_data import TOOLKIT

# Card grid view
def get_all_tools():
    return [
        {
            "id": tool["id"],
            "category": tool["category"],
            "title": tool["title"],
            "description": tool["description"],
            "icon": tool["icon"],
        }
        for tool in TOOLKIT
    ]
    

# Group by category 
def get_tools_by_category():
    grouped = {}
    for tool in TOOLKIT:
        cat = tool["category"]
        if cat not in grouped:
            grouped[cat] = []
        grouped[cat].append({
            "id": tool["id"],
            "title": tool["title"],
            "description": tool["description"],
            "icon": tool["icon"],
        })
    return grouped



# Full detail when clicked on the card
def get_tool_by_id(tool_id: str):
    for tool in TOOLKIT:
        if tool["id"] == tool_id:
            return tool
    return None
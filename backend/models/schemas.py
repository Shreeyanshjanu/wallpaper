from pydantic import BaseModel
from typing import List

class MediaPosition(BaseModel):
    id: str
    media_type: str  # 'video' or 'image'
    x: float
    y: float
    width: float
    height: float
    start_time: int
    duration: int

class ComposeResponse(BaseModel):
    download_url: str
    file_name: str

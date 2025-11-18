from pydantic import BaseModel
from typing import List

class VideoPosition(BaseModel):
    video_url: str
    x:float
    y:float
    width:float
    height:float
    start_time:float
    duration:float

class ComposeRequest(BaseModel):
    videos: List[VideoPosition]
    canvas_width:int=1920
    canvas_height:int=1080
    output_duration:int=120

class ComposeResponse(BaseModel):
    download_url: str
    file_name: str
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import uvicorn
import os
import traceback
import json
from typing import List
from models.schemas import ComposeResponse
from services.video_processor import VideoProcessor

app = FastAPI(title="Wallpaper Video Composer API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

video_processor = VideoProcessor()


@app.get("/")
def read_root():
    return {"message": "Wallpaper Video Composer API is running"}


@app.post("/api/compose-upload", response_model=ComposeResponse)
async def compose_videos_upload(
        videos: List[UploadFile] = File(...),
        metadata: str = Form(...)
):
    """
    Accept video files directly from client and compose them
    """
    temp_files = []
    try:
        # Parse metadata
        meta = json.loads(metadata)
        video_positions = meta['video_positions']
        canvas_width = meta['canvas_width']
        canvas_height = meta['canvas_height']
        output_duration = meta['output_duration']

        print(f"Received {len(videos)} video files")

        # Save uploaded files temporarily
        video_paths = {}
        for video_file in videos:
            # Extract video ID from filename
            video_id = video_file.filename.replace('.mp4', '')
            temp_path = os.path.join("temp", f"upload_{video_id}.mp4")

            # Save file
            with open(temp_path, 'wb') as f:
                content = await video_file.read()
                f.write(content)

            video_paths[video_id] = temp_path
            temp_files.append(temp_path)

        # Create video position objects with local file paths
        from models.schemas import VideoPosition
        video_positions_objects = []
        for vp in video_positions:
            video_id = vp['id']
            if video_id in video_paths:
                video_positions_objects.append(VideoPosition(
                    video_url=video_paths[video_id],  # Use local file path
                    x=vp['x'],
                    y=vp['y'],
                    width=vp['width'],
                    height=vp['height'],
                    start_time=vp['start_time'],
                    duration=vp['duration']
                ))

        # Compose videos
        output_path = video_processor.compose_videos_from_local(
            videos=video_positions_objects,
            canvas_width=canvas_width,
            canvas_height=canvas_height,
            output_duration=output_duration
        )

        file_name = os.path.basename(output_path)

        return ComposeResponse(
            download_url=f"http://localhost:8000/download/{file_name}",
            file_name=file_name
        )

    except Exception as e:
        print(f"Error composing videos: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # Cleanup uploaded files
        for temp_file in temp_files:
            if os.path.exists(temp_file):
                os.remove(temp_file)


@app.get("/download/{filename}")
async def download_file(filename: str):
    """Download composed video file"""
    file_path = os.path.join("temp", filename)
    if os.path.exists(file_path):
        return FileResponse(
            file_path,
            media_type="video/mp4",
            filename=filename
        )
    raise HTTPException(status_code=404, detail="File not found")


@app.get("/health")
def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

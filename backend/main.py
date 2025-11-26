from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import uvicorn
import os
import traceback
import json
from typing import List

from services.video_processor import VideoProcessor
from models.schemas import ComposeResponse

app = FastAPI(title="Wallpaper Video Composer API")

# CORS Configuration - Allow your Netlify domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://wallpaper-composer.netlify.app",  # Your Netlify frontend
        "http://localhost:3000",
        "*"  # Allow all for testing
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create temp directory if it doesn't exist
os.makedirs("temp", exist_ok=True)

video_processor = VideoProcessor()

@app.get("/")
def read_root():
    return {"message": "Wallpaper Video Composer API is running"}

@app.post("/api/compose-upload", response_model=ComposeResponse)
async def compose_media_upload(
        request: Request,  # Added to get base URL
        media_files: List[UploadFile] = File(...),
        metadata: str = Form(...)
):
    """
    Accept multiple media files (videos + images) and compose them
    """
    temp_files = []
    try:
        meta = json.loads(metadata)
        media_positions = meta['media_positions']
        canvas_width = meta['canvas_width']
        canvas_height = meta['canvas_height']
        output_duration = meta['output_duration']

        print(f"Received {len(media_files)} media files")

        # Save uploaded files
        media_paths = {}
        for media_file in media_files:
            media_id = media_file.filename.replace('.mp4', '').replace('.png', '').replace('.jpg', '').replace('.jpeg', '')

            # Determine extension from filename
            extension = media_file.filename.split('.')[-1]
            temp_path = os.path.join("temp", f"upload_{media_id}.{extension}")

            with open(temp_path, 'wb') as f:
                content = await media_file.read()
                f.write(content)

            media_paths[media_id] = temp_path
            temp_files.append(temp_path)

        # Create media position objects
        from models.schemas import MediaPosition
        media_positions_objects = []
        for mp in media_positions:
            media_id = mp['id']
            if media_id in media_paths:
                media_positions_objects.append(MediaPosition(
                    id=media_id,
                    media_type=mp['media_type'],
                    x=mp['x'],
                    y=mp['y'],
                    width=mp['width'],
                    height=mp['height'],
                    start_time=mp['start_time'],
                    duration=mp['duration']
                ))

        # Compose
        output_path = video_processor.compose_media_from_local(
            media_items=media_positions_objects,
            media_paths=media_paths,
            canvas_width=canvas_width,
            canvas_height=canvas_height,
            output_duration=output_duration
        )

        file_name = os.path.basename(output_path)

        # Get base URL dynamically (works in production and development)
        base_url = str(request.base_url).rstrip('/')
        
        return ComposeResponse(
            download_url=f"{base_url}/download/{file_name}",  # ✅ Fixed!
            file_name=file_name
        )

    except Exception as e:
        print(f"Error composing: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # Don't delete files immediately - keep them for download
        pass

@app.get("/download/{filename}")
async def download_file(filename: str):
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

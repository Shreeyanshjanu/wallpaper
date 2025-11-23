import ffmpeg
import os
from typing import List
import uuid
import httpx

# Set FFmpeg executable path for Windows
FFMPEG_PATH = r"C:\ffmpeg\ffmpeg-8.0-essentials_build\bin\ffmpeg.exe"
os.environ["FFMPEG_BINARY"] = FFMPEG_PATH


class VideoProcessor:
    def __init__(self, temp_dir="temp"):
        self.temp_dir = temp_dir
        os.makedirs(temp_dir, exist_ok=True)

    def download_video_from_url(self, url: str, local_path: str):
        """Download video from any public URL (Cloudinary, etc.)"""
        try:
            print(f"Downloading video from: {url}")

            # Use httpx to download
            with httpx.stream("GET", url, timeout=60.0) as response:
                response.raise_for_status()

                with open(local_path, 'wb') as f:
                    for chunk in response.iter_bytes(chunk_size=8192):
                        f.write(chunk)

            print(f"Downloaded to: {local_path}")
        except Exception as e:
            raise Exception(f"Failed to download video from {url}: {str(e)}")

    def compose_videos_from_local(
            self,
            videos: List,
            canvas_width: int,
            canvas_height: int,
            output_duration: int
    ) -> str:
        """
        Compose videos from local file paths (no download needed)
        """
        output_filename = f"{uuid.uuid4()}.mp4"
        output_path = os.path.join(self.temp_dir, output_filename)

        # Videos are already local, just use their paths
        local_videos = [video.video_url for video in videos]

        try:
            # Create base canvas
            base = ffmpeg.input(
                f'color=c=white:s={canvas_width}x{canvas_height}:d={output_duration}',
                f='lavfi'
            )

            # Build overlay chain
            current = base
            for idx, video in enumerate(videos):
                x_pos = int(video.x * canvas_width)
                y_pos = int(video.y * canvas_height)
                scaled_width = int(video.width * canvas_width)
                scaled_height = int(video.height * canvas_height)

                video_input = ffmpeg.input(local_videos[idx], stream_loop=-1)
                scaled = video_input.filter('scale', scaled_width, scaled_height)

                video_duration = min(video.duration, output_duration - video.start_time)
                trimmed = scaled.filter('trim', start=0, duration=video_duration)
                trimmed = trimmed.filter('setpts', 'PTS-STARTPTS')

                if video.start_time > 0:
                    trimmed = trimmed.filter('tpad', start_duration=video.start_time)

                current = ffmpeg.overlay(current, trimmed, x=x_pos, y=y_pos)

            output = ffmpeg.output(
                current,
                output_path,
                vcodec='libx264',
                pix_fmt='yuv420p',
                t=output_duration,
                **{'b:v': '5M'}
            )

            print("Running FFmpeg composition...")
            ffmpeg.run(output, overwrite_output=True, capture_stdout=True, capture_stderr=True)
            print(f"Composition complete: {output_path}")

        except ffmpeg.Error as e:
            error_message = e.stderr.decode() if e.stderr else str(e)
            raise Exception(f"FFmpeg error: {error_message}")

        return output_path

    def compose_media_from_local(
            self,
            media_items: List,
            media_paths: dict,
            canvas_width: int,
            canvas_height: int,
            output_duration: int
    ) -> str:
        """
        Compose videos AND images from local file paths
        """
        output_filename = f"{uuid.uuid4()}.mp4"
        output_path = os.path.join(self.temp_dir, output_filename)

        try:
            # Create base canvas
            base = ffmpeg.input(
                f'color=c=white:s={canvas_width}x{canvas_height}:d={output_duration}',
                f='lavfi'
            )

            current = base
            for idx, media in enumerate(media_items):
                media_path = media_paths[media.id]
                x_pos = int(media.x * canvas_width)
                y_pos = int(media.y * canvas_height)
                scaled_width = int(media.width * canvas_width)
                scaled_height = int(media.height * canvas_height)

                if media.media_type == 'video':
                    # Handle video
                    video_input = ffmpeg.input(media_path, stream_loop=-1)
                    scaled = video_input.filter('scale', scaled_width, scaled_height)

                    video_duration = min(media.duration, output_duration - media.start_time)
                    trimmed = scaled.filter('trim', start=0, duration=video_duration)
                    trimmed = trimmed.filter('setpts', 'PTS-STARTPTS')

                    if media.start_time > 0:
                        trimmed = trimmed.filter('tpad', start_duration=media.start_time)

                    current = ffmpeg.overlay(current, trimmed, x=x_pos, y=y_pos)

                else:
                    # Handle image - convert to video stream
                    image_input = ffmpeg.input(media_path, loop=1, t=media.duration)
                    scaled = image_input.filter('scale', scaled_width, scaled_height)

                    if media.start_time > 0:
                        scaled = scaled.filter('tpad', start_duration=media.start_time)

                    current = ffmpeg.overlay(current, scaled, x=x_pos, y=y_pos)

            output = ffmpeg.output(
                current,
                output_path,
                vcodec='libx264',
                pix_fmt='yuv420p',
                t=output_duration,
                **{'b:v': '5M'}
            )

            print("Running FFmpeg composition...")
            ffmpeg.run(output, overwrite_output=True, capture_stdout=True, capture_stderr=True)
            print(f"Composition complete: {output_path}")

        except ffmpeg.Error as e:
            error_message = e.stderr.decode() if e.stderr else str(e)
            raise Exception(f"FFmpeg error: {error_message}")

        return output_path

    def cleanup_file(self, file_path: str):
        """Remove temporary file"""
        if os.path.exists(file_path):
            os.remove(file_path)

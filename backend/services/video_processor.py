import ffmpeg
import os
from typing import List
from models.schemas import VideoPosition
import uuid
import httpx  # Use httpx instead of requests
FFMPEG_PATH = r"C:\ffmpeg\bin\ffmpeg.exe"  # Update this path
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

    def compose_videos(
            self,
            videos: List[VideoPosition],
            canvas_width: int,
            canvas_height: int,
            output_duration: int
    ) -> str:
        """
        Compose multiple videos onto a canvas using FFmpeg overlay filters
        """
        output_filename = f"{uuid.uuid4()}.mp4"
        output_path = os.path.join(self.temp_dir, output_filename)

        # Download all videos locally first
        local_videos = []
        for idx, video in enumerate(videos):
            local_path = os.path.join(self.temp_dir, f"input_{idx}_{uuid.uuid4()}.mp4")

            try:
                # Download from Cloudinary or any public URL
                self.download_video_from_url(video.video_url, local_path)
                local_videos.append(local_path)
            except Exception as e:
                # Clean up any downloaded files on error
                for lv in local_videos:
                    if os.path.exists(lv):
                        os.remove(lv)
                raise Exception(f"Error downloading video {idx}: {str(e)}")

        try:
            # Create base canvas (white background)
            base = ffmpeg.input(
                f'color=c=white:s={canvas_width}x{canvas_height}:d={output_duration}',
                f='lavfi'
            )

            # Build overlay chain
            current = base
            for idx, video in enumerate(videos):
                # Calculate pixel positions from normalized values
                x_pos = int(video.x * canvas_width)
                y_pos = int(video.y * canvas_height)
                scaled_width = int(video.width * canvas_width)
                scaled_height = int(video.height * canvas_height)

                # Load video input
                video_input = ffmpeg.input(local_videos[idx], stream_loop=-1)  # Loop infinitely

                # Scale video to desired size
                scaled = video_input.filter('scale', scaled_width, scaled_height)

                # Trim to fit within output duration considering start time
                video_duration = min(video.duration, output_duration - video.start_time)
                trimmed = scaled.filter('trim', start=0, duration=video_duration)
                trimmed = trimmed.filter('setpts', 'PTS-STARTPTS')

                # Add delay if start_time > 0
                if video.start_time > 0:
                    trimmed = trimmed.filter('tpad', start_duration=video.start_time)

                # Overlay on current canvas
                current = ffmpeg.overlay(current, trimmed, x=x_pos, y=y_pos)

            # Output with codec settings
            output = ffmpeg.output(
                current,
                output_path,
                vcodec='libx264',
                pix_fmt='yuv420p',
                t=output_duration,
                **{'b:v': '5M'}  # 5 Mbps bitrate
            )

            # Run FFmpeg
            print("Running FFmpeg composition...")
            ffmpeg.run(output, overwrite_output=True, capture_stdout=True, capture_stderr=True)
            print(f"Composition complete: {output_path}")

        except ffmpeg.Error as e:
            # Clean up on FFmpeg error
            for local_video in local_videos:
                if os.path.exists(local_video):
                    os.remove(local_video)
            error_message = e.stderr.decode() if e.stderr else str(e)
            raise Exception(f"FFmpeg error: {error_message}")

        finally:
            # Cleanup input files
            for local_video in local_videos:
                if os.path.exists(local_video):
                    os.remove(local_video)

        return output_path

    def cleanup_file(self, file_path: str):
        """Remove temporary file"""
        if os.path.exists(file_path):
            os.remove(file_path)

    def compose_videos_from_local(
            self,
            videos: List[VideoPosition],
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


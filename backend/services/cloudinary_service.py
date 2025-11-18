import os
import requests
from dotenv import load_dotenv

load_dotenv()


class CloudinaryService:
    def __init__(self):
        self.cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME")
        self.api_key = os.getenv("CLOUDINARY_API_KEY")
        self.api_secret = os.getenv("CLOUDINARY_API_SECRET")

    def delete_video(self, public_id: str):
        """Delete video from Cloudinary after processing"""
        url = f"https://api.cloudinary.com/v1_1/{self.cloud_name}/video/destroy"
        auth = (self.api_key, self.api_secret)
        data = {"public_id": public_id}

        response = requests.post(url, auth=auth, data=data)
        return response.json()

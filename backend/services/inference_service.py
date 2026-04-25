import os
import tempfile
from pathlib import Path
from inference_sdk import InferenceHTTPClient
from dotenv import load_dotenv

# Explicitly point to the backend/.env file regardless of where the server is run from
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

CLIENT = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key=os.environ.get("ROBOFLOW_API_KEY")
)

class InferenceService:
    @staticmethod
    def detect_image(image_bytes: bytes):
        # Save bytes to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp_file:
            tmp_file.write(image_bytes)
            tmp_file_path = tmp_file.name

        try:
            # Infer using the temporary file path
            result = CLIENT.infer(tmp_file_path, model_id="freshness-fruits-and-vegetables/7")
            return result
        finally:
            # Always clean up the temp file
            if os.path.exists(tmp_file_path):
                os.remove(tmp_file_path)

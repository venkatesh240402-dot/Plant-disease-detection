import os
import asyncio
from inference_sdk import InferenceHTTPClient
from dotenv import load_dotenv

load_dotenv("backend/.env")

CLIENT = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key=os.environ.get("ROBOFLOW_API_KEY")
)

try:
    # try inferring on a dummy file
    with open("backend/.env", "rb") as f:
        image_bytes = f.read()
    
    import base64
    image_b64 = base64.b64encode(image_bytes).decode('utf-8')
    result = CLIENT.infer(image_b64, model_id="freshness-fruits-and-vegetables/7")
    print("Success")
except Exception as e:
    import traceback
    traceback.print_exc()

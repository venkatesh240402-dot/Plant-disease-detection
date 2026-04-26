import base64
import requests
import io
from PIL import Image

# Warmup: Load the model into RAM when the server starts so the first scan is instant
def warmup_model():
    try:
        print("🔥 Warming up llava:13b model...")
        payload = {
            "model": "llava:13b",
            "prompt": "hi",
            "images": [],
            "stream": False,
            "keep_alive": -1  # Keep model in RAM forever (until server restarts)
        }
        requests.post("http://localhost:11434/api/generate", json=payload, timeout=120)
        print("✅ llava:13b is warm and ready!")
    except Exception as e:
        print(f"⚠️ Warmup failed (Ollama may not be running yet): {e}")

warmup_model()

class InferenceService:
    @staticmethod
    def detect_image(image_bytes: bytes):
        try:
            # 1. Resize image to 640x480 before sending to LLaVA
            # This is the biggest speed optimization — LLaVA doesn't need a huge image
            img = Image.open(io.BytesIO(image_bytes))
            img = img.convert("RGB")
            img.thumbnail((1024, 1024), Image.LANCZOS)
            buffer = io.BytesIO()
            img.save(buffer, format="JPEG", quality=92)
            resized_bytes = buffer.getvalue()
            
            # 2. Convert to base64
            base64_image = base64.b64encode(resized_bytes).decode('utf-8')
            
            # 3. Prepare payload with keep_alive to prevent model unloading
            payload = {
                "model": "llava:13b",
                "prompt": "You are an expert plant pathologist. Carefully examine this image for ANY signs of disease, infection, spots, lesions, discoloration, wilting, or damage on the plant. Do NOT default to healthy unless the leaf is completely perfect with zero blemishes. If there is even a slight abnormality, identify the disease. Reply ONLY in this exact format (no extra words):\nCrop: [Plant species]\nDisease: [Exact disease name, or 'Healthy' ONLY if perfect]\nSolution: [One specific treatment sentence]",
                "images": [base64_image],
                "stream": False,
                "keep_alive": -1  # Keep model in RAM between requests
            }
            
            # 4. Send to local Ollama server
            response = requests.post("http://localhost:11434/api/generate", json=payload, timeout=120)
            response.raise_for_status()
            
            # 5. Parse the response
            result_text = response.json().get("response", "Unknown")
            
            # DEBUG: Print raw LLaVA output
            print(f"\n--- LLaVA Raw Response ---\n{result_text}\n--------------------------")
            
            # 6. Return in the JSON format that api_client.dart expects
            return {
                "predictions": [
                    {
                        "class": result_text.strip(),
                        "confidence": 0.99
                    }
                ]
            }
            
        except Exception as e:
            print(f"Ollama Error: {e}")
            return {
                "predictions": [
                    {
                        "class": "Crop: Unknown\nDisease: Error\nSolution: Could not connect to Ollama. Please ensure the server is running.",
                        "confidence": 0.0
                    }
                ]
            }

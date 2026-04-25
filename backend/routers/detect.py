from fastapi import APIRouter, File, UploadFile
from backend.services.inference_service import InferenceService

router = APIRouter()

@router.post("/detect")
async def detect_disease(file: UploadFile = File(...)):
    # Read the file contents
    image_bytes = await file.read()
    
    # Call the Roboflow API via our service
    result = InferenceService.detect_image(image_bytes)
    
    return result

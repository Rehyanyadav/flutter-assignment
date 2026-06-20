import os
import io
from PIL import Image
from supabase import create_client, Client

# --- SUPABASE CONFIG ---
SUPABASE_URL = "https://onxbxmjjyspgskemqywl.supabase.co"

# TODO: PASTE YOUR SECRET KEY HERE
SUPABASE_KEY = "YOUR_SECRET_KEY" 

BUCKET_NAME = "media"
INPUT_DIR = "input_images"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def process_and_upload():
    if not os.path.exists(INPUT_DIR):
        print(f"Create a folder named '{INPUT_DIR}' and add some images.")
        return
        
    for filename in os.listdir(INPUT_DIR):
        if not filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            continue
            
        filepath = os.path.join(INPUT_DIR, filename)
        base_name = os.path.splitext(filename)[0]
        # Sanitize filename to remove spaces and special characters which Supabase rejects
        import re
        base_name = re.sub(r'[^a-zA-Z0-9_-]', '_', base_name)
        print(f"Processing: {filename}...")
        
        with Image.open(filepath) as img:
            # 1. Raw Archive (Original)
            raw_bytes = io.BytesIO()
            img.save(raw_bytes, format=img.format)
            raw_path = f"{base_name}_raw.{img.format.lower()}"
            
            # 2. Mobile Full (1080x1080 max)
            mobile_img = img.copy()
            mobile_img.thumbnail((1080, 1080), Image.Resampling.LANCZOS)
            mobile_bytes = io.BytesIO()
            mobile_img.save(mobile_bytes, format="webp", quality=80)
            mobile_path = f"{base_name}_mobile.webp"
            
            # 3. Thumbnail (300x300 max)
            thumb_img = img.copy()
            thumb_img.thumbnail((300, 300), Image.Resampling.LANCZOS)
            thumb_bytes = io.BytesIO()
            thumb_img.save(thumb_bytes, format="webp", quality=70)
            thumb_path = f"{base_name}_thumb.webp"
            
            # Upload to Supabase Storage
            upload_to_storage(raw_path, raw_bytes.getvalue())
            upload_to_storage(mobile_path, mobile_bytes.getvalue())
            upload_to_storage(thumb_path, thumb_bytes.getvalue())
            
            # Get Public URLs
            raw_url = supabase.storage.from_(BUCKET_NAME).get_public_url(raw_path)
            mobile_url = supabase.storage.from_(BUCKET_NAME).get_public_url(mobile_path)
            thumb_url = supabase.storage.from_(BUCKET_NAME).get_public_url(thumb_path)
            
            # Insert into Database
            supabase.table("posts").insert({
                "media_thumb_url": thumb_url,
                "media_mobile_url": mobile_url,
                "media_raw_url": raw_url,
            }).execute()
            print(f"Successfully seeded {filename} to database.\n")

def upload_to_storage(path, file_bytes):
    try:
        supabase.storage.from_(BUCKET_NAME).upload(path, file_bytes, {"content-type": "image/webp"})
    except Exception as e:
        print(f"Failed to upload {path}. Error: {e}")

if __name__ == "__main__":
    process_and_upload()
    print("Pipeline complete.")

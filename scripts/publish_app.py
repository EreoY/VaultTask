import os
import sys
import zipfile
import subprocess
import base64
import argparse
from datetime import datetime

# Configuration
CHUNK_SIZE = 512 * 1024  # 512KB
PROJECT_DIR = "my_ai_assistant"
BACKEND_DIR = "cloudflare_backend"

def run_cmd(cmd, cwd=None):
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result.stdout

def build_app(platform):
    print(f"Building for {platform}...")
    run_cmd(f"flutter build {platform} --release", cwd=PROJECT_DIR)

def create_zip(platform):
    zip_name = f"calenda-{platform}.zip"
    if platform == "linux":
        src = os.path.join(PROJECT_DIR, "build/linux/x64/release/bundle")
    elif platform == "windows":
        src = os.path.join(PROJECT_DIR, "build/windows/x64/runner/Release")
    else:
        raise ValueError("Unsupported platform")

    print(f"Zipping {src} to {zip_name}...")
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(src):
            for file in files:
                abs_path = os.path.join(root, file)
                rel_path = os.path.relpath(abs_path, src)
                z.write(abs_path, rel_path)
    return zip_name

def upload_to_d1(zip_path, platform, db_name):
    print(f"Uploading {zip_path} to D1 ({db_name})...")
    
    # 1. Clear old binaries for this platform
    run_cmd(f'wrangler d1 execute {db_name} --command "DELETE FROM app_binaries WHERE platform=\'{platform}\'"', cwd=BACKEND_DIR)

    # 2. Read and chunk
    with open(zip_path, 'rb') as f:
        data = f.read()
    
    total_chunks = (len(data) + CHUNK_SIZE - 1) // CHUNK_SIZE
    version = "1.0.0"
    created_at = int(datetime.now().timestamp() * 1000)

    for i in range(total_chunks):
        start = i * CHUNK_SIZE
        end = min(start + CHUNK_SIZE, len(data))
        chunk = data[start:end]
        
        # Convert chunk to hex string for SQL BLOB literal X'...'
        hex_data = chunk.hex()
        
        print(f"Uploading chunk {i+1}/{total_chunks}...")
        sql = f"INSERT INTO app_binaries (platform, version, chunk_index, total_chunks, data, created_at) VALUES ('{platform}', '{version}', {i}, {total_chunks}, X'{hex_data}', {created_at});"
        
        # We write the SQL to a temp file to avoid command line length limits
        with open("temp_upload.sql", "w") as tmp:
            tmp.write(sql)
        
        run_cmd(f'wrangler d1 execute {db_name} --file=../temp_upload.sql', cwd=BACKEND_DIR)
    
    os.remove("temp_upload.sql")
    print("Upload complete!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", required=True, choices=["linux", "windows"])
    parser.add_argument("--db", default="calenda-db")
    args = parser.parse_args()

    # build_app(args.platform) # Uncomment to build before upload
    zip_file = create_zip(args.platform)
    upload_to_d1(zip_file, args.platform, args.db)
    os.remove(zip_file)

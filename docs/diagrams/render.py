"""Render Mermaid .mmd files to PNG via mermaid.ink API."""
import zlib
import base64
import urllib.request
import sys
import os

def encode_mermaid(code: str) -> str:
    """Encode Mermaid code for mermaid.ink API."""
    # pako (zlib) compress → base64url
    compressed = zlib.compress(code.encode('utf-8'), level=9)
    # base64url (no padding)
    encoded = base64.urlsafe_b64encode(compressed).decode('utf-8').rstrip('=')
    return encoded

def render(mmd_path: str, output_path: str):
    """Render a .mmd file to PNG."""
    with open(mmd_path, 'r', encoding='utf-8') as f:
        code = f.read()

    encoded = encode_mermaid(code)
    url = f'https://mermaid.ink/img/{encoded}?type=png'

    print(f'Downloading: {os.path.basename(mmd_path)} → {os.path.basename(output_path)}')
    try:
        urllib.request.urlretrieve(url, output_path)
        print(f'  OK: {output_path}')
    except Exception as e:
        print(f'  FAILED: {e}')

def main():
    diagrams_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(diagrams_dir, 'png')
    os.makedirs(output_dir, exist_ok=True)

    mmd_files = sorted([f for f in os.listdir(diagrams_dir) if f.endswith('.mmd')])

    if not mmd_files:
        print('No .mmd files found.')
        return

    for mmd in mmd_files:
        mmd_path = os.path.join(diagrams_dir, mmd)
        png_name = mmd.replace('.mmd', '.png')
        png_path = os.path.join(output_dir, png_name)
        render(mmd_path, png_path)

    print(f'\nDone. {len(mmd_files)} diagrams rendered to {output_dir}/')

if __name__ == '__main__':
    main()

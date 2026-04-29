import os
import io
import re
import sys
import json
from pathlib import Path
from google.cloud import vision

# --- Credentials Setup ---
_CRED_PATH = Path(__file__).parent / "credentials.json"
if _CRED_PATH.exists():
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(_CRED_PATH)

# --- Configuration: Nutritional Keywords ---
_NUTRIENT_KEYWORDS = {
    "enerji", "energy", "energie", "kcal", "kj",
    "yag", "fat", "fett", "doymus", "saturated", "saturates", "gesattigte",
    "karbonhidrat", "carbohydrate", "carbohydrates", "kohlenhydrate",
    "seker", "sugar", "sugars", "zucker",
    "lif", "fiber", "fibre", "ballaststoffe",
    "protein", "eiweiss", "zulal",
    "tuz", "salt", "salz", "sodyum", "sodium", "natrium",
    "vitamin", "kalsiyum", "calcium", "demir", "iron", "magnezyum", "magnesium", "cinko", "zinc",
    "potasyum", "potassium", "fosfor", "phosphorus", "iyot", "iodine"
}

_VAL_KEYWORDS = {"uygun", "yok", "var", "pozitif", "negatif", "normal", "berrak", "renksiz"}

def _to_ascii(s: str) -> str:
    """Basic Turkish character normalization for keyword matching."""
    return s.lower().replace('ı', 'i').replace('ş', 's').replace('ğ', 'g').replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')

def _is_nutrient_word(word: str) -> bool:
    norm = _to_ascii(word)
    parts = re.split(r'[^a-zA-Z]', norm)
    return any(p in _NUTRIENT_KEYWORDS for p in parts if p)

def _is_value_word(word: str) -> bool:
    text = word.lower()
    if any(c.isdigit() for c in text): return True
    if text in _VAL_KEYWORDS: return True
    # Look for decimals like 31,2 or 0.06
    if re.match(r'^[\d.,/]+[a-zA-Z%]*$', text): return True
    return False

def _clean_text(text: str) -> str:
    # Join spaced decimals: 6 . 2 -> 6.2
    text = re.sub(r'(\d)\s*([.,])\s*(\d)', r'\1\2\3', text)
    return re.sub(r'\s+', ' ', text).strip()

def analyze_image(image_path: str):
    client = vision.ImageAnnotatorClient()
    with io.open(image_path, 'rb') as image_file:
        content = image_file.read()
    
    image = vision.Image(content=content)
    response = client.document_text_detection(image=image)
    
    if response.error.message:
        return {"status": "error", "message": response.error.message}
    
    annotation = response.full_text_annotation
    if not annotation:
        return {"status": "low_quality", "veri": {}}

    extracted = {}
    for page in annotation.pages:
        # UNIVERSAL WORD GATHERING
        words = []
        for block in page.blocks:
            for paragraph in block.paragraphs:
                for word in paragraph.words:
                    text = "".join(s.text for s in word.symbols)
                    v = word.bounding_box.vertices
                    words.append({
                        'text': text,
                        'y_min': min(pt.y for pt in v), 'y_max': max(pt.y for pt in v),
                        'x_min': min(pt.x for pt in v), 'x_max': max(pt.x for pt in v),
                        'y_mid': (min(pt.y for pt in v) + max(pt.y for pt in v)) / 2
                    })

        if not words: continue

        # Robust Line Grouping (Tolerance 40% of height)
        words.sort(key=lambda w: w['y_mid'])
        lines = []
        current_line = [words[0]]
        for i in range(1, len(words)):
            w = words[i]
            prev = current_line[-1]
            h = max(w['y_max'] - w['y_min'], prev['y_max'] - prev['y_min'])
            if abs(w['y_mid'] - prev['y_mid']) < h * 0.4:
                current_line.append(w)
            else:
                lines.append(sorted(current_line, key=lambda x: x['x_min']))
                current_line = [w]
        lines.append(sorted(current_line, key=lambda x: x['x_min']))

        # Extraction from lines
        for line in lines:
            # Anchor search
            start_idx = -1
            for i, w in enumerate(line):
                if _is_nutrient_word(w['text']):
                    start_idx = i
                    break
            
            if start_idx == -1: continue

            # Value split search
            split_idx = -1
            for i in range(start_idx, len(line)):
                # A value word is something that has a digit or is a keyword
                # BUT we must skip the anchor itself if it contains a digit (e.g. B12)
                if i == start_idx and any(c.isalpha() for c in line[i]['text']):
                    continue
                if _is_value_word(line[i]['text']):
                    split_idx = i
                    break
            
            # Greedy: if no value found but words exist after anchor
            if split_idx == -1 and len(line) > start_idx + 1:
                split_idx = len(line) - 1

            if split_idx != -1:
                key_words = line[start_idx:split_idx]
                val_words = line[split_idx:]
                
                # If key is empty, take the anchor as key
                if not key_words:
                    key_words = [line[start_idx]]
                    val_words = line[start_idx+1:] if len(line) > start_idx+1 else []

                key_text = " ".join(w['text'] for w in key_words)
                key_text = re.sub(r'[:\-=\.,\s\(\)]+$', '', key_text).strip()
                key_text = re.sub(r'^[:\-=\.,\s\(\)]+', '', key_text).strip()
                
                if key_text and val_words:
                    val_text = " ".join(w['text'] for w in val_words)
                    extracted[key_text] = _clean_text(val_text)

    if not extracted:
        return {"status": "low_quality", "gorsel": Path(image_path).name, "veri": {}}

    return {"status": "ok", "gorsel": Path(image_path).name, "veri": extracted}

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    paths = [Path(target)] if Path(target).is_file() else sorted(Path(target).glob("*"))
    images = [str(p) for p in paths if p.suffix.lower() in exts]

    if not images:
        print(json.dumps({"error": "No images found"}, ensure_ascii=False))
        return

    results = {Path(img).name: analyze_image(img) for img in images}
    print(json.dumps(results, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()

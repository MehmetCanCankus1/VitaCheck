import cv2
import numpy as np
import json
import re
import os
import easyocr
import tempfile
from typing import Dict, List, Optional

DEBUG = True
SAVE_OUTPUT = False

reader = None
def get_reader():
    global reader
    if reader is None:
        reader = easyocr.Reader(['en', 'tr'], gpu=False)
    return reader

def scout_and_crop(image_path: str):
    img = cv2.imread(image_path)
    if img is None: raise FileNotFoundError(f"Image not found: {image_path}")
    img_h, img_w = img.shape[:2]
    scale_down = 1.0
    if max(img_h, img_w) > 1500:
        scale_down = 1500 / max(img_h, img_w)
        scout_img = cv2.resize(img, None, fx=scale_down, fy=scale_down)
    else: scout_img = img.copy()
        
    results = get_reader().readtext(scout_img)
    if not results: return img
        
    mask = np.zeros(scout_img.shape[:2], dtype=np.uint8)
    for box, text, conf in results:
        points = np.array(box, dtype=np.int32)
        cv2.fillPoly(mask, [points], 255)
        
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (100, 30))
    dilated = cv2.dilate(mask, kernel, iterations=2)
    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours: return img
    
    largest_cnt = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_cnt)
    
    x_orig, y_orig = int(x / scale_down), int(y / scale_down)
    w_orig, h_orig = int(w / scale_down), int(h / scale_down)
    pad_x, pad_y = int(img_w * 0.05), int(img_h * 0.05)
    
    x1, y1 = max(0, x_orig - pad_x), max(0, y_orig - pad_y)
    x2, y2 = min(img_w, x_orig + w_orig + pad_x), min(img_h, y_orig + h_orig + pad_y)
    cropped = img[y1:y2, x1:x2]
    
    if DEBUG: cv2.imwrite("debug_density_crop.jpg", cropped)
    return cropped

def high_fidelity_ocr(cropped_img) -> List[Dict]:
    gray = cv2.cvtColor(cropped_img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    scale = min(2000.0 / max(h, w), 3.0)
    if scale < 1.0: scale = 1.0
    
    resized = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enhanced = clahe.apply(resized)
    
    res_a = get_reader().readtext(resized)
    res_b = get_reader().readtext(enhanced)
    
    boxes = []
    for box, text, conf in res_a + res_b:
        y_center = sum([p[1] for p in box]) / 4
        x_min = min([p[0] for p in box])
        x_max = max([p[0] for p in box])
        boxes.append({"raw_text": text.strip(), "x": (x_min + x_max)/2, "y": y_center, "conf": conf, "x_min": x_min, "x_max": x_max})
    
    return boxes

def normalize_text(text: str) -> str:
    t = text.lower()
    t = re.sub(r'(\d)\s+(\d)', r'\1.\2', t)
    t = re.sub(r'(\d)[9pq]\b', r'\1', t)
    t = re.sub(r'ya[gğ][a-z]*', 'yağ', t, flags=re.IGNORECASE)
    return t

def detect_columns(boxes: List[Dict]) -> Dict:
    priority_cols = []
    fallback_cols = []
    
    # Priority 1: Broad sweep for "100" without kcal
    for b in boxes:
        t = b["raw_text"].lower()
        if "100" in t and "kcal" not in t and "kj" not in t:
            center_x = b["x"]
            width = max(b["x_max"] - b["x_min"], 100)
            priority_cols.append({"col_x": center_x, "tolerance": width})
            
    # Fallback: Densest vertical grouping of numeric boxes
    if not priority_cols:
        x_coords = []
        for b in boxes:
            t = normalize_text(b["raw_text"]).replace(',', '.')
            if re.search(r'\d', t):
                x_coords.append(b["x"])
        if x_coords:
            hist, bin_edges = np.histogram(x_coords, bins=max(2, len(x_coords)//2))
            densest_bin = np.argmax(hist)
            fallback_center = (bin_edges[densest_bin] + bin_edges[densest_bin+1])/2
            fallback_cols.append({"col_x": fallback_center, "tolerance": 150})
            
    return {"priority": priority_cols, "fallback": fallback_cols}

def passes_sanity(field: str, val: float) -> bool:
    limits = {"sugar_g": 100, "salt_g": 10, "protein_g": 100, "fat_g": 100, 
              "saturated_fat_g": 100, "carbohydrate_g": 100, "fiber_g": 100, "calories_kcal": 1000}
    if field in limits:
        return 0 <= val <= limits[field]
    return True

def is_typical(field: str, val: float) -> bool:
    typical_ranges = {
        "sugar_g": (0.0, 30.0),
        "salt_g": (0.0, 3.0),
        "protein_g": (0.0, 30.0),
        "fat_g": (0.0, 30.0),
        "saturated_fat_g": (0.0, 15.0),
        "carbohydrate_g": (0.0, 60.0),
        "fiber_g": (0.0, 15.0),
        "calories_kcal": (5.0, 500.0)
    }
    if field in typical_ranges:
        low, high = typical_ranges[field]
        return low <= val <= high
    return True

def score_candidates(boxes: List[Dict]) -> Dict[str, float]:
    cols = detect_columns(boxes)
    if DEBUG: print(f"[DEBUG] Detected Cols: {cols}")
    
    keyword_map = {
        "saturated_fat_g": ["saturates", "doymuş", "doymus"], "sugar_g": ["sugars", "sugar", "şeker", "seker"],
        "calories_kcal": ["kcal", "energy", "enerji", "ener"], "fat_g": ["fat", "yağ", "lipides"],
        "carbohydrate_g": ["carbohydrate", "karbonhidrat", "carb", "glucides"], "fiber_g": ["fibre", "fiber", "lif"],
        "protein_g": ["protein", "proteines", "zülal"], "salt_g": ["salt", "sodium", "tuz", "sodyum"]
    }
    
    # Normalize
    for b in boxes: b["text"] = normalize_text(b["raw_text"])

    extracted = {}
    
    # Strictly isolate headers so 100 ml doesn't enter parser
    header_boxes = []
    for b in boxes:
        t = b["text"]
        if "100" in t and "kcal" not in t and "kj" not in t:
            header_boxes.append(b)
            
    for field, keywords in keyword_map.items():
        # Find keyword locations
        kw_boxes = [b for b in boxes if any(kw in b["text"] for kw in keywords)]
        if not kw_boxes: continue
        kw_box = kw_boxes[0] # assume first matched is header
        kw_y, kw_x = kw_box["y"], kw_box["x"]
        
        candidates = []
        for b in boxes:
            if b in header_boxes: continue
            
            # Penalize heavily if the number box is clearly to the left of the keyword (like "18as")
            # In LTR labels, numbers are almost always right or bottom-right of the keyword
            pos_penalty = 0
            if b["x"] < kw_x - 50:
                pos_penalty = -500
            
            txt = b["text"].replace(',', '.')
            if field == "calories_kcal" and "kj" in txt and "kcal" not in txt: continue
            
            m = None
            if field == "calories_kcal":
                m = re.search(r'(\d+\.\d+|\d+)\s*kcal', txt)
                if not m: m = re.search(r'(\d+\.\d+|\d+)', txt)
            else:
                m = re.search(r'(\d+\.\d+|\d+)', txt)
                
            if not m: continue
            
            try: base_val = float(m.group(1))
            except: continue
            
            if base_val == 0.0:
                vals_to_test = [0.0]
            else:
                # Intelligent decimal parsing
                digits_only = re.sub(r'[^0-9]', '', m.group(1))
                if digits_only:
                    lz = len(digits_only) - len(digits_only.lstrip('0'))
                    vals_to_test = [base_val, base_val/10.0, base_val/100.0, base_val/1000.0]
                    # Direct hint: if there are leading zeros perfectly matching division
                    if lz > 0 and base_val >= 1.0:
                        vals_to_test.append(base_val / (10 ** lz))
                else:
                    vals_to_test = [base_val, base_val/10.0, base_val/100.0, base_val/1000.0]
                
            for val in list(dict.fromkeys(vals_to_test)):
                # --- EVALUATE GATEKEEPER ---
                if not passes_sanity(field, val):
                    if DEBUG: print(f"[REJECT] {field} -> C:{val} from B:{base_val} (Reason: Failed Sanity)")
                    continue
                    
                score = pos_penalty
                
                # Line Match (+500)
                if abs(b["y"] - kw_y) < 30: score += 500
                
                # Column Alignment (+400)
                aligned = False
                for c in cols["priority"]:
                    if abs(b["x"] - c["col_x"]) <= c["tolerance"] * 1.5: aligned = True; break
                if aligned: score += 400
                elif not cols["priority"]:
                    for c in cols["fallback"]:
                        if abs(b["x"] - c["col_x"]) <= c["tolerance"]: aligned = True; break
                    if aligned: score += 200
                    
                # Proximity (+0 to 100)
                dist = np.sqrt((b["x"] - kw_x)**2 + (b["y"] - kw_y)**2)
                dist_score = 100.0 / (1.0 + (dist/50.0))
                score += dist_score
                
                # Typical Realistic Expectation (+150)
                if is_typical(field, val):
                    score += 150
                
                # Confidence (+0 to 20)
                score += (b["conf"] * 20.0)
                
                # Absolute Unit-Lock Bonus (+1000)
                # If reading Kalori, and the raw text physically contains 'kcal', it is an absolute match.
                if field == "calories_kcal" and "kcal" in b["text"]:
                    score += 1000
                
                # Tie break bonus: Explicit dot match ONLY if actual decimal found
                if val == base_val and '.' in m.group(1):
                    score += 50
                    
                # Tie break bonus: Direct intelligent division derived from Leading Zeroes
                if val != base_val and val == (base_val / (10 ** lz)) if 'lz' in locals() else False:
                    score += 50
                
                candidates.append({"val": val, "score": score, "str": b["text"]})
            
        if candidates:
            candidates.sort(key=lambda c: c["score"], reverse=True)
            best = candidates[0]
            extracted[field] = best["val"]
            if DEBUG:
                print(f"[DEBUG] WINNER: {field} -> {best['val']} (Score: {best['score']:.1f})")
                
    return extracted

def analyze_food_label(image_path: str) -> Dict:
    try:
        cropped_img = scout_and_crop(image_path)
        boxes = high_fidelity_ocr(cropped_img)
        final_data = score_candidates(boxes)
        
        schema_fields = ["sugar_g", "salt_g", "protein_g", "fat_g", "saturated_fat_g", 
                         "carbohydrate_g", "fiber_g", "calories_kcal"]
        readable_tr_map = {
            "sugar_g": "Şeker (g)", "salt_g": "Tuz (g)", "protein_g": "Protein (g)",
            "fat_g": "Yağ (g)", "saturated_fat_g": "Doymuş Yağ (g)",
            "carbohydrate_g": "Karbonhidrat (g)", "fiber_g": "Lif (g)", "calories_kcal": "Kalori (kcal)"
        }
        
        data_output = {}
        readable_tr_output = {}
        for f in schema_fields:
            val = float(final_data.get(f, 0.0))
            data_output[f] = val
            readable_tr_output[readable_tr_map[f]] = val
            
        return {"data": data_output, "readable_tr": readable_tr_output}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    test_img = sys.argv[1] if len(sys.argv) > 1 else "testgorsel.jpg"
    
    if os.path.exists(test_img):
        print(f"Analyzing {test_img} via HEURISTIC ENGINE...")
        result = analyze_food_label(test_img)
        print("\n=== FINAL JSON OUTPUT ===")
        print(json.dumps(result, ensure_ascii=False, indent=2))
        print("==========================\n")
        
        if SAVE_OUTPUT:
            with open("sonuc.json", "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
    else:
        print(f"HATA: '{test_img}' adlı görsel bulunamadı!")

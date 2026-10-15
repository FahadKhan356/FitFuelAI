#!/usr/bin/env python3
"""
FitFuel AI — Open Food Facts Bulk Importer
Run:
    pip install pandas supabase python-dotenv
Then:
    python3 import_foods.py
"""

import os
import sys
import math
import pandas as pd
from dotenv import load_dotenv

# Try importing supabase
try:
    from supabase import create_client
except ImportError:
    # Fallback to requests or httpx if supabase package is missing
    create_client = None

load_dotenv()

# ── Config ────────────────────────────────────────────────────────────
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://aijdrpisjamcspptrpiu.supabase.co')
# Use Service Role Key if available, else Anon Key
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_ANON_KEY')

# Check both Desktop and local workspace path for Open Food Facts CSV
CSV_CANDIDATES = [
    '/Users/aktivacity/Desktop/en.openfoodfacts.org.products.csv',
    'en.openfoodfacts.org.products.csv',
    os.path.expanduser('~/Desktop/en.openfoodfacts.org.products.csv'),
]

CSV_PATH = next((p for p in CSV_CANDIDATES if os.path.exists(p)), None)
BATCH_SIZE = 500
MAX_ROWS = int(os.getenv('MAX_ROWS', '200000')) # default 200k rows

# ── Columns we need ───────────────────────────────────────────────────
COLS = [
    'product_name',
    'brands',
    'countries_en',
    'energy-kcal_100g',
    'proteins_100g',
    'carbohydrates_100g',
    'fat_100g',
    'fiber_100g',
    'sugars_100g',
    'sodium_100g',
    'potassium_100g',
    'image_url',
    'code',
]

def normalize_key(text):
    """Lowercase + trim + single spaces — prevents duplicate cache entries"""
    if not text:
        return ''
    return ' '.join(str(text).lower().strip().split())

def safe_float(val, multiplier=1.0):
    """Safe numeric conversion"""
    try:
        f = float(val)
        if math.isnan(f) or math.isinf(f):
            return 0.0
        return round(f * multiplier, 2)
    except (ValueError, TypeError):
        return 0.0

def main():
    if not CSV_PATH:
        print("ERROR: Open Food Facts CSV not found in any of:")
        for c in CSV_CANDIDATES:
            print(f"  - {c}")
        sys.exit(1)

    print(f"Connecting to Supabase at {SUPABASE_URL}...")
    if not create_client:
        print("ERROR: supabase-py library is not installed. Please run: pip install supabase")
        sys.exit(1)

    sb = create_client(SUPABASE_URL, SUPABASE_KEY)

    print(f"Reading CSV: {CSV_PATH}")
    print(f"Target import: {MAX_ROWS:,} rows in batches of {BATCH_SIZE}...")

    chunk_size = 10000
    total_saved = 0
    batch_buffer = []

    reader = pd.read_csv(
        CSV_PATH,
        usecols=COLS,
        low_memory=False,
        chunksize=chunk_size,
        on_bad_lines='skip',
        encoding='utf-8',
        sep='\t', # Open Food Facts uses tab-separated values
    )

    for chunk_num, chunk in enumerate(reader):
        if total_saved >= MAX_ROWS:
            break

        # ── Filter: must have product name and calories ────────────
        chunk = chunk[chunk['product_name'].notna()]
        chunk = chunk[chunk['energy-kcal_100g'].notna()]
        chunk = chunk[chunk['energy-kcal_100g'] > 0]
        chunk = chunk[chunk['energy-kcal_100g'] < 10000] # sanity check

        for _, row in chunk.iterrows():
            if total_saved >= MAX_ROWS:
                break

            food_name = str(row['product_name']).strip()
            if len(food_name) < 2:
                continue

            record = {
                'search_key': normalize_key(food_name),
                'food_name': food_name,
                'country_code': 'GLOBA',
                'serving_quantity': 100,
                'serving_unit': 'grams',
                'calories': safe_float(row['energy-kcal_100g']),
                'protein_g': safe_float(row['proteins_100g']),
                'carbs_g': safe_float(row['carbohydrates_100g']),
                'fat_g': safe_float(row['fat_100g']),
                'fiber_g': safe_float(row['fiber_100g']),
                'sugar_g': safe_float(row['sugars_100g']),
                'sodium_mg': safe_float(row['sodium_100g'], 1000), # g -> mg
                'potassium_mg': safe_float(row.get('potassium_100g', 0), 1000),
                'source': 'open_food_facts',
                'accuracy_warning': False,
            }

            batch_buffer.append(record)

            # Insert when batch is full or reached target limit
            effective_batch_size = min(BATCH_SIZE, MAX_ROWS - total_saved)
            if len(batch_buffer) >= effective_batch_size:
                to_insert = batch_buffer[:effective_batch_size]
                try:
                    sb.table('food_items').insert(to_insert).execute()
                    total_saved += len(to_insert)
                    print(f"[{total_saved:,}/{MAX_ROWS:,}] Saved {len(to_insert)} rows...")
                    batch_buffer = batch_buffer[effective_batch_size:]
                except Exception as e:
                    print(f" Batch error: {e}")
                    batch_buffer = [] # continue without crashing

        if total_saved >= MAX_ROWS:
            break

    # Insert remaining
    if batch_buffer and total_saved < MAX_ROWS:
        remaining = batch_buffer[:MAX_ROWS - total_saved]
        try:
            sb.table('food_items').insert(remaining).execute()
            total_saved += len(remaining)
            print(f"Final batch: Saved {len(remaining)} rows.")
        except Exception as e:
            print(f"Final batch error: {e}")

    print(f"\nDONE! Successfully imported {total_saved:,} foods into Supabase food_items.")

if __name__ == '__main__':
    main()

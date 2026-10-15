-- Widen country_code if needed
ALTER TABLE public.food_items ALTER COLUMN country_code TYPE VARCHAR(10);

-- Full-text search index for smart partial matching on food_items
ALTER TABLE public.food_items ADD COLUMN IF NOT EXISTS search_vector tsvector GENERATED ALWAYS AS (to_tsvector('english', food_name)) STORED;

CREATE INDEX IF NOT EXISTS idx_food_fts ON public.food_items USING gin(search_vector);

-- Basic index on search_key
CREATE INDEX IF NOT EXISTS idx_food_search_key ON public.food_items (search_key);

-- Verify count
SELECT COUNT(*) FROM public.food_items;

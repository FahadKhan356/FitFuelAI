-- ============================================================
-- RPC: get_weekly_summary
-- Returns the past 7 days of calories, water, and protein ending on p_end_date.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_weekly_summary(
  p_user_id UUID,
  p_end_date DATE
)
RETURNS TABLE (
  date DATE,
  calories INT,
  water_ml INT,
  protein_g DOUBLE PRECISION,
  activity TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH days AS (
    SELECT generate_series(p_end_date - INTERVAL '6 days', p_end_date, INTERVAL '1 day')::date AS d
  )
  SELECT
    days.d AS date,
    COALESCE(m.cals, 0)::INT AS calories,
    COALESCE(w.amount, 0)::INT AS water_ml,
    COALESCE(m.prot, 0)::DOUBLE PRECISION AS protein_g,
    'normal'::TEXT AS activity
  FROM days
  LEFT JOIN (
    SELECT 
      m_inner.date,
      SUM(m_inner.total_calories) AS cals,
      SUM(mi.protein) AS prot
    FROM public.meals m_inner
    LEFT JOIN public.meal_items mi ON mi.meal_id = m_inner.id
    WHERE m_inner.user_id = p_user_id AND m_inner.date >= p_end_date - INTERVAL '6 days' AND m_inner.date <= p_end_date
    GROUP BY m_inner.date
  ) m ON m.date = days.d
  LEFT JOIN (
    SELECT 
      w_inner.date,
      SUM(w_inner.amount_ml) AS amount
    FROM public.water_intake w_inner
    WHERE w_inner.user_id = p_user_id AND w_inner.date >= p_end_date - INTERVAL '6 days' AND w_inner.date <= p_end_date
    GROUP BY w_inner.date
  ) w ON w.date = days.d
  ORDER BY days.d ASC;
END;
$$;

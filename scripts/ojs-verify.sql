SELECT
  CURRENT_USER(),
  COALESCE(
    (SELECT path FROM journals WHERE enabled = 1 ORDER BY journal_id LIMIT 1),
    ''
  );

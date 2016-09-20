
-- Simpler, and cleaner
DROP TABLE randomTable;
CREATE TABLE randomTable(id serial PRIMARY KEY, description text);
CREATE OR REPLACE FUNCTION getNArrayS(el text[], count int) RETURNS text AS $$
  SELECT string_agg(el[random()*(array_length(el,1)-1)+1], ' ') FROM generate_series(1,count) g(i)
$$
VOLATILE
LANGUAGE SQL;

WITH t(ray) AS(
  SELECT (string_to_array(pg_read_file('words.list')::text,E'\n')) 
) 
INSERT INTO randomTable(description)
SELECT getNArrayS(T.ray, 3) FROM T, generate_series(1,10000);

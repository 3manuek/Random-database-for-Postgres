
-- Copy the words text file into your data directory
-- # cp cp /usr/share/dict/words data/pg95/words.list

-- Simpler, and cleaner
DROP TABLE randomTable;

CREATE TABLE randomTable(id serial PRIMARY KEY, description text);
CREATE INDEX ON randomTable USING GIN(to_tsvector('english',description));


CREATE OR REPLACE FUNCTION getNArrayS(el text[], count int) RETURNS text AS $$
  SELECT string_agg(el[random()*(array_length(el,1)-1)+1], ' ') FROM generate_series(1,count) g(i)
$$
VOLATILE
LANGUAGE SQL;

WITH t(ray) AS(
  SELECT (string_to_array(pg_read_file('words.list')::text,E'\n')) 
) 
INSERT INTO randomTable(description)
-- For a fixed size of phrase , use getNArrayS(array, <num>)
SELECT getNArrayS(T.ray, round(random()*5+1)::int) FROM T, generate_series(1,10000);


-- First, copy the words dictionary into your data directory
--  i.e. cp /usr/share/dict/words data/pg95/words.list
-- More details: http://stackoverflow.com/questions/39480580/how-to-index-a-string-array-column-for-pg-trgm-term-any-array-column-que
CREATE EXTENSION pg_trgm;

-- Obtiene un array de texto y un tope, retorna esa cantidad de palabras en un array
CREATE OR REPLACE FUNCTION getNArray(el text[], count int) RETURNS text[] AS $$
  SELECT array_agg(el[random()*(array_length(el,1)-1)+1]) FROM generate_series(1,count) g(i)
$$
VOLATILE
LANGUAGE SQL;

DROP TABLE testGin;
CREATE TABLE testGin(id serial PRIMARY KEY, array_column text[]);

-- Creo el array de palabras:
WITH t(ray) AS(
  SELECT (string_to_array(pg_read_file('words.list')::text,E'\n')) 
) 
INSERT INTO testGin(array_column)
-- Se puede tambien hacer getNArray(T.array,round(random()*10)) 
SELECT getNArray(T.ray, 4) FROM T, generate_series(1,100000);       

CREATE INDEX ON testGin USING GIN(array_to_string(array_column, ' ') gin_trgm_ops);

-- la magia:
CREATE OR REPLACE FUNCTION f(arr text[]) RETURNS text AS $$
   SELECT arr::text
 LANGUAGE SQL IMMUTABLE;

CREATE INDEX ON testGin USING GIN(f(array_column) gin_trgm_ops);


-- Index usage:
-- postgres=# EXPLAIN SELECT id FROM testgin WHERE f(array_column) ilike '%test%';
--                                   QUERY PLAN                                   
-- -----------------------------------------------------------------------------
--  Bitmap Heap Scan on testgin  (cost=34.82..1669.63 rows=880 width=4)
--   Recheck Cond: (f(array_column) ~~* '%test%'::text)
--   ->  Bitmap Index Scan on testgin_f_idx  (cost=0.00..34.60 rows=880 width=0)
--         Index Cond: (f(array_column) ~~* '%test%'::text)
-- (4 rows)

-- postgres=# explain SELECT id, array_column FROM testgin 
--   WHERE 'response' % ANY (array_column) and f(array_column) ~ 'response';
--                                  QUERY PLAN                                  
-- ----------------------------------------------------------------------------
-- Bitmap Heap Scan on testgin  (cost=76.08..120.38 rows=1 width=85)
--   Recheck Cond: (f(array_column) ~ 'response'::text)
--   Filter: ('response'::text % ANY (array_column))
--   ->  Bitmap Index Scan on testgin_f_idx  (cost=0.00..76.08 rows=11 width=0)
--         Index Cond: (f(array_column) ~ 'response'::text)
-- (5 rows)

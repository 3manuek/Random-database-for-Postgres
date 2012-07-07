Random-database-for-Postgres
============================

Just a code to generate random data in the database but with some coherence. Compatible with > 8.4.


Some Details
============

This code will generate a database with several random values with references and partitioning. TAke in mind 
that the way of partitioning here is only for test purposes, in the real life will be a chaos partitioning 
using this kind of check constraints due to:

SELECT * FROM dia4.persona WHERE DNI = 22345543 AND DNI/100000 = 223;

As you can see, you need to add the condition of the check to allow using searching through partitions, which 
could be un-extensible and expensive for code maintenance. 

I used this way in this example just to experimental purposes, but the normal use is a range of timestamp or serial.

In this script, if you want more data, just raise the generate_series 2nd parameter. Takes time to generate the 
data, but is a nice tool for test.

I used this code for some trainings and the main objetive is to have a database with some complexity to query on.


Some future changes that I want to commit
=========================================

<code>

-- - Llave compuesta DNI con tipo:

dia4=# CREATE TYPE tipo_doc AS ENUM('DNI','Pasaporte','LC');
CREATE TYPE
dia4=# CREATE TYPE doc_comp AS (tipo tipo_doc, num bigint);
CREATE TYPE
dia4=# CREATE TABLE prueba (documento doc_comp PRIMARY KEY);
NOTICE:  CREATE TABLE / PRIMARY KEY creará el índice implícito «prueba_pkey» para la tabla «prueba»
CREATE TABLE
dia4=# INSERT INTO prueba VALUES(('DNI',123455));
INSERT 0 1
dia4=# SELECT * FROM prueba ;
  documento  
--------------
 (DNI,123455)
(1 fila)
dia4=# SELECT (documento::doc_comp) FROM prueba ;
  documento  
--------------
 (DNI,123455)
(1 fila)
dia4=# SELECT (documento::doc_comp).num FROM prueba ;
  num  
--------
 123455
(1 fila)
dia4=# SELECT (documento::doc_comp).tipo FROM prueba ;
 tipo
------
 DNI
(1 fila)

</code>
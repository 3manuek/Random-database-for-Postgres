Random-database-for-Postgres
============================

Just a code to generate random data in the database but with some coherence. Compatible with > 8.4.

The idea of this script is to test or use for educational purposes. The difference of this script is that the 
data is being generated on the fly, so you may expect some kind of overhead. 

NOTE:
https://github.com/pvh/postgresql-sample-database (Isis.sql) is a nice project and has more data types. I recommend
to collaborate on this one instead this (code needs some clean up and translation from spanish).

Some Details
============

This code will generate a database with several random values with references and partitioning. 

You must consider that the following way of partitioning is only  for test purposes. In the real cases will be a 
chaos use partitioning with this kind of constraint checks as follows:

SELECT * FROM dia4.persona WHERE DNI = 22345543 AND DNI/100000 = 223;

In the previous examples, we are filtering using a weird condition which can be unextensible and expensive for 
code maintenance. 

In this script, if you want more data, just raise the generate_series 2nd parameter. Takes time to generate the 
data, but is a nice tool for test.

I used this code for some trainings and the main objetive is to have a database with some complexity to query on.


Some future changes that I want to commit
=========================================

- Easy configurable amount of rows
- More weird things
- Full text search colums for testing
- Laboratory data types or unstable features (yes, we *can*!)

<pre>

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

</pre>

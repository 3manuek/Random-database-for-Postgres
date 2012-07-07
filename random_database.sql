
\c template1

DROP DATABASE coches;

CREATE DATABASE coches;

\c coches

--CREATE LANGUAGE plpgsql; --viene por defecto en 9.0

CREATE DOMAIN dni  AS bigint  CHECK (VALUE > 0);

CREATE TYPE grav    AS ENUM ('GRAVE','MEDIO','LEVE');

--Queremos implementar tipo de doc y numero como un solo tipo de datos?
CREATE TYPE tipo_doc AS ENUM('DNI','Pasaporte','LC','LE','Cedula');

CREATE DOMAIN id_emp AS CHAR(4);

CREATE DOMAIN sexo AS CHAR(1) CHECK ( upper(VALUE) IN ('F', 'M','I'));


CREATE TYPE doc_comp AS (tipo tipo_doc, num dni);

DROP SCHEMA IF EXISTS dia4 CASCADE;

CREATE SCHEMA dia4;

--CREATE TYPE empresa AS ENUM ('FORD','FIAT','SEAT');


CREATE TABLE dia4.persona (
    dni         dni PRIMARY KEY,
    nombre      text NOT NULL,
    apellido    text NOT NULL,
    sexo        sexo,
    fecha_nac   date CHECK (fecha_nac < now()::date),
    observ      text,
    salario     NUMERIC(8,2) );

-- No usada aun, pero la idea es usarlo en persona	
CREATE OR REPLACE FUNCTION cuil (cuil bigint) RETURNS boolean AS
$CUIL$
DECLARE
	RES BIGINT;
	DIG BIGINT;
	NUM BIGINT;
BEGIN
	IF LENGTH(cuil::text) != 11 OR SUBSTR(cuil::text, 1, 2) = '00' THEN
		RETURN 0;
	END IF;
	RES = 0;
	FOR I IN 1..10 LOOP
		NUM := (SUBSTR(cuil::text, I, 1))::bigint;
		IF (I = 1 OR I = 7) THEN RES := RES + NUM * 5;
		ELSIF (I = 2 OR I = 8) THEN RES := RES + NUM * 4;
		ELSIF (I = 3 OR I = 9) THEN RES := RES + NUM * 3;
		ELSIF (I = 4 OR I = 10) THEN RES := RES + NUM * 2;
		ELSIF (I = 5) THEN RES := RES + NUM * 7;
		ELSIF (I = 6) THEN RES := RES + NUM * 6;
		END IF;
	END LOOP;
	DIG := 11 - MOD(RES,11);
	IF DIG = 11 THEN 
		DIG := 0;
	END IF;
    
	IF DIG = (SUBSTR(cuil::text,11,1))::bigint THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END;
$CUIL$ LANGUAGE 'plpgsql'
IMMUTABLE CALLED ON NULL INPUT SECURITY INVOKER;

COMMENT ON FUNCTION "public"."validar_cuil"(bigint)
IS 'Valida el cuil segun formato 99999999999
Devuelve 0 para los cuil No V�lidos
Devuelve 1 para los cuil V�lidos';

CREATE DOMAIN cuil AS bigint CHECK(cuil(VALUE));

	
CREATE OR REPLACE FUNCTION actualiza_sexo() RETURNS trigger AS $BADI$
DECLARE
BEGIN
    IF NEW.sexo IS NOT NULL THEN
        RETURN NEW;
    END IF;

    IF (NEW.nombre ~ $e$o$$e$) THEN
        NEW.sexo := 'M';
    ELSE
        NEW.sexo := 'F';
    END IF;
    RETURN NEW;
END;
$BADI$ VOLATILE LANGUAGE plpgsql;

CREATE TRIGGER T_actualiza_sexo BEFORE INSERT OR UPDATE ON dia4.persona
    FOR EACH ROW EXECUTE PROCEDURE actualiza_sexo();

CREATE TABLE dia4.empresas (
    id_emp      id_emp PRIMARY KEY,
    nombre_emp  text,
    pais        text
);    
    
CREATE TABLE dia4.coche (
    id_coche    serial PRIMARY KEY,
    id_emp      id_emp REFERENCES dia4.empresas,
    modelo      text );


CREATE TABLE dia4.patentes (
    dni         dni    ,--REFERENCES dia4.persona,
    id_coche    bigint REFERENCES dia4.coche,
    patente     CHAR(6) PRIMARY KEY,
    region      CHAR(3) CHECK ( region IN('EXT','NAC') ),
    anno        date );

CREATE TABLE dia4.infraccion (
    patente         CHAR(6) REFERENCES dia4.patentes,
    fecha           date,
    gravedad        grav );

CREATE TABLE dia4.veraz (
    dni         dni REFERENCES dia4.persona UNIQUE,
    desde       date,
    descripcion text
 );


CREATE OR REPLACE FUNCTION part() RETURNS TRIGGER AS $part$
DECLARE
     milion integer;
     factor int := 100000;
BEGIN
     select NEW.dni / factor into milion;
    BEGIN
        EXECUTE 'INSERT INTO dia4.persona_' || milion || ' SELECT (' || QUOTE_LITERAL(NEW) || '::dia4.persona).*' ;
    EXCEPTION
    WHEN undefined_table THEN
          EXECUTE 'CREATE TABLE dia4.persona_' || milion ||
          '(CHECK (dni / ' || factor || ' = ' || milion || '), PRIMARY KEY (dni)) INHERITS (dia4.persona);';
          EXECUTE 'INSERT INTO dia4.persona_' || milion || ' SELECT (' || QUOTE_LITERAL(NEW) || '::dia4.persona).*' ;
    END;
  RETURN NULL;
END
$part$ LANGUAGE plpgsql;    

CREATE TRIGGER part_maestra BEFORE INSERT ON dia4.persona FOR EACH ROW EXECUTE PROCEDURE part();



-- INSERCION DE DATOS

INSERT INTO dia4.persona(dni,nombre,apellido,fecha_nac,salario) (
    SELECT
        i::dni,
        ('{Romulo,Ricardo,Romina,Fabricio,Francisca,Noa,Silvia,Priscila,Tiziana,Ana,Horacio,Nayara,Mario}'::text[])[round(random()*12+1)] as nombre,
        ('{Perez,Ortigoza,Tucci,Smith,Fernandez,Samuel,Veloso,Guevara,Calvo,Cantina,Casas,Quesada,Rodriguez,Ike,Baldo,Vespi}'::text[])[round(random()*15+1)] as apellido,  
        (now() - (round(random()*5000+6000)::text || ' days')::interval)::date,                 --fecha_nac
        (random()*10000)::NUMERIC(8,2)                                                          --salario
        FROM generate_series(20000000,22000000) i(i));


INSERT INTO dia4.empresas VALUES('OPEL','Wi leben motors','Germany'),('FORD','Ford Industries','Germany'),('FIAT','Fab Ita AT','Italy'),('SEAT','S Espa�ola AuTo','Spain');


INSERT INTO dia4.coche(id_emp, modelo) (
    SELECT
        --(((SELECT array_agg(enumlabel) FROM pg_enum where enumtypid = 'empresa'::regtype)::text[])[round(random()*2+1)])::empresa,
        (SELECT id_emp FROM dia4.empresas ORDER BY random() LIMIT 1),
        round(random()*1000)::text
    FROM
        generate_series(1,200)
);

--DROP FUNCTION retorna_persona_aleatoria();

CREATE OR REPLACE FUNCTION retorna_persona_aleatoria() RETURNS dni AS $BODY$
SELECT dni FROM dia4.persona order by random() limit 1
$BODY$
LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION retorna_coche_aleatorio() RETURNS integer AS $BODY$
SELECT id_coche FROM dia4.coche order by random() limit 1
$BODY$
LANGUAGE sql VOLATILE;

-- Se podr�a utilizar desde el fuente el retorno de datos, pero de esta forma,
-- permite la posibilidad de que una persona posea m�s de dos coches.
INSERT INTO dia4.patentes (
    SELECT
        retorna_persona_aleatoria(),                                --dni
        retorna_coche_aleatorio(),                                  --id_coche
        substr(upper((random()*10000000)::text),0,7),               --patente
        ('{EXT,NAC}'::text[])[round(random()*1+1)],                 --region
        (now() - (round(random()*10) || ' years')::interval)::date  --anno
        FROM
            generate_series(1,300)
);


INSERT INTO dia4.infraccion (
    SELECT patente,
           (now() - (round(random()*100) || ' days')::interval)::date,
           ((SELECT array_agg(enumlabel) FROM pg_enum where enumtypid = 'grav'::regtype)::grav[])[round(random()*2+1)]::grav
        FROM
            (SELECT patente FROM dia4.patentes ORDER BY random() LIMIT 30) pat
);

INSERT INTO dia4.veraz(dni,desde) (
    SELECT
        dni,
        (now() - (round(random()*100) || ' days')::interval)::date
    FROM  
        (SELECT dni FROM dia4.persona ORDER BY random() LIMIT 70 ) per
);


--
-- Sacar Modelos Repetidos, simplemente agrega una C. REVISAR.
--
UPDATE dia4.coche
    SET modelo = (modelo || 'C')::text
    WHERE (id_emp,modelo) IN
                         (SELECT id_emp, modelo
                               FROM dia4.coche
                                GROUP BY id_emp, modelo having count(*) >1
                                ORDER BY id_emp, modelo);


-----------------------------------------------------------------------------------                                       
-- FIN INSERCIONES --
-----------------------------------------------------------------------------------
                                        

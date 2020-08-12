-- Cerinta numarul 6

CREATE OR REPLACE PACKAGE pachet 
AS
  TYPE tablou_indexat IS TABLE OF movie%ROWTYPE INDEX BY BINARY_INTEGER;
END;
/

CREATE OR REPLACE FUNCTION functiamea(v_lname ACTOR.ACT_LNAME%TYPE)
  RETURN pachet.tablou_indexat 
AS
  my_table pachet.tablou_indexat;

BEGIN
  SELECT * BULK COLLECT INTO my_table
  FROM movie
  WHERE MOV_ID IN ( SELECT MOV_ID
                    FROM MOVIE_CAST
                    WHERE ACT_ID = (  SELECT ACT_ID
                                      FROM ACTOR
                                      WHERE LOWER(ACT_LNAME) = LOWER(v_lname)
                                    )
                  );
  RETURN my_table;
END;
/

DECLARE
  tabelul_meu pachet.tablou_indexat;
BEGIN
  tabelul_meu := functiamea('farmiga');
  IF tabelul_meu.COUNT = 0 THEN DBMS_OUTPUT.PUT_LINE('Acest actor nu a fost gasit sau nu joaca in niciun film!');
  ELSE
    FOR i IN tabelul_meu.FIRST .. tabelul_meu.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(tabelul_meu(i).mov_title || ' ' || tabelul_meu(i).mov_year); 
    END LOOP;
  END IF;
END;
/

-- Cerinta numarul 7

CREATE OR REPLACE PROCEDURE ACTORI_FILME
AS
BEGIN
  DECLARE
    v_fname ACTOR.ACT_FNAME%TYPE;
    v_lname ACTOR.ACT_LNAME%TYPE;
    v_nr NUMBER(6);
    CURSOR cursorul_meu IS
      SELECT a.ACT_FNAME, a.ACT_LNAME, COUNT(c.MOV_ID)
      FROM MOVIE m JOIN MOVIE_CAST c ON m.MOV_ID = c.MOV_ID  JOIN ACTOR a ON c.ACT_ID = a.ACT_ID
      GROUP BY a.ACT_FNAME, a.ACT_LNAME
      HAVING COUNT(c.MOV_ID)>=2;
  BEGIN
    OPEN cursorul_meu;
      LOOP
        FETCH cursorul_meu INTO v_fname, v_lname, v_nr;
        EXIT WHEN cursorul_meu%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Actorul ' || v_fname || ' ' || v_lname || ' a jucat in ' || v_nr || ' filme.');
      END LOOP;
    CLOSE cursorul_meu;
  END;  
END;
/

EXECUTE ACTORI_FILME;


-- Cerinta numarul 8


CREATE OR REPLACE PACKAGE PACHET_GEN_FILM
AS
  TYPE TABEL_GEN IS VARRAY(5) OF GENRES.GEN_TITLE%TYPE;
END;
/

CREATE OR REPLACE FUNCTION genurile_filmului(v_title MOVIE.MOV_TITLE%TYPE DEFAULT 'Miracle in cell no. 7')
RETURN PACHET_GEN_FILM.TABEL_GEN AS GEN PACHET_GEN_FILM.TABEL_GEN;
BEGIN
  SELECT GEN_TITLE 
  BULK COLLECT INTO GEN
  FROM   GENRES
  WHERE  GEN_ID IN (SELECT GEN_ID
                    FROM MOVIE_GENRES JOIN MOVIE USING(MOV_ID)
                    WHERE UPPER(MOV_TITLE) = UPPER(v_title)
                    );
  FOR i IN GEN.FIRST .. GEN.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(GEN(i));
  END LOOP;
  RETURN GEN;
  EXCEPTION 
    WHEN TOO_MANY_ROWS THEN 
          DBMS_OUTPUT.PUT_LINE('Exista mai multe filme cu numele dat!');
    WHEN VALUE_ERROR THEN
          DBMS_OUTPUT.PUT_LINE('Filmul nu are niciun gen!');
    WHEN NO_DATA_FOUND THEN 
          DBMS_OUTPUT.PUT_LINE('Nu exista un film cu acest nume!');
    WHEN OTHERS THEN      
          DBMS_OUTPUT.PUT_LINE('Alta eroare!');
END genurile_filmului; 
/

DECLARE
  TABELGEN PACHET_GEN_FILM.TABEL_GEN;
BEGIN
  TABELGEN := genurile_filmului('DEADPOOL');
END;
/

-- Cerinta numarul 9

CREATE OR REPLACE PACKAGE PACHET_TARA_DIR
AS
  TYPE TABEL_TARA IS VARRAY(5) OF COUNTRY.COUNTRY_NAME%TYPE;
END;
/

CREATE OR REPLACE PROCEDURE TARA_DIRECTORILOR(v_lname DIRECTOR.DIR_LNAME%TYPE DEFAULT '')
IS TARA PACHET_TARA_DIR.TABEL_TARA;
BEGIN
  SELECT COUNTRY_NAME 
  BULK COLLECT INTO TARA
  FROM   COUNTRY
  WHERE  COUNTRY_ID IN (SELECT COUNTRY_ID
                    FROM MOVIE_COUNTRY c JOIN MOVIE m ON (m.MOV_ID = c.MOV_ID) JOIN MOVIE_DIRECTION d ON (m.MOV_ID = d.MOV_ID) JOIN DIRECTOR di ON (d.DIR_ID = di.DIR_ID)
                    WHERE UPPER(DIR_LNAME) = UPPER(v_lname)
                    );
  FOR i IN TARA.FIRST .. TARA.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(TARA(i));
  END LOOP;
  EXCEPTION 
    WHEN TOO_MANY_ROWS THEN 
          DBMS_OUTPUT.PUT_LINE('Exista mai multi directori cu numele dat!');
    WHEN NO_DATA_FOUND THEN 
          DBMS_OUTPUT.PUT_LINE('Nu exista un director cu acest nume!');
    WHEN OTHERS THEN      
          DBMS_OUTPUT.PUT_LINE('Alta eroare!');
END TARA_DIRECTORILOR; 
/

BEGIN
 TARA_DIRECTORILOR('MILLER');
END;
/

-- Cerinta numarul 10

CREATE OR REPLACE TRIGGER check_sex
AFTER INSERT OR UPDATE OF ACT_GENDER ON ACTOR
DECLARE
  TYPE LISTA_SEX IS VARRAY(20) OF ACTOR.ACT_GENDER%TYPE;
  LISTA LISTA_SEX;
BEGIN 
SELECT ACT_GENDER 
BULK COLLECT INTO LISTA
FROM ACTOR;
FOR i IN LISTA.FIRST .. LISTA.LAST LOOP
IF (UPPER(LISTA(i)) NOT IN ('M', 'F')) THEN  
      RAISE_APPLICATION_ERROR (-20506, 'Sexul nu exista! Inserati M pentru sexul masculin sau F pentru sexul feminin.'); 
END IF; 
END LOOP;
END;
/

INSERT INTO ACTOR VALUES (11, 'Ryan', 'Gosling', 's');
INSERT INTO ACTOR VALUES (11, 'Ryan', 'Gosling', 'M');

-- Cerinta numarul 11

CREATE OR REPLACE TRIGGER check_year 
BEFORE INSERT OR UPDATE OF MOV_YEAR ON MOVIE
FOR EACH ROW
BEGIN 
IF (:NEW.MOV_YEAR > TO_NUMBER(TO_CHAR(SYSDATE,'yyyy'))) THEN  
      RAISE_APPLICATION_ERROR (-20505, 'Filmul cu anul inserat nu exista inca!'); 
END IF; 
END;
/

INSERT INTO MOVIE VALUES (12, 'Master and commander', 2021);

-- Cerinta numarul 12

CREATE TABLE tabel_trigger_ldd
 ( utilizator VARCHAR2(30),
   nume_bd VARCHAR2(50),
   eveniment VARCHAR2(20),
   nume_obiect VARCHAR2(30),
   data DATE);
   
CREATE OR REPLACE TRIGGER trigger_ldd
AFTER CREATE ON SCHEMA
BEGIN
 INSERT INTO tabel_trigger_ldd
 VALUES (SYS.LOGIN_USER, SYS.DATABASE_NAME, SYS.SYSEVENT,
 SYS.DICTIONARY_OBJ_NAME, SYSDATE);
END;
/

SELECT *
FROM tabel_trigger_ldd;

 CREATE TABLE tabeltest (IDD NUMBER);
 DROP TABLE tabeltest;
 
SELECT *
FROM tabel_trigger_ldd;









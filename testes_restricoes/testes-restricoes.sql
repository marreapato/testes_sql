----- tipos de objetos

CREATE OR REPLACE TYPE tp_endereco AS OBJECT(
    pais varchar2(15),
    cep varchar2(9),
    estado varchar2(15),
    cidade VARCHAR2(20),
    complemento varchar2(30)
);

--DROP TYPE tp_endereco;

CREATE OR REPLACE TYPE TP_FONE AS OBJECT (
    COD_PAIS VARCHAR(3),
    COD_DDD VARCHAR(5),
    PHONE VARCHAR(10)
);

CREATE OR REPLACE TYPE TP_FONES AS VARRAY(3) OF TP_FONE;

--TIPO PESSOA
CREATE OR REPLACE TYPE TP_PASSAGEIRO AS OBJECT(
    PK_CPF VARCHAR2(11),
    NOME VARCHAR2(20),
    SEXO VARCHAR2(1),
    DATA_NASCIMENTO DATE,
    ENDERECO_PAX tp_endereco,
    TELEFONES tp_fones,
    EMAIL VARCHAR2(30),
    MEMBER FUNCTION calcular_idade RETURN NUMBER
    
)NOT FINAL;

-- Corpo da member function calcular_idade para o tipo TP_PASSAGEIRO --
CREATE OR REPLACE TYPE BODY TP_PASSAGEIRO AS
    MEMBER FUNCTION calcular_idade RETURN NUMBER IS
    BEGIN
        RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, self.DATA_NASCIMENTO) / 12);
    END calcular_idade;
END;


CREATE TYPE MAIOR_IDADE_TP UNDER TP_PASSAGEIRO(
);

--DROP TYPE MENOR_IDADE_TP;
CREATE TYPE MENOR_IDADE_TP UNDER TP_PASSAGEIRO(
    autorizacao_viagem varchar2(3)  
);


--DROP TYPE PASSAGEM_TP;
CREATE TYPE PASSAGEM_TP AS OBJECT(    
    pk_numero_passagem INTEGER,
    valor_passagem NUMBER(38,2),
    data_ida DATE,
    data_chegada DATE
);

CREATE TABLE PASSAGEIRO_TB OF TP_PASSAGEIRO(
CONSTRAINT CPF_UNICO_PASSAGEIRO PRIMARY KEY (PK_CPF)
);


CREATE TABLE MENOR_IDADE_TB OF MENOR_IDADE_TP;

CREATE TABLE MAIOR_IDADE_TB OF MAIOR_IDADE_TP;
----

--DROP TABLE PASSAGEM;

CREATE TABLE PASSAGEM OF PASSAGEM_TP(    
    CONSTRAINT numero_passagem_pkey PRIMARY KEY(pk_numero_passagem)
);

CREATE OR REPLACE TYPE tp_ref_relac AS OBJECT(
passageiros REF TP_PASSAGEIRO,
passagem REF PASSAGEM_TP) NOT FINAL;
/
    
CREATE TYPE tp_nt_ref_relac AS TABLE OF tp_ref_relac;
/
    

-- ENTIDADE VOO
CREATE OR REPLACE TYPE VOO_TP AS OBJECT(
    pk_localizador_voo NUMBER(38,0), -- trecho ID
    origem VARCHAR2(3),       -- origem IATA 3
    destino VARCHAR2(3),      -- destino IATA 3
    hora_embarque TIMESTAMP,
    hora_desembarque TIMESTAMP,
    compras tp_nt_ref_relac
);

CREATE TABLE VOO_TABLE OF voo_tp (
    CONSTRAINT pkey_localizador_voo PRIMARY KEY (pk_localizador_voo)

) NESTED TABLE COMPRAS STORE AS LISTA_COMPRAS;

-----

-- Inserting passenger data
INSERT INTO PASSAGEIRO_TB VALUES (
    '12345678901',    -- PK_CPF
    'John Doe',       -- NOME
    'M',              -- SEXO
    TO_DATE('1990-05-15', 'YYYY-MM-DD'),  -- DATA_NASCIMENTO
    tp_endereco('USA', '12345', 'California', 'Los Angeles', 'Apt 123'), -- ENDERECO_PAX
    tp_fones(TP_FONE('001', '123', '4567890')), -- TELEFONES
    'johndoe@example.com'  -- EMAIL
);

-- Inserting another passenger
INSERT INTO PASSAGEIRO_TB VALUES (
    '98765432101',    -- PK_CPF
    'Jane Smith',     -- NOME
    'F',              -- SEXO
    TO_DATE('1985-10-20', 'YYYY-MM-DD'),  -- DATA_NASCIMENTO
    tp_endereco('USA', '54321', 'New York', 'Manhattan', 'Apt 456'), -- ENDERECO_PAX
    tp_fones(TP_FONE('001', '456', '1234567')), -- TELEFONES
    'janesmith@example.com'  -- EMAIL
);

-------------------------------

-- Inserting flight ticket data
INSERT INTO PASSAGEM VALUES (
    1001,          -- pk_numero_passagem
    450.00,        -- valor_passagem
    TO_DATE('2024-05-10', 'YYYY-MM-DD'),  -- data_ida
    TO_DATE('2024-05-15', 'YYYY-MM-DD')   -- data_chegada
);

-- Inserting another flight ticket
INSERT INTO PASSAGEM VALUES (
    1002,          -- pk_numero_passagem
    520.00,        -- valor_passagem
    TO_DATE('2024-06-20', 'YYYY-MM-DD'),  -- data_ida
    TO_DATE('2024-06-25', 'YYYY-MM-DD')   -- data_chegada
);


-- Inserting flight data
INSERT INTO VOO_TABLE VALUES (
    5001,          -- pk_localizador_voo
    'LAX',         -- origem
    'JFK',         -- destino
    TO_TIMESTAMP('2024-05-10 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),  -- hora_embarque
    TO_TIMESTAMP('2024-05-10 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),  -- hora_desembarque
    tp_nt_ref_relac(
        tp_ref_relac(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '12345678901'),
            (SELECT REF(pt) FROM PASSAGEM pt WHERE pt.pk_numero_passagem = 1001)
        ),
        tp_ref_relac(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765432101'),
            (SELECT REF(pt) FROM PASSAGEM pt WHERE pt.pk_numero_passagem = 1002)
        )
    )
);

SELECT * FROM VOO_TABLE;


SELECT
    v.pk_localizador_voo AS flight_id,
    v.origem AS origin,
    v.destino AS destination,
    DEREF(c.passageiros).PK_CPF AS passenger_cpf,
    DEREF(c.passageiros).NOME AS passenger_name,
    DEREF(c.passagem).pk_numero_passagem AS ticket_number,
    DEREF(c.passagem).valor_passagem AS ticket_price,
    DEREF(c.passagem).data_ida AS departure_date,
    DEREF(c.passagem).data_chegada AS arrival_date
FROM
    VOO_TABLE v,
    TABLE(v.compras) c;



SELECT DEREF(C.PASSAGEM).PK_NUMERO_PASSAGEM FROM LISTA_COMPRAS C;

SELECT DEREF(C.PASSAGEM).PK_NUMERO_PASSAGEM,
       COUNT(*) AS occurrence_count
FROM LISTA_COMPRAS C
WHERE C.PASSAGEM IS NOT NULL
GROUP BY DEREF(C.PASSAGEM).PK_NUMERO_PASSAGEM
HAVING COUNT(*) > 1;





SELECT
    v.pk_localizador_voo AS flight_id,
    DEREF(c.passageiros).PK_CPF AS passenger_cpf
FROM
    VOO_TABLE v,
    TABLE(v.compras) c;

----------------
DROP TYPE ESTADIA_TP;
CREATE TYPE ESTADIA_TP AS OBJECT(

 pk_cod_estadia INTEGER,
 valor_estadia NUMBER(38,2),
 data_check_in DATE,
 data_check_out DATE,
 reservas tp_nt_ref_relac
 
);

--DROP TABLE ESTADIA;

SELECT DEREF(r.PASSAGEM).PK_NUMERO_PASSAGEM
FROM ESTADIA e,
     TABLE(e.reservas) r;


DECLARE
    v_count NUMBER;
BEGIN
    -- Iterate over each ESTADIA record
    FOR est IN (SELECT e.pk_cod_estadia
                FROM ESTADIA e
                WHERE (SELECT COUNT(DISTINCT DEREF(r.PASSAGEM).PK_NUMERO_PASSAGEM)
                       FROM TABLE(e.reservas) r) = 1)
    LOOP
        -- Clear the nested table (replace with an empty collection)
        UPDATE ESTADIA e
        SET e.reservas = tp_nt_ref_relac() -- Use the appropriate empty collection type
        WHERE e.pk_cod_estadia = est.pk_cod_estadia;
    END LOOP;

    COMMIT; -- Commit the transaction
END;
/

EXEC SetAttributeToNull(2005,1);

CREATE OR REPLACE PROCEDURE SetAttributeToNull(
    p_estadia_id IN ESTADIA.pk_cod_estadia%TYPE,
    p_index IN NUMBER
) AS
    v_reservas tp_nt_ref_relac; -- Nested table type
    v_ref_relac tp_ref_relac; -- Reference type

BEGIN
    -- Retrieve the nested table for the specified ESTADIA record
    SELECT e.reservas
    INTO v_reservas
    FROM ESTADIA e
    WHERE e.pk_cod_estadia = p_estadia_id;

    -- Check if the index is within the bounds of the nested table
    IF p_index > 0 AND p_index <= v_reservas.COUNT THEN
        -- Get the specific tp_ref_relac() object at the specified index
        v_ref_relac := v_reservas(p_index);

        -- Update the attribute value to NULL (example: setting passageiros attribute to NULL)
        v_ref_relac.passageiros := NULL;

        -- Update the nested table in the ESTADIA record with the modified object
        v_reservas(p_index) := v_ref_relac;

        -- Update the ESTADIA record with the modified nested table
        UPDATE ESTADIA e
        SET e.reservas = v_reservas
        WHERE e.pk_cod_estadia = p_estadia_id;

        COMMIT; -- Commit the transaction
        DBMS_OUTPUT.PUT_LINE('Attribute set to NULL successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Invalid index.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/



-- Inserting more reservation data into ESTADIA table
INSERT INTO ESTADIA VALUES (
    2005,          -- pk_cod_estadia
    400.00,        -- valor_estadia
    TO_DATE('2024-08-15', 'YYYY-MM-DD'),  -- data_check_in
    TO_DATE('2024-08-20', 'YYYY-MM-DD'),  -- data_check_out
    tp_nt_ref_relac(
        tp_ref_relac(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765432101'),
            (SELECT REF(pt) FROM PASSAGEM pt WHERE pt.pk_numero_passagem = 1001)
        )
    )
);


SELECT
    e.pk_cod_estadia AS stay_id,
    e.valor_estadia AS stay_cost,
    e.data_check_in AS check_in_date,
    e.data_check_out AS check_out_date,
    DEREF(r.passageiros).PK_CPF AS passenger_cpf,
    DEREF(r.passageiros).NOME AS passenger_name,
    DEREF(r.passagem).pk_numero_passagem AS ticket_number,
    DEREF(r.passagem).valor_passagem AS ticket_price,
    DEREF(r.passagem).data_ida AS departure_date,
    DEREF(r.passagem).data_chegada AS arrival_date
FROM
    ESTADIA e,
    TABLE(e.reservas) r;
------------

CREATE OR REPLACE TYPE tp_ref_registrada AS OBJECT(
passageiros REF TP_PASSAGEIRO,
estadias REF ESTADIA_TP) NOT FINAL;
/
    
CREATE TYPE tp_nt_ref_registrada AS TABLE OF tp_ref_registrada;
/


-- ENTIDADE HOTEL
CREATE TYPE HOTEL_TP AS OBJECT(

    pkid_hotel INTEGER,
    nome VARCHAR2(30),
    endereco_hotel tp_endereco,
    registros tp_nt_ref_registrada
);



CREATE TABLE HOTEL OF HOTEL_TP(
    CONSTRAINT hotel_pkey PRIMARY KEY (pkid_hotel)
)NESTED TABLE REGISTROS STORE AS LISTA_REGISTROS;


-- Inserting hotel data into HOTEL table
INSERT INTO HOTEL VALUES (
    1,                          -- pkid_hotel
    'Grand Hotel',              -- nome
    tp_endereco('USA', '54321', 'New York', 'Manhattan', '123 Main St'),  -- endereco_hotel
    tp_nt_ref_registrada(
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '12345678901'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 2001)
        ),
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765432101'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 2002)
        )
    )
);

-- Inserting more hotel data into HOTEL table
INSERT INTO HOTEL VALUES (
    2,                          -- pkid_hotel
    'Beach Resort',             -- nome
    tp_endereco('USA', '90210', 'California', 'Santa Monica', '456 Beach Blvd'),  -- endereco_hotel
    tp_nt_ref_registrada(
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765432101'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 2001)
        )
    )
);

SELECT
    h.pkid_hotel AS hotel_id,
    h.nome AS hotel_name,
    h.endereco_hotel.pais AS country,
    h.endereco_hotel.cidade AS city,
    DEREF(r.passageiros).PK_CPF AS passenger_cpf,
    DEREF(r.passageiros).NOME AS passenger_name,
    DEREF(r.estadias).pk_cod_estadia AS stay_id,
    DEREF(r.estadias).valor_estadia AS stay_cost,
    DEREF(r.estadias).data_check_in AS check_in_date,
    DEREF(r.estadias).data_check_out AS check_out_date
FROM
    HOTEL h,
    TABLE(h.registros) r;

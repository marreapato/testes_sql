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
    acompanhamento_especial varchar2(3)  
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


CREATE OR REPLACE FUNCTION calcular_idade_trigger(data_nascimento DATE) RETURN NUMBER IS
BEGIN
    RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, data_nascimento) / 12);
END calcular_idade_trigger;


CREATE OR REPLACE TRIGGER idade_passageiro_trigger
BEFORE INSERT ON PASSAGEIRO_TB
FOR EACH ROW
DECLARE
    v_idade NUMBER;
    v_acompanhamento_especial VARCHAR2(3);
BEGIN
    -- Calcula a idade do novo passageiro
    v_idade := calcular_idade_trigger(:new.DATA_NASCIMENTO);

    -- Determina o valor de autorizacao_viagem com base na idade
    IF v_idade < 16 THEN
        v_acompanhamento_especial := 'sim';
    ELSIF v_idade >= 16 AND v_idade < 18 THEN
        v_acompanhamento_especial := 'nao';
    ELSE
        v_acompanhamento_especial := NULL; -- Você pode definir outro valor padrão se necessário
    END IF;

    -- Insere na tabela apropriada
    IF v_idade < 18 THEN
        -- Inserir na tabela MENOR_IDADE_TB
        INSERT INTO MENOR_IDADE_TB (PK_CPF, NOME, SEXO, DATA_NASCIMENTO, ENDERECO_PAX, TELEFONES, EMAIL, acompanhamento_especial)
        VALUES (:new.PK_CPF, :new.NOME, :new.SEXO, :new.DATA_NASCIMENTO, :new.ENDERECO_PAX, :new.TELEFONES, :new.EMAIL, v_acompanhamento_especial);
    ELSE
        -- Inserir na tabela MAIOR_IDADE_TB
        INSERT INTO MAIOR_IDADE_TB (PK_CPF, NOME, SEXO, DATA_NASCIMENTO, ENDERECO_PAX, TELEFONES, EMAIL)
        VALUES (:new.PK_CPF, :new.NOME, :new.SEXO, :new.DATA_NASCIMENTO, :new.ENDERECO_PAX, :new.TELEFONES, :new.EMAIL);
    END IF;
END;
/


CREATE OR REPLACE PROCEDURE MoveRecordsToMaiorIdade AS
    CURSOR menor_cursor IS
        SELECT *
        FROM MENOR_IDADE_TB;

    v_idade NUMBER;
BEGIN
    -- Loop through the cursor to process each record in MENOR_IDADE_TB
    FOR menor_rec IN menor_cursor LOOP
        -- Calculate age using the calcular_idade_trigger function
        v_idade := calcular_idade_trigger(menor_rec.DATA_NASCIMENTO);

        -- Check if the age is 18 years or older
        IF v_idade >= 18 THEN
            -- Insert the record into MAIOR_IDADE_TB
            INSERT INTO MAIOR_IDADE_TB (
                PK_CPF,
                NOME,
                SEXO,
                DATA_NASCIMENTO,
                ENDERECO_PAX,
                TELEFONES,
                EMAIL
            ) VALUES (
                menor_rec.PK_CPF,
                menor_rec.NOME,
                menor_rec.SEXO,
                menor_rec.DATA_NASCIMENTO,
                menor_rec.ENDERECO_PAX,
                menor_rec.TELEFONES,
                menor_rec.EMAIL
            );

            -- Delete the record from MENOR_IDADE_TB
            DELETE FROM MENOR_IDADE_TB
            WHERE PK_CPF = menor_rec.PK_CPF; -- Assuming PK_CPF is the primary key
        END IF;
    END LOOP;

    -- Commit the transaction to apply changes
    COMMIT;
END MoveRecordsToMaiorIdade;
/

CREATE OR REPLACE PROCEDURE UpdateAcompanhamentoViagem AS
BEGIN
  
    UPDATE MENOR_IDADE_TB
    SET ACOMPANHAMENTO_ESPECIAL = 'nao'
    WHERE calcular_idade_trigger(DATA_NASCIMENTO) >= 16;
    
    -- Commit the transaction to apply changes
    COMMIT;
    
    -- Display a success message
    DBMS_OUTPUT.PUT_LINE('Acompanhamento Viagem updated successfully.');
END UpdateAcompanhamentoViagem;

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
    TO_DATE('2012-10-20', 'YYYY-MM-DD'),  -- DATA_NASCIMENTO
    tp_endereco('USA', '54321', 'New York', 'Manhattan', 'Apt 456'), -- ENDERECO_PAX
    tp_fones(TP_FONE('001', '456', '1234567')), -- TELEFONES
    'janesmith@example.com'  -- EMAIL
);


SELECT T.CALCULAR_IDADE() FROM MENOR_IDADE_TB T;

SELECT * FROM MENOR_IDADE_TB;


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



SELECT DEREF(C.PASSAGEIROS).NOME FROM LISTA_COMPRAS C;

SELECT
    v.pk_localizador_voo AS flight_id,
    DEREF(c.passageiros).PK_CPF AS passenger_cpf
FROM
    VOO_TABLE v,
    TABLE(v.compras) c;

----------------
--DROP TYPE ESTADIA_TP;
CREATE TYPE ESTADIA_TP AS OBJECT(

 pk_cod_estadia INTEGER,
 valor_estadia NUMBER(38,2),
 data_check_in DATE,
 data_check_out DATE,
 reservas tp_nt_ref_relac
 
);

--DROP TABLE ESTADIA;

CREATE TABLE ESTADIA OF ESTADIA_TP(
 CONSTRAINT cod_estadia_pkey PRIMARY KEY(pk_cod_estadia)
)NESTED TABLE RESERVAS STORE AS LISTA_RESERVAS;


-- Inserting reservation data into ESTADIA table
INSERT INTO ESTADIA VALUES (
    2001,          -- pk_cod_estadia
    300.00,        -- valor_estadia
    TO_DATE('2024-07-01', 'YYYY-MM-DD'),  -- data_check_in
    TO_DATE('2024-07-05', 'YYYY-MM-DD'),  -- data_check_out
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

-- Inserting more reservation data into ESTADIA table
INSERT INTO ESTADIA VALUES (
    2004,          -- pk_cod_estadia
    400.00,        -- valor_estadia
    TO_DATE('2024-08-15', 'YYYY-MM-DD'),  -- data_check_in
    TO_DATE('2024-08-20', 'YYYY-MM-DD'),  -- data_check_out
    tp_nt_ref_relac(
        tp_ref_relac(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765434101'),
            (SELECT REF(pt) FROM PASSAGEM pt WHERE pt.pk_numero_passagem = 1002)
        )
    )
);

SELECT * FROM ESTADIA;

-- Insert new reservation data into the nested table for ESTADIA record with PK_COD_ESTADIA = 2001
INSERT INTO TABLE(
    SELECT e.reservas
    FROM ESTADIA e
    WHERE e.pk_cod_estadia = 2001
)
VALUES (
    tp_ref_relac(
        (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '11122233344'),
        (SELECT REF(pt) FROM PASSAGEM pt WHERE pt.PK_NUMERO_PASSAGEM = 1001)
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
    15,                          -- pkid_hotel
    'Grand Hotel',              -- nome
    tp_endereco('USA', '54321', 'New York', 'Manhattan', '123 Main St'),  -- endereco_hotel
    tp_nt_ref_registrada(
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '12345678901'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 2001)
        ),
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765432101'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 202)
        )
    )
);

-- Inserting more hotel data into HOTEL table
INSERT INTO HOTEL VALUES (
    91,                          -- pkid_hotel
    'Beach Resort',             -- nome
    tp_endereco('USA', '90210', 'California', 'Santa Monica', '456 Beach Blvd'),  -- endereco_hotel
    tp_nt_ref_registrada(
        tp_ref_registrada(
            (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '98765430101'),
            (SELECT REF(e) FROM ESTADIA e WHERE e.pk_cod_estadia = 301)
        )
    )
);
SELECT * FROM HOTEL;

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

EXEC CLEAR_HOTEL_WITH_NULL_CPF();

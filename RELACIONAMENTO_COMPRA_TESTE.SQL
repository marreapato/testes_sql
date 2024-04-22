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

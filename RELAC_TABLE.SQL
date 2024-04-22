

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


--DROP TABLE PASSAGEIRO_TB;
--TIPO MENOR DE IDADE
--DROP TYPE MAIOR_IDADE_TP;
CREATE TYPE MAIOR_IDADE_TP UNDER TP_PASSAGEIRO(
);

--DROP TYPE MENOR_IDADE_TP;
CREATE TYPE MENOR_IDADE_TP UNDER TP_PASSAGEIRO(
    autorizacao_viagem varchar2(3)  
);

--TABELA OBJETO

CREATE TABLE PASSAGEIRO_TB OF TP_PASSAGEIRO(
CONSTRAINT CPF_UNICO_PASSAGEIRO PRIMARY KEY (PK_CPF)
);


CREATE TABLE MENOR_IDADE_TB OF MENOR_IDADE_TP;

CREATE TABLE MAIOR_IDADE_TB OF MAIOR_IDADE_TP;

INSERT INTO PASSAGEIRO_TB (PK_CPF,NOME,SEXO,DATA_NASCIMENTO,ENDERECO_PAX,TELEFONES,EMAIL)
VALUES('12345678901',
'CARLOS',
'M',
TO_DATE('12/09/2015','DD/MM/YYYY'),
tp_endereco('Brasil', '12345-678', 'Salvador', 'Bahia', 'rua da casa'),
tp_fones(
        TP_FONE('55', '71', '987694321'),
        TP_FONE('55', '16', '987624321'),
        TP_FONE('55', '81', '987644321')
    ),
    'carlos@gmail.com'
    );
----------

CREATE OR REPLACE TYPE tp_relac AS OBJECT (
    passageiros REF tp_passageiro,
    passagens REF PASSAGEM_TP
) NOT FINAL;


CREATE TABLE relac_table OF tp_relac;

SELECT * FROM PASSAGENS_TAB;
-- Example: Inserting a passagem_tp object

-- Now perform the insertion into relac_table
INSERT INTO relac_table VALUES(
        (SELECT REF(p) FROM PASSAGEIRO_TB p WHERE p.PK_CPF = '12345678901'),
        (SELECT REF(v) FROM PASSAGENS_TAB v WHERE v.PK_NUMERO_PASSAGEM = 1)
);

-- Querying RELAC_TABLE to fetch and display object references
SELECT
    r.passageiros.PK_CPF AS passageiro_cpf,
    r.passageiros.NOME AS passageiro_nome,
    r.passageiros.SEXO AS passageiro_sexo,
    r.passagens.pk_localizador_voo AS voo_localizador,
    r.passagens.origem AS voo_origem,
    r.passagens.destino AS voo_destino
FROM
    relac_table r;


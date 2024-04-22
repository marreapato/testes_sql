--DROP TYPE MENOR_IDADE_TP;


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

--DROP TYPE TP_FONES;


CREATE TYPE ESTADIA_TP AS OBJECT(

 pk_cod_estadia INTEGER,
 valor_estadia NUMBER(38,2),
 data_check_in DATE,
 data_check_out DATE
 
);

CREATE TYPE TP_NT_ESTADIAS AS TABLE OF estadia_tp;

CREATE TYPE hotel_tp AS OBJECT (
    pkid_hotel INTEGER,
    nome VARCHAR2(30),
    endereco_hotel tp_endereco,
    estadias_list TP_NT_ESTADIAS
);

CREATE TABLE hotel_table OF hotel_tp (
    CONSTRAINT hotel_pk PRIMARY KEY (pkid_hotel)

) NESTED TABLE estadias_list STORE AS estadias_tab;

ALTER TABLE ESTADIAS_TAB MODIFY(

    CONSTRAINT ESTADIA_PK PRIMARY KEY (PK_COD_ESTADIA)
);

INSERT INTO hotel_table VALUES (1, 'Hotel A', tp_endereco('Brasil', '12345-678', 'São Paulo', 'São Paulo', '456 Oak St'), 
TP_NT_ESTADIAS(estadia_tp(1, 100.00, TO_DATE('2024-04-22', 'YYYY-MM-DD'), TO_DATE('2024-04-25', 'YYYY-MM-DD')),
estadia_tp(2, 150.00, TO_DATE('2024-05-01', 'YYYY-MM-DD'), TO_DATE('2024-05-05', 'YYYY-MM-DD')))
);

SELECT * FROM HOTEL_TABLE;

SELECT h.pkid_hotel, h.nome AS hotel_nome,
       e.pk_cod_estadia,
       e.valor_estadia,
       e.data_check_in,
       e.data_check_out
FROM hotel_table h,
     TABLE(h.estadias_list) e;

SELECT *
FROM TABLE(SELECT d.ESTADIAS_LIST
FROM hotel_table d
WHERE d.PKID_HOTEL = 1);

SELECT * FROM estadias_tab;

-- Inserção de nova estadia
INSERT INTO TABLE (
    SELECT h.estadias_list
    FROM hotel_table h
    WHERE pkid_hotel = 1
)
VALUES (3, 100.00, TO_DATE('2024-04-22', 'YYYY-MM-DD'), TO_DATE('2024-04-25', 'YYYY-MM-DD'));


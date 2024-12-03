-- This script was generated by the ERD tool in pgAdmin 4.
-- Please log an issue at https://redmine.postgresql.org/projects/pgadmin4/issues/new if you find any bugs, including reproduction steps.
BEGIN;


CREATE TABLE IF NOT EXISTS public.transaction_data
(
    transaction_id integer NOT NULL,
    transaction_data date,
    user_id integer,
    card_id integer,
    amount numeric,
    use_chip character varying(20),
    "merchant id" integer,
    merchant_city character varying(20),
    merchant_state character varying(20),
    zip character varying(7),
    mcc_code integer,
    error_id integer,
    PRIMARY KEY (transaction_id)
);

CREATE TABLE IF NOT EXISTS public.user_data
(
    user_id integer NOT NULL,
    current_age integer,
    retirement_age integer,
    birth_year integer,
    birth_month integer,
    gender character varying(10),
    address character varying(50),
    per_capita_income numeric,
    yearly_income numeric,
    total_debt numeric,
    credit_score integer,
    num_credit_cards integer,
    PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS public.card_data
(
    card_id integer NOT NULL,
    user_id integer NOT NULL,
    card_brand character varying(10),
    card_type character varying(30),
    card_expiry date,
    has_chip character varying(5),
    num_cards_issued integer,
    credit_limit integer,
    acct_open_date date,
    year_pin_last_changed integer,
    card_on_dark_web character varying(5),
    PRIMARY KEY (card_id)
);

CREATE TABLE IF NOT EXISTS public.errors
(
    error_id integer NOT NULL,
    descripiton character varying(50),
    PRIMARY KEY (error_id)
);

CREATE TABLE IF NOT EXISTS public.mcc
(
    mcc_code integer NOT NULL,
    descripiton character varying(100),
    PRIMARY KEY (mcc_code)
);

ALTER TABLE IF EXISTS public.transaction_data
    ADD FOREIGN KEY (card_id)
    REFERENCES public.card_data (card_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.transaction_data
    ADD FOREIGN KEY (error_id)
    REFERENCES public.errors (error_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.transaction_data
    ADD FOREIGN KEY (user_id)
    REFERENCES public.user_data (user_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.transaction_data
    ADD FOREIGN KEY (mcc_code)
    REFERENCES public.mcc (mcc_code) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;

END;
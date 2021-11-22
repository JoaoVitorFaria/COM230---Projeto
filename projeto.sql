--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: dm_nome; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dm_nome AS character varying(80);


ALTER DOMAIN public.dm_nome OWNER TO postgres;

--
-- Name: dm_num25; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dm_num25 AS character varying(25);


ALTER DOMAIN public.dm_num25 OWNER TO postgres;

--
-- Name: dm_numdoc; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dm_numdoc AS character varying(12);


ALTER DOMAIN public.dm_numdoc OWNER TO postgres;

--
-- Name: dm_status; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dm_status AS boolean;


ALTER DOMAIN public.dm_status OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: denuncia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.denuncia (
    delator public.dm_numdoc NOT NULL,
    id_policial public.dm_numdoc NOT NULL,
    status boolean DEFAULT false NOT NULL,
    descricao text NOT NULL,
    data date NOT NULL,
    cod_propriedade public.dm_numdoc NOT NULL,
    nro_registro integer NOT NULL,
    CONSTRAINT check_data CHECK ((data > '2021-01-01'::date)),
    CONSTRAINT check_status CHECK (((status = true) OR (status = false)))
);


ALTER TABLE public.denuncia OWNER TO postgres;

--
-- Name: CONSTRAINT check_data ON denuncia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_data ON public.denuncia IS 'Definimos essa data apenas como forma de dizer que não havia aplicação até 01/01/2021, logo não seria possível haver denúncias antes dessa data.';


--
-- Name: CONSTRAINT check_status ON denuncia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_status ON public.denuncia IS 'O status de uma denuncia deve ser True(verificada) ou false(não verificada).';


--
-- Name: apaga_denuncia(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.apaga_denuncia(codigo character varying) RETURNS public.denuncia
    LANGUAGE sql
    AS $$ 
select * from denuncia d where d.cod_propriedade = apaga_denuncia.codigo
$$;


ALTER FUNCTION public.apaga_denuncia(codigo character varying) OWNER TO postgres;

--
-- Name: atualiza_onda_municipios(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.atualiza_onda_municipios() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
    mu municipio%rowtype;
begin
    for mu in select * from municipio loop
            if (mu.taxa_ocupacao_leitos <= 15) then update mu set mu.onda = 'verde';
                else if (mu.taxa_ocupacao_leitos > 15 and mu.taxa_ocupacao_leitos < 50) then update mu set mu.onda = 'amarela';
                elseif (mu.taxa_ocupacao_leitos > 50 and mu.taxa_ocupacao_leitos < 90) then update mu set mu.onda = 'vermelha';
                else  update mu set mu.onda = 'roxa';
                end if;
    end if;
    end loop;
end;
$$;


ALTER FUNCTION public.atualiza_onda_municipios() OWNER TO postgres;

--
-- Name: atualiza_pontuacao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.atualiza_pontuacao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if(NEW.status = TRUE and OLD.status = false)then
		update usuario set pontuação = pontuação + 50 where "CPF" = NEW.delator;
	end if;
return null;
end; 
$$;


ALTER FUNCTION public.atualiza_pontuacao() OWNER TO postgres;

--
-- Name: atualiza_populacao(real, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.atualiza_populacao(bonus real, id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$ 
DECLARE total real; 
BEGIN 
total := bonus + m.num_habitantes from municipio m where m.id = atualiza_populacao.id; 
return total; 
END; 
$$;


ALTER FUNCTION public.atualiza_populacao(bonus real, id integer) OWNER TO postgres;

--
-- Name: consulta_cpf(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.consulta_cpf() RETURNS SETOF public.dm_numdoc
    LANGUAGE sql
    AS $$ select distinct u."CPF" as cpf from usuario u $$;


ALTER FUNCTION public.consulta_cpf() OWNER TO postgres;

--
-- Name: incrementa_pontuacao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.incrementa_pontuacao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if (new.status = true and old.status = false) then
		update usuario set pontuacao = pontuacao + 50 where "CPF" = new.delator;
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.incrementa_pontuacao() OWNER TO postgres;

--
-- Name: retorna_cidade(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.retorna_cidade(id integer) RETURNS record
    LANGUAGE sql
    AS $$ select m.nome, m.estado from municipio m
where m.id = retorna_cidade.id
$$;


ALTER FUNCTION public.retorna_cidade(id integer) OWNER TO postgres;

--
-- Name: retorna_cod_noticia(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.retorna_cod_noticia() RETURNS integer
    LANGUAGE sql
    AS $$select n.codigo as codigo from noticia n where id_municipio = 1$$;


ALTER FUNCTION public.retorna_cod_noticia() OWNER TO postgres;

--
-- Name: retorna_fotos_denuncia(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.retorna_fotos_denuncia() RETURNS TABLE(foto public.dm_numdoc, nro_registro integer)
    LANGUAGE plpgsql
    AS $$ 
begin
	return query select d.foto, d.nro_registro from fotos_denuncia d ;
end;
$$;


ALTER FUNCTION public.retorna_fotos_denuncia() OWNER TO postgres;

--
-- Name: ver_hospital(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ver_hospital() RETURNS integer
    LANGUAGE sql
    AS $$select h.num_total_leitos as numero_leitos from hospital h$$;


ALTER FUNCTION public.ver_hospital() OWNER TO postgres;

--
-- Name: hospital; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hospital (
    razao_social public.dm_nome NOT NULL,
    num_total_leitos integer NOT NULL,
    taxa_ocupacao integer NOT NULL,
    nome public.dm_nome NOT NULL,
    bairro public.dm_nome NOT NULL,
    rua public.dm_nome NOT NULL,
    numero integer NOT NULL,
    complemento text NOT NULL,
    id_municipio integer,
    CONSTRAINT check_num_leitos CHECK ((num_total_leitos >= 0)),
    CONSTRAINT check_numero CHECK ((numero >= 0)),
    CONSTRAINT check_taxa_ocupacao CHECK ((numero >= 0))
);


ALTER TABLE public.hospital OWNER TO postgres;

--
-- Name: CONSTRAINT check_num_leitos ON hospital; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_num_leitos ON public.hospital IS 'O numero de leitos de um hospital não pode ser negativo.';


--
-- Name: CONSTRAINT check_numero ON hospital; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_numero ON public.hospital IS 'O número de endereço de um hospital não pode ser negativo.';


--
-- Name: CONSTRAINT check_taxa_ocupacao ON hospital; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_taxa_ocupacao ON public.hospital IS 'A taxa de ocupação de um hospital não pode ser negativa. ';


--
-- Name: dados_hospital; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.dados_hospital AS
 SELECT h.razao_social,
    h.num_total_leitos AS numero_leitos,
    h.nome AS nome_hospital,
    h.bairro,
    h.rua
   FROM public.hospital h
  WHERE (h.id_municipio = 2)
  WITH NO DATA;


ALTER TABLE public.dados_hospital OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW dados_hospital; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW public.dados_hospital IS 'Retorna a razão social, número total de leitos, nome, bairro e rua dos hospitais da cidade de Itajubá.';


--
-- Name: denuncia_cod_denuncia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.denuncia_cod_denuncia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.denuncia_cod_denuncia_seq OWNER TO postgres;

--
-- Name: denuncia_cod_denuncia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.denuncia_cod_denuncia_seq OWNED BY public.denuncia.nro_registro;


--
-- Name: denuncias_nao_verificadas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.denuncias_nao_verificadas AS
 SELECT d.descricao,
    d.data,
    d.cod_propriedade
   FROM public.denuncia d
  WHERE (d.status = false);


ALTER TABLE public.denuncias_nao_verificadas OWNER TO postgres;

--
-- Name: VIEW denuncias_nao_verificadas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.denuncias_nao_verificadas IS 'Retorna a descricao, data e cod_propriedade de todas denuncias que ainda não foram verificadas. 
';


--
-- Name: fotos_denuncia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fotos_denuncia (
    foto public.dm_numdoc NOT NULL,
    nro_registro integer
);


ALTER TABLE public.fotos_denuncia OWNER TO postgres;

--
-- Name: imagem_noticia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.imagem_noticia (
    imagem public.dm_numdoc NOT NULL,
    id_noticia integer NOT NULL
);


ALTER TABLE public.imagem_noticia OWNER TO postgres;

--
-- Name: imagem_noticia_id_noticia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.imagem_noticia_id_noticia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.imagem_noticia_id_noticia_seq OWNER TO postgres;

--
-- Name: imagem_noticia_id_noticia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.imagem_noticia_id_noticia_seq OWNED BY public.imagem_noticia.id_noticia;


--
-- Name: localizacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localizacao (
    "CPF" public.dm_numdoc NOT NULL,
    cod_propriedade public.dm_numdoc NOT NULL,
    id_microrregiao integer NOT NULL
);


ALTER TABLE public.localizacao OWNER TO postgres;

--
-- Name: microrregiao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.microrregiao (
    nome_microrregiao public.dm_nome NOT NULL,
    populacao_estimada integer NOT NULL,
    area integer NOT NULL,
    num_casos integer NOT NULL,
    num_propriedades integer NOT NULL,
    num_usuarios integer NOT NULL,
    status public.dm_nome NOT NULL,
    id_municipio integer NOT NULL,
    id_microrregiao integer NOT NULL,
    CONSTRAINT check_area CHECK ((area >= 0)),
    CONSTRAINT check_num_casos CHECK ((num_casos >= 0)),
    CONSTRAINT check_num_propriedade CHECK ((num_propriedades >= 0)),
    CONSTRAINT check_num_usuarios CHECK ((num_usuarios >= 0)),
    CONSTRAINT check_populacao CHECK ((populacao_estimada >= 0)),
    CONSTRAINT check_status CHECK ((((status)::text = 'verde'::text) OR ((status)::text = 'amarelo'::text) OR ((status)::text = 'vermelho'::text) OR ((status)::text = 'roxo'::text)))
);


ALTER TABLE public.microrregiao OWNER TO postgres;

--
-- Name: CONSTRAINT check_area ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_area ON public.microrregiao IS 'O tamanho de uma microrregião não pode ser negativo.';


--
-- Name: CONSTRAINT check_num_casos ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_num_casos ON public.microrregiao IS 'O número de casos de uma microrregião não pode negativo.';


--
-- Name: CONSTRAINT check_num_propriedade ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_num_propriedade ON public.microrregiao IS 'O número de propriedades de uma microrregião não pode ser negativo.';


--
-- Name: CONSTRAINT check_num_usuarios ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_num_usuarios ON public.microrregiao IS 'O número de usuários de uma propriedade não pode ser negativo.';


--
-- Name: CONSTRAINT check_populacao ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_populacao ON public.microrregiao IS 'A população de uma microrregião não pode ser negativa. ';


--
-- Name: CONSTRAINT check_status ON microrregiao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_status ON public.microrregiao IS 'Uma microrregião deve estar em uma das ondas: verde, amarela, vermelha ou roxa.';


--
-- Name: microrregiao_id_microrregiao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.microrregiao_id_microrregiao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.microrregiao_id_microrregiao_seq OWNER TO postgres;

--
-- Name: microrregiao_id_microrregiao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.microrregiao_id_microrregiao_seq OWNED BY public.microrregiao.id_microrregiao;


--
-- Name: municipio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.municipio (
    nome public.dm_nome NOT NULL,
    estado public.dm_nome NOT NULL,
    num_habitantes integer NOT NULL,
    num_casos_confirmados integer NOT NULL,
    taxa_ocupacao_leitos integer NOT NULL,
    onda public.dm_nome NOT NULL,
    id integer NOT NULL,
    CONSTRAINT check_casos_confirmados CHECK ((num_casos_confirmados >= 0)),
    CONSTRAINT check_onda CHECK ((((onda)::text = 'verde'::text) OR ((onda)::text = 'amarela'::text) OR ((onda)::text = 'vermelha'::text) OR ((onda)::text = 'roxa'::text))),
    CONSTRAINT check_populacao CHECK ((num_habitantes > 0)),
    CONSTRAINT check_taxa_ocupacao CHECK ((taxa_ocupacao_leitos >= 0))
);


ALTER TABLE public.municipio OWNER TO postgres;

--
-- Name: CONSTRAINT check_casos_confirmados ON municipio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_casos_confirmados ON public.municipio IS 'O número de casos confirmados não pode ser negativo.';


--
-- Name: CONSTRAINT check_onda ON municipio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_onda ON public.municipio IS 'A onda deve ser verde, amarela, vermelha ou roxa.';


--
-- Name: CONSTRAINT check_populacao ON municipio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_populacao ON public.municipio IS 'O tamanho da população de um municipio não pode ser negativo.';


--
-- Name: CONSTRAINT check_taxa_ocupacao ON municipio; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_taxa_ocupacao ON public.municipio IS 'A taxa de ocupação de leitos não pode ser negativa. ';


--
-- Name: municipio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.municipio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.municipio_id_seq OWNER TO postgres;

--
-- Name: municipio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.municipio_id_seq OWNED BY public.municipio.id;


--
-- Name: noticia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.noticia (
    data_publicacao date NOT NULL,
    titulo character varying(50) NOT NULL,
    descricao text,
    codigo integer NOT NULL,
    id_municipio integer,
    id_noticia integer NOT NULL
);


ALTER TABLE public.noticia OWNER TO postgres;

--
-- Name: noticia_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.noticia_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.noticia_codigo_seq OWNER TO postgres;

--
-- Name: noticia_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.noticia_codigo_seq OWNED BY public.noticia.codigo;


--
-- Name: noticia_id_noticia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.noticia_id_noticia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.noticia_id_noticia_seq OWNER TO postgres;

--
-- Name: noticia_id_noticia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.noticia_id_noticia_seq OWNED BY public.noticia.id_noticia;


--
-- Name: propriedade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.propriedade (
    tipo "char" NOT NULL,
    nome public.dm_nome,
    numero integer NOT NULL,
    complemento text,
    "CEP" public.dm_numdoc NOT NULL,
    bairro public.dm_nome NOT NULL,
    rua public.dm_nome NOT NULL,
    codigo public.dm_numdoc NOT NULL,
    CONSTRAINT check_numero CHECK ((numero >= 0)),
    CONSTRAINT check_tipo_propriedade CHECK (((tipo = 'r'::"char") OR (tipo = 'c'::"char") OR (tipo = 'p'::"char")))
);


ALTER TABLE public.propriedade OWNER TO postgres;

--
-- Name: CONSTRAINT check_numero ON propriedade; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_numero ON public.propriedade IS 'O número de endereço de uma propriedade não pode ser negativo.
';


--
-- Name: CONSTRAINT check_tipo_propriedade ON propriedade; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_tipo_propriedade ON public.propriedade IS 'Uma propriedade deve ser do tipo residencial, comercial ou publica.';


--
-- Name: propriedade_comercial; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.propriedade_comercial (
    "CNPJ" public.dm_numdoc NOT NULL,
    nota integer NOT NULL,
    cod_propriedade public.dm_numdoc NOT NULL,
    CONSTRAINT check_nota CHECK (((nota >= 0) AND (nota <= 10)))
);


ALTER TABLE public.propriedade_comercial OWNER TO postgres;

--
-- Name: CONSTRAINT check_nota ON propriedade_comercial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_nota ON public.propriedade_comercial IS 'A nota de uma propriedade deve ser maior/igual a 0 e menor/igual a 10.';


--
-- Name: propriedade_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.propriedade_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.propriedade_seq OWNER TO postgres;

--
-- Name: propriedade_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.propriedade_seq OWNED BY public.propriedade.codigo;


--
-- Name: proprietario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proprietario (
    nome_proprietario public.dm_nome NOT NULL,
    cod_propriedade public.dm_numdoc NOT NULL,
    telefone character varying(12),
    cpf public.dm_numdoc
);


ALTER TABLE public.proprietario OWNER TO postgres;

--
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    "CPF" public.dm_numdoc NOT NULL,
    idade smallint NOT NULL,
    senha public.dm_num25 NOT NULL,
    tipo text NOT NULL,
    pontuacao integer NOT NULL,
    numero integer NOT NULL,
    complemento text,
    cep public.dm_numdoc NOT NULL,
    bairro public.dm_nome NOT NULL,
    rua public.dm_nome NOT NULL,
    nome public.dm_nome,
    id_municipio integer,
    CONSTRAINT check_tipo CHECK (((tipo = ('morador'::bpchar)::text) OR (tipo = ('policial'::bpchar)::text) OR (tipo = ('agente'::bpchar)::text))),
    CONSTRAINT verifica_numero_casa CHECK ((numero >= 0))
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- Name: CONSTRAINT check_tipo ON usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_tipo ON public.usuario IS 'um usario sempre sera do tipo morador, policial ou agente sanitario.';


--
-- Name: CONSTRAINT verifica_numero_casa ON usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT verifica_numero_casa ON public.usuario IS 'o número de endereço da residência do usuário não pode ser negativo.';


--
-- Name: usuario_agente_sanitario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_agente_sanitario (
    "CPF" public.dm_numdoc NOT NULL,
    num_carteira_funcional public.dm_numdoc NOT NULL,
    nivel integer NOT NULL,
    CONSTRAINT check_nivel CHECK ((nivel >= 0))
);


ALTER TABLE public.usuario_agente_sanitario OWNER TO postgres;

--
-- Name: CONSTRAINT check_nivel ON usuario_agente_sanitario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT check_nivel ON public.usuario_agente_sanitario IS 'não existe um nivel negativo para o agente sanitario';


--
-- Name: usuario_policial; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_policial (
    "CPF" public.dm_numdoc NOT NULL,
    num_carteira_funcional public.dm_numdoc NOT NULL,
    batalhao character varying(80) NOT NULL,
    patente character varying(80) NOT NULL
);


ALTER TABLE public.usuario_policial OWNER TO postgres;

--
-- Name: ver_cidades; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ver_cidades AS
 SELECT m.nome
   FROM public.municipio m;


ALTER TABLE public.ver_cidades OWNER TO postgres;

--
-- Name: ver_origem; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.ver_origem AS
 SELECT u.id_municipio
   FROM public.usuario u
  WITH NO DATA;


ALTER TABLE public.ver_origem OWNER TO postgres;

--
-- Name: denuncia nro_registro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.denuncia ALTER COLUMN nro_registro SET DEFAULT nextval('public.denuncia_cod_denuncia_seq'::regclass);


--
-- Name: imagem_noticia id_noticia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imagem_noticia ALTER COLUMN id_noticia SET DEFAULT nextval('public.imagem_noticia_id_noticia_seq'::regclass);


--
-- Name: microrregiao id_microrregiao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.microrregiao ALTER COLUMN id_microrregiao SET DEFAULT nextval('public.microrregiao_id_microrregiao_seq'::regclass);


--
-- Name: municipio id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio ALTER COLUMN id SET DEFAULT nextval('public.municipio_id_seq'::regclass);


--
-- Name: noticia codigo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticia ALTER COLUMN codigo SET DEFAULT nextval('public.noticia_codigo_seq'::regclass);


--
-- Name: noticia id_noticia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticia ALTER COLUMN id_noticia SET DEFAULT nextval('public.noticia_id_noticia_seq'::regclass);


--
-- Name: propriedade codigo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propriedade ALTER COLUMN codigo SET DEFAULT nextval('public.propriedade_seq'::regclass);


--
-- Name: usuario_policial ck_num_carteira_funcional; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_policial
    ADD CONSTRAINT ck_num_carteira_funcional UNIQUE (num_carteira_funcional);


--
-- Name: usuario_agente_sanitario ck_num_carteira_funcional_; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_agente_sanitario
    ADD CONSTRAINT ck_num_carteira_funcional_ UNIQUE (num_carteira_funcional);


--
-- Name: propriedade_comercial cnpj; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propriedade_comercial
    ADD CONSTRAINT cnpj UNIQUE ("CNPJ");


--
-- Name: denuncia denuncia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.denuncia
    ADD CONSTRAINT denuncia_pkey PRIMARY KEY (nro_registro);


--
-- Name: fotos_denuncia fotos_denuncia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fotos_denuncia
    ADD CONSTRAINT fotos_denuncia_pkey PRIMARY KEY (foto);


--
-- Name: hospital hospital_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospital
    ADD CONSTRAINT hospital_pkey PRIMARY KEY (razao_social);


--
-- Name: imagem_noticia imagem_noticia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imagem_noticia
    ADD CONSTRAINT imagem_noticia_pkey PRIMARY KEY (id_noticia);


--
-- Name: localizacao localizacao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao
    ADD CONSTRAINT localizacao_pkey PRIMARY KEY ("CPF", cod_propriedade, id_microrregiao);


--
-- Name: microrregiao microrregiao_nome_microrregiao_id_municipio_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.microrregiao
    ADD CONSTRAINT microrregiao_nome_microrregiao_id_municipio_key UNIQUE (nome_microrregiao, id_municipio);


--
-- Name: microrregiao microrregiao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.microrregiao
    ADD CONSTRAINT microrregiao_pkey PRIMARY KEY (id_microrregiao);


--
-- Name: municipio municipio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_pkey PRIMARY KEY (id);


--
-- Name: municipio municipio_ukey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_ukey UNIQUE (nome, estado);


--
-- Name: noticia noticia_id_municipio_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticia
    ADD CONSTRAINT noticia_id_municipio_codigo_key UNIQUE (id_municipio, codigo);


--
-- Name: noticia noticia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticia
    ADD CONSTRAINT noticia_pkey PRIMARY KEY (id_noticia);


--
-- Name: propriedade_comercial propriedade_comercial_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propriedade_comercial
    ADD CONSTRAINT propriedade_comercial_pkey PRIMARY KEY (cod_propriedade);


--
-- Name: propriedade propriedade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propriedade
    ADD CONSTRAINT propriedade_pkey PRIMARY KEY (codigo);


--
-- Name: proprietario proprietario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proprietario
    ADD CONSTRAINT proprietario_pkey PRIMARY KEY (cod_propriedade);


--
-- Name: usuario_agente_sanitario usuario_agente_sanitario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_agente_sanitario
    ADD CONSTRAINT usuario_agente_sanitario_pkey PRIMARY KEY ("CPF");


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY ("CPF");


--
-- Name: usuario_policial usuario_policial_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_policial
    ADD CONSTRAINT usuario_policial_pkey PRIMARY KEY ("CPF");


--
-- Name: denuncia atualiza_pontuacao; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER atualiza_pontuacao BEFORE UPDATE ON public.denuncia FOR EACH ROW EXECUTE FUNCTION public.incrementa_pontuacao();


--
-- Name: denuncia chama_proced; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER chama_proced AFTER UPDATE ON public.denuncia FOR EACH ROW EXECUTE FUNCTION public.atualiza_pontuacao();


--
-- Name: denuncia fk_delator; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.denuncia
    ADD CONSTRAINT fk_delator FOREIGN KEY (delator) REFERENCES public.usuario("CPF");


--
-- Name: CONSTRAINT fk_delator ON denuncia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_delator ON public.denuncia IS 'delator referencia usuario(CPF)';


--
-- Name: fotos_denuncia fk_denuncia; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fotos_denuncia
    ADD CONSTRAINT fk_denuncia FOREIGN KEY (nro_registro) REFERENCES public.denuncia(nro_registro) ON DELETE CASCADE;


--
-- Name: CONSTRAINT fk_denuncia ON fotos_denuncia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_denuncia ON public.fotos_denuncia IS 'nro_registro referencia denuncia(cod_denuncia)';


--
-- Name: localizacao fk_microrregiao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao
    ADD CONSTRAINT fk_microrregiao FOREIGN KEY (id_microrregiao) REFERENCES public.microrregiao(id_microrregiao);


--
-- Name: hospital fk_municipio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospital
    ADD CONSTRAINT fk_municipio FOREIGN KEY (id_municipio) REFERENCES public.municipio(id);


--
-- Name: microrregiao fk_municipio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.microrregiao
    ADD CONSTRAINT fk_municipio FOREIGN KEY (id_municipio) REFERENCES public.municipio(id);


--
-- Name: noticia fk_municipio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.noticia
    ADD CONSTRAINT fk_municipio FOREIGN KEY (id_municipio) REFERENCES public.municipio(id);


--
-- Name: usuario fk_municipio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT fk_municipio FOREIGN KEY (id_municipio) REFERENCES public.municipio(id);


--
-- Name: imagem_noticia fk_noticia; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imagem_noticia
    ADD CONSTRAINT fk_noticia FOREIGN KEY (id_noticia) REFERENCES public.noticia(id_noticia);


--
-- Name: denuncia fk_policial; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.denuncia
    ADD CONSTRAINT fk_policial FOREIGN KEY (id_policial) REFERENCES public.usuario_policial("CPF");


--
-- Name: propriedade_comercial fk_propriedade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.propriedade_comercial
    ADD CONSTRAINT fk_propriedade FOREIGN KEY (cod_propriedade) REFERENCES public.propriedade(codigo);


--
-- Name: CONSTRAINT fk_propriedade ON propriedade_comercial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_propriedade ON public.propriedade_comercial IS 'cod_propriedade referencia propriedade(cod_propriedade).';


--
-- Name: denuncia fk_propriedade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.denuncia
    ADD CONSTRAINT fk_propriedade FOREIGN KEY (cod_propriedade) REFERENCES public.propriedade(codigo);


--
-- Name: CONSTRAINT fk_propriedade ON denuncia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_propriedade ON public.denuncia IS 'cod_propriedade referencia propriedade(cod_propriedade).';


--
-- Name: localizacao fk_propriedade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao
    ADD CONSTRAINT fk_propriedade FOREIGN KEY (cod_propriedade) REFERENCES public.propriedade(codigo);


--
-- Name: CONSTRAINT fk_propriedade ON localizacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_propriedade ON public.localizacao IS 'cod_propriedade referencia propriedade(cod_propriedade).';


--
-- Name: proprietario fk_propriedade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proprietario
    ADD CONSTRAINT fk_propriedade FOREIGN KEY (cod_propriedade) REFERENCES public.propriedade(codigo);


--
-- Name: usuario_policial fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_policial
    ADD CONSTRAINT fk_user FOREIGN KEY ("CPF") REFERENCES public.usuario("CPF") ON DELETE CASCADE;


--
-- Name: localizacao fk_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao
    ADD CONSTRAINT fk_usuario FOREIGN KEY ("CPF") REFERENCES public.usuario("CPF");


--
-- Name: CONSTRAINT fk_usuario ON localizacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_usuario ON public.localizacao IS 'CPF referencia usuario(CPF)';


--
-- Name: usuario_agente_sanitario fk_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_agente_sanitario
    ADD CONSTRAINT fk_usuario FOREIGN KEY ("CPF") REFERENCES public.usuario("CPF") ON DELETE CASCADE;


--
-- Name: CONSTRAINT fk_usuario ON usuario_agente_sanitario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_usuario ON public.usuario_agente_sanitario IS 'CPF referencia usuario(usuario_cpf).';


--
-- PostgreSQL database dump complete
--


--
-- PostgreSQL database dump
--

\restrict 4hrz2tEw9FiRInxOdlYmh2on6Zwp2naS8VCcSkmrUZs8dw6kgg43KTWa5rRPcH3

-- Dumped from database version 15.16
-- Dumped by pg_dump version 15.15

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note (
    title character varying NOT NULL,
    content character varying NOT NULL,
    sentiment character varying,
    id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.note_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.note_id_seq OWNED BY public.note.id;


--
-- Name: notetaglink; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notetaglink (
    note_id integer NOT NULL,
    tag_id integer NOT NULL
);


--
-- Name: tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag (
    name character varying NOT NULL,
    id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: tag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_id_seq OWNED BY public.tag.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    email character varying NOT NULL,
    name character varying NOT NULL,
    hashed_password character varying,
    oauth_provider character varying,
    oauth_id character varying,
    is_active boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: note id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note ALTER COLUMN id SET DEFAULT nextval('public.note_id_seq'::regclass);


--
-- Name: tag id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag ALTER COLUMN id SET DEFAULT nextval('public.tag_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Data for Name: note; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.note (title, content, sentiment, id, user_id) FROM stdin;
new note	new note in my mind	Neutral	1	3
\.


--
-- Data for Name: notetaglink; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notetaglink (note_id, tag_id) FROM stdin;
1	1
1	2
\.


--
-- Data for Name: tag; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tag (name, id, user_id) FROM stdin;
new	1	3
note	2	3
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."user" (id, email, name, hashed_password, oauth_provider, oauth_id, is_active, created_at, updated_at) FROM stdin;
1	testuser@example.com	testuser	$2b$12$RnAf6njLYsvsSMqsIcW9Xeuvxycblx1QPAL8kEP0OuNX8BlQ5fA6m	\N	\N	t	2026-02-28 16:27:49.809897	2026-02-28 16:27:49.809917
2	verifyuser1697575289@example.com	verifyuser	$2b$12$GYNubiHwYDel/c/frxCLWe.ciX32okuAxCMRINqLdcZwl2Z84hIW2	\N	\N	t	2026-02-28 16:54:54.366328	2026-02-28 16:54:54.366347
3	user1@example.com	User1	$2b$12$9/loCB.3eeA6oYdQKUJJj.WYyhH82EdX6Rqn6PEJCe1Y.xscBo73C	\N	\N	t	2026-02-28 17:42:41.470807	2026-02-28 17:42:41.470826
\.


--
-- Name: note_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.note_id_seq', 1, true);


--
-- Name: tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tag_id_seq', 2, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_id_seq', 3, true);


--
-- Name: note note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_pkey PRIMARY KEY (id);


--
-- Name: notetaglink notetaglink_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notetaglink
    ADD CONSTRAINT notetaglink_pkey PRIMARY KEY (note_id, tag_id);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: ix_note_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_note_user_id ON public.note USING btree (user_id);


--
-- Name: ix_tag_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tag_name ON public.tag USING btree (name);


--
-- Name: ix_tag_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tag_user_id ON public.tag USING btree (user_id);


--
-- Name: ix_user_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_user_email ON public."user" USING btree (email);


--
-- Name: note note_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: notetaglink notetaglink_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notetaglink
    ADD CONSTRAINT notetaglink_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id);


--
-- Name: notetaglink notetaglink_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notetaglink
    ADD CONSTRAINT notetaglink_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tag(id);


--
-- Name: tag tag_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT ALL ON SCHEMA public TO cloudsqlsuperuser;


--
-- PostgreSQL database dump complete
--

\unrestrict 4hrz2tEw9FiRInxOdlYmh2on6Zwp2naS8VCcSkmrUZs8dw6kgg43KTWa5rRPcH3


\restrict 4quYbqR66bRZZy4JAFwRddeEsXMYvHp8z1yI2jgc49c8gIuu0ODadjd7ekkTnsX

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Homebrew)

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
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: immutable_array_to_string(text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.immutable_array_to_string(text[], text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
        SELECT array_to_string($1, $2);
      $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying,
    token uuid,
    invited_by_id uuid,
    team_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    invitation_state character varying,
    name character varying
);


--
-- Name: library_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.library_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    song_id uuid,
    user_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    from_user_id uuid,
    source character varying
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message character varying,
    room_playlist_record_id uuid,
    room_id uuid,
    user_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    pinned boolean DEFAULT false,
    song_id uuid
);


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_owner_id uuid NOT NULL,
    application_id uuid NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    scopes character varying
);


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_owner_id uuid,
    application_id uuid,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    scopes character varying,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: record_listens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_listens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    room_playlist_record_id uuid,
    song_id uuid,
    user_id uuid,
    approval integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: room_playlist_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_playlist_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    room_id uuid,
    song_id uuid,
    user_id uuid,
    "order" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    play_state character varying,
    played_at timestamp(6) without time zone
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    current_record_id uuid,
    user_rotation uuid[] DEFAULT '{}'::uuid[],
    team_id uuid,
    playing_until timestamp(6) without time zone,
    waiting_songs boolean,
    queue_processing boolean DEFAULT false
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: songs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.songs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    duration_in_seconds integer,
    youtube_id character varying,
    description character varying,
    thumbnail_url character varying,
    license character varying,
    licensed boolean DEFAULT false,
    youtube_tags character varying[] DEFAULT '{}'::character varying[],
    channel_title character varying,
    channel_id character varying,
    published_at timestamp without time zone,
    category_id character varying,
    text_search tsvector GENERATED ALWAYS AS ((((setweight(to_tsvector('english'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('english'::regconfig, (COALESCE(channel_title, ''::character varying))::text), 'A'::"char")) || setweight(to_tsvector('english'::regconfig, COALESCE(public.immutable_array_to_string((youtube_tags)::text[], ' '::text), ''::text)), 'B'::"char")) || setweight(to_tsvector('english'::regconfig, (COALESCE(description, ''::character varying))::text), 'C'::"char"))) STORED
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tags_library_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags_library_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tag_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    library_record_id uuid
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying,
    owner_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: teams_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid,
    user_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying,
    active_room_id uuid,
    active_team_id uuid
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: library_records library_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.library_records
    ADD CONSTRAINT library_records_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: record_listens record_listens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_listens
    ADD CONSTRAINT record_listens_pkey PRIMARY KEY (id);


--
-- Name: room_playlist_records room_playlist_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_playlist_records
    ADD CONSTRAINT room_playlist_records_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: songs songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (id);


--
-- Name: tags_library_records tags_library_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags_library_records
    ADD CONSTRAINT tags_library_records_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users teams_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users
    ADD CONSTRAINT teams_users_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_invitations_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_token ON public.invitations USING btree (token);


--
-- Name: index_library_records_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_library_records_on_created_at ON public.library_records USING btree (created_at);


--
-- Name: index_library_records_on_song_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_library_records_on_song_id ON public.library_records USING btree (song_id);


--
-- Name: index_library_records_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_library_records_on_source ON public.library_records USING btree (source);


--
-- Name: index_library_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_library_records_on_user_id ON public.library_records USING btree (user_id);


--
-- Name: index_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_created_at ON public.messages USING btree (created_at);


--
-- Name: index_messages_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_room_id ON public.messages USING btree (room_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_record_listens_on_room_playlist_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_listens_on_room_playlist_record_id ON public.record_listens USING btree (room_playlist_record_id);


--
-- Name: index_record_listens_on_song_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_listens_on_song_id ON public.record_listens USING btree (song_id);


--
-- Name: index_room_playlist_records_on_play_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_playlist_records_on_play_state ON public.room_playlist_records USING btree (play_state);


--
-- Name: index_room_playlist_records_on_played_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_playlist_records_on_played_at ON public.room_playlist_records USING btree (played_at);


--
-- Name: index_room_playlist_records_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_playlist_records_on_room_id ON public.room_playlist_records USING btree (room_id);


--
-- Name: index_room_playlist_records_on_song_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_playlist_records_on_song_id ON public.room_playlist_records USING btree (song_id);


--
-- Name: index_room_playlist_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_playlist_records_on_user_id ON public.room_playlist_records USING btree (user_id);


--
-- Name: index_rooms_on_playing_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_playing_until ON public.rooms USING btree (playing_until);


--
-- Name: index_songs_on_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_channel_id ON public.songs USING btree (channel_id);


--
-- Name: index_songs_on_duration_in_seconds; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_duration_in_seconds ON public.songs USING btree (duration_in_seconds);


--
-- Name: index_songs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_name ON public.songs USING gin (name public.gin_trgm_ops);


--
-- Name: index_songs_on_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_published_at ON public.songs USING btree (published_at);


--
-- Name: index_songs_on_searchable_content_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_searchable_content_trgm ON public.songs USING gist (((((((COALESCE(name, ''::character varying))::text || ' '::text) || (COALESCE(channel_title, ''::character varying))::text) || ' '::text) || COALESCE(public.immutable_array_to_string((youtube_tags)::text[], ' '::text), ''::text))) public.gist_trgm_ops);


--
-- Name: index_songs_on_text_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_text_search ON public.songs USING gin (text_search);


--
-- Name: index_songs_on_youtube_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_songs_on_youtube_id ON public.songs USING btree (youtube_id);


--
-- Name: index_tags_library_records_on_library_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_library_records_on_library_record_id ON public.tags_library_records USING btree (library_record_id);


--
-- Name: index_tags_library_records_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_library_records_on_tag_id ON public.tags_library_records USING btree (tag_id);


--
-- Name: index_tags_library_records_on_tag_id_and_library_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_library_records_on_tag_id_and_library_record_id ON public.tags_library_records USING btree (tag_id, library_record_id);


--
-- Name: index_tags_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_user_id ON public.tags USING btree (user_id);


--
-- Name: index_teams_users_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_on_team_id ON public.teams_users USING btree (team_id);


--
-- Name: index_teams_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_users_on_user_id ON public.teams_users USING btree (user_id);


--
-- Name: index_users_on_active_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_active_room_id ON public.users USING btree (active_room_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: song_name_order_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX song_name_order_index ON public.songs USING btree (name);


--
-- Name: unique_record_listens; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_record_listens ON public.record_listens USING btree (room_playlist_record_id, song_id, user_id);


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 4quYbqR66bRZZy4JAFwRddeEsXMYvHp8z1yI2jgc49c8gIuu0ODadjd7ekkTnsX

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251117093000'),
('20251117092530'),
('20251117091002'),
('20200603024043'),
('20200515034314'),
('20200513040509'),
('20200513033849'),
('20200424153153'),
('20200423152618'),
('20200415022511'),
('20200407040051'),
('20200401223702'),
('20200318014102'),
('20200307232816'),
('20200305230807'),
('20200304014747'),
('20200304014052'),
('20200226234654'),
('20200226234544'),
('20200223055015'),
('20200209060935'),
('20200205061306'),
('20200205052424'),
('20200125023143'),
('20200102170036'),
('20191231155941'),
('20191231020447'),
('20191231015122'),
('20191231014524'),
('20191231014000'),
('20191231013211'),
('20190929003240'),
('20190928195833'),
('20190927234716'),
('20190927233126'),
('20190927232709'),
('20190927232332'),
('20190702133426'),
('20190606130002'),
('20190606125833'),
('20190409022601'),
('20190407020627'),
('20190403034154'),
('20190329055638'),
('20190329055527'),
('20190329051901'),
('20190329051721'),
('20190329051317'),
('20190326121153'),
('20190322030346'),
('20190322030217'),
('20190322022735'),
('20190319133140'),
('20190319122943'),
('20190305135026'),
('20190218202341'),
('20190218194925'),
('20190218193526'),
('20180115152059'),
('20171228003631');


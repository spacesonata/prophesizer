-- LAST UPDATE: 6/14/2021:
-- adding teams_info_expanded_all_id to teams_from_timestamp

DROP FUNCTION IF EXISTS data.reblase_gameeventid(in_game_event_id bigint) CASCADE;
DROP FUNCTION IF EXISTS data.gamephase_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.timestamp_from_gameday(in_season integer, in_gameday integer) CASCADE;
DROP FUNCTION IF EXISTS data.teams_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.team_slug_creation() CASCADE;
DROP FUNCTION IF EXISTS data.slugging(in_total_bases_from_hits bigint, in_at_bats bigint) CASCADE;
DROP FUNCTION IF EXISTS data.season_timespan(in_season integer) CASCADE;
DROP FUNCTION IF EXISTS data.round_half_even(val numeric, prec integer) CASCADE;
DROP FUNCTION IF EXISTS data.rosters_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.refresh_matviews() CASCADE;
DROP FUNCTION IF EXISTS data.refresh_matviews_concurrently() CASCADE;
DROP FUNCTION IF EXISTS data.ref_leaderboard_season_pitching(in_season integer) CASCADE;
DROP FUNCTION IF EXISTS data.ref_leaderboard_season_batting(in_season integer) CASCADE;
DROP FUNCTION IF EXISTS data.reblase_gameid(in_game_id character varying) CASCADE;
DROP FUNCTION IF EXISTS data.rating_to_star(in_rating numeric) CASCADE;
DROP FUNCTION IF EXISTS data.players_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.player_slug_creation() CASCADE;
DROP FUNCTION IF EXISTS data.player_mods_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.player_day_vibe(in_player_id character varying, in_gameday integer, in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.pitching_rating_raw(in_unthwackability numeric, in_ruthlessness numeric, in_overpowerment numeric, in_shakespearianism numeric, in_coldness numeric) CASCADE;
DROP FUNCTION IF EXISTS data.pitching_rating(in_player_id character varying, in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.pitcher_idol_coins(in_player_id character varying, in_season integer) CASCADE;
DROP FUNCTION IF EXISTS data.on_base_percentage(in_hits bigint, in_raw_at_bats bigint, in_walks bigint, in_sacs bigint) CASCADE;
DROP FUNCTION IF EXISTS data.last_position_in_string(in_string text, in_search text) CASCADE;
DROP FUNCTION IF EXISTS data.innings_from_outs(in_outs numeric) CASCADE;
DROP FUNCTION IF EXISTS data.gameday_from_timestamp(in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.earned_run_average(in_runs numeric, in_outs numeric) CASCADE;
DROP FUNCTION IF EXISTS data.defense_rating_raw(in_omniscience numeric, in_tenaciousness numeric, in_watchfulness numeric, in_anticapitalism numeric, in_chasiness numeric) CASCADE;
DROP FUNCTION IF EXISTS data.defense_rating(in_player_id character varying, in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.current_season() CASCADE;
DROP FUNCTION IF EXISTS data.current_gameday() CASCADE;
DROP FUNCTION IF EXISTS data.current_tournament() CASCADE;
DROP FUNCTION IF EXISTS data.batting_rating_raw(in_tragicness numeric, in_patheticism numeric, in_thwackability numeric, in_divinity numeric, in_moxie numeric, in_musclitude numeric, in_martyrdom numeric) CASCADE;
DROP FUNCTION IF EXISTS data.batting_rating(in_player_id character varying, in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.batting_average(in_hits bigint, in_raw_at_bats bigint) CASCADE;
DROP FUNCTION IF EXISTS data.batter_idol_coins(in_player_id character varying, in_season integer) CASCADE;
DROP FUNCTION IF EXISTS data.baserunning_rating_raw(in_laserlikeness numeric, in_continuation numeric, in_base_thirst numeric, in_indulgence numeric, in_ground_friction numeric) CASCADE;
DROP FUNCTION IF EXISTS data.baserunning_rating(in_player_id character varying, in_timestamp timestamp without time zone) CASCADE;
DROP FUNCTION IF EXISTS data.bankers_round(in_val numeric, in_prec integer) CASCADE;

--
-- Name: round_half_even(numeric, integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.round_half_even(val numeric, prec integer) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
declare
    retval numeric;
    difference numeric;
    even boolean;
begin
    retval := round(val,prec);
    difference := retval-val;
    if abs(difference)*(10::numeric^prec) = 0.5::numeric then
        even := (retval * (10::numeric^prec)) % 2::numeric = 0::numeric;
        if not even then
            retval := round(val-difference,prec);
        end if;
		
    end if;
    return retval;
end;
$$;
--
-- Name: current_season(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.current_season() RETURNS integer
    LANGUAGE sql
    AS $$
SELECT max(season) from data.games;
$$;
--
-- Name: current_tournament(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.current_tournament() RETURNS integer
    LANGUAGE sql
    AS $$
SELECT 
CASE
	WHEN phase_id BETWEEN 12 AND 16 THEN 0
	ELSE NULL
END AS tournament_current	
FROM DATA.time_map
WHERE first_time = 
(
	SELECT MAX(first_time)
	FROM DATA.time_map
)
$$;
--
-- Name: players_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.players_from_timestamp(in_timestamp timestamp without time zone DEFAULT timezone('utc'::text, now())) RETURNS TABLE(id integer, player_id character varying, valid_from timestamp without time zone, valid_until timestamp without time zone, player_name character varying, deceased boolean, hash uuid, anticapitalism numeric, base_thirst numeric, buoyancy numeric, chasiness numeric, coldness numeric, continuation numeric, divinity numeric, ground_friction numeric, indulgence numeric, laserlikeness numeric, martyrdom numeric, moxie numeric, musclitude numeric, omniscience numeric, overpowerment numeric, patheticism numeric, ruthlessness numeric, shakespearianism numeric, suppression numeric, tenaciousness numeric, thwackability numeric, tragicness numeric, unthwackability numeric, watchfulness numeric,pressurization numeric, cinnamon numeric, total_fingers smallint, soul smallint, fate smallint, peanut_allergy boolean, armor text, bat text, ritual text, coffee smallint, blood smallint, url_slug character varying, tournament integer, evolution integer, batting_rating numeric, pitching_rating numeric, baserunning_rating numeric, defense_rating numeric)
    LANGUAGE plpgsql
    AS $$
begin
	return query 
	select *
	from data.players p
	where p.valid_from <= in_timestamp + (INTERVAL '1 millisecond')
	and in_timestamp < coalesce(p.valid_until,timezone('utc'::text, now()) + (INTERVAL '1 millisecond'));
end;
$$;

--
-- Name: bankers_round(numeric, integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.bankers_round(in_val numeric, in_prec integer) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
declare
    retval numeric;
    difference numeric;
    even boolean;
begin
    retval := round(in_val,in_prec);
    difference := retval-in_val;
    if abs(difference)*(10::numeric^in_prec) = 0.5::numeric then
        even := (retval * (10::numeric^in_prec)) % 2::numeric = 0::numeric;
        if not even then
            retval := round(val-difference,in_prec);
        end if;
	end if;
    return retval;
end;
$$;
--
-- Name: baserunning_rating(character varying, timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.baserunning_rating(in_player_id character varying, in_timestamp timestamp without time zone DEFAULT timezone('utc'::text, now())) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
	round(power(p.laserlikeness,0.5) *
   	power(p.continuation * p.base_thirst * p.indulgence * p.ground_friction, 0.1),15)
FROM data.players_from_timestamp(in_timestamp) p
WHERE p.player_id = in_player_id
$$;
--
-- Name: baserunning_rating_raw(numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.baserunning_rating_raw(in_laserlikeness numeric, in_continuation numeric, in_base_thirst numeric, in_indulgence numeric, in_ground_friction numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
	round(power(in_laserlikeness,0.5) *
	power(in_continuation * in_base_thirst * in_indulgence * in_ground_friction, 0.1),15);
$$;
--
-- Name: batter_idol_coins(character varying, integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.batter_idol_coins(in_player_id character varying, in_season integer DEFAULT '-1'::integer) RETURNS bigint
    LANGUAGE sql
    AS $$
SELECT 
SUM
(
	CASE
	  WHEN ge.event_type IN ('SINGLE','DOUBLE','TRIPLE') THEN 200
	  WHEN ge.event_type = 'HOME_RUN' THEN 1200
	  ELSE 0
	END 
) AS coins
FROM data.game_events ge
WHERE ge.season = 
CASE
  when in_season = -1 then (SELECT data.current_season())
  else in_season
END
AND ge.batter_id = in_player_id;
$$;
--
-- Name: batting_average(bigint, bigint); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.batting_average(in_hits bigint, in_raw_at_bats bigint) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT (in_hits::numeric/ in_raw_at_bats::numeric)::numeric(10,3)
$$;
--
-- Name: batting_rating(character varying, timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.batting_rating(in_player_id character varying, in_timestamp timestamp without time zone DEFAULT timezone('utc'::text, now())) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
   round(power((1 - p.tragicness),0.01) * 
   power((1 - p.patheticism),0.05) *
   power((p.thwackability * p.divinity),0.35) *
   power((p.moxie * p.musclitude),0.075) * 
   power(p.martyrdom,0.02),15)
FROM data.players_from_timestamp(in_timestamp) p
WHERE player_id = in_player_id;
$$;
--
-- Name: batting_rating_raw(numeric, numeric, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.batting_rating_raw(in_tragicness numeric, in_patheticism numeric, in_thwackability numeric, in_divinity numeric, in_moxie numeric, in_musclitude numeric, in_martyrdom numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
   round(power((1 - in_tragicness),0.01) * 
   power((1 - in_patheticism),0.05) *
   power((in_thwackability * in_divinity),0.35) *
   power((in_moxie * in_musclitude),0.075) * 
   power(in_martyrdom,0.02),15);
$$;
--
-- Name: current_gameday(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.current_gameday() RETURNS integer
    LANGUAGE sql
    AS $$
SELECT max(day) FROM data.game_events WHERE
season = (SELECT data.current_season());
$$;
--
-- Name: defense_rating(character varying, timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.defense_rating(in_player_id character varying, in_timestamp timestamp without time zone DEFAULT timezone('utc'::text, now())) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
	round(power((p.omniscience * p.tenaciousness),0.2) *
   	power((p.watchfulness * p.anticapitalism * p.chasiness),0.1),15)
FROM data.players_from_timestamp(in_timestamp) p
WHERE p.player_id = in_player_id;
$$;
--
-- Name: defense_rating_raw(numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.defense_rating_raw(in_omniscience numeric, in_tenaciousness numeric, in_watchfulness numeric, in_anticapitalism numeric, in_chasiness numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
	round(power((in_omniscience * in_tenaciousness),0.2) *
   	power((in_watchfulness * in_anticapitalism * in_chasiness),0.1),15);
$$;
--
-- Name: earned_run_average(numeric, numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.earned_run_average(in_runs numeric, in_outs numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT round(9*(in_runs/((in_outs::DECIMAL)/3)::DECIMAL) ,2)
$$;
--
-- Name: gameday_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.gameday_from_timestamp(in_timestamp timestamp without time zone) RETURNS TABLE(season integer, gameday integer)
    LANGUAGE sql
    AS $$
SELECT
(
	SELECT COALESCE
	(
 		(
  			SELECT season FROM data.time_map WHERE first_time = 
			(
				SELECT max(first_time)
				FROM data.time_map 
				WHERE first_time < in_timestamp
			)	
		)
	,0)
),(
	SELECT COALESCE
	(
  		(
  			SELECT day FROM data.time_map WHERE first_time = 
			(
				SELECT max(first_time)
				FROM data.time_map 
				WHERE first_time < in_timestamp
			)	
		)
	,0)
);
$$ ROWS 1;

--
-- Name: gamephase_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.gamephase_from_timestamp(in_timestamp timestamp without time zone) 
RETURNS TABLE(season integer, tournament integer, gameday integer, phase_type VARCHAR)
    LANGUAGE sql
    AS $$
SELECT
CASE
	when in_timestamp BETWEEN '2021-04-11 18:00' AND '2021-04-11 19:00' THEN 14 -- Elections S15
	WHEN season = -1 AND day = 115 and tm.phase_id = 13 THEN 11 -- Elections S12
	WHEN season = -1 AND day = 116 and tm.phase_id = 13 THEN 13 -- Elections S14
	WHEN season = 10 AND first_time > '2021-11-01' THEN NULL -- Time after Cup, before S12
	WHEN phase_type_id IN ('6','7','8') then NULL -- Tourney phase types
	ELSE season
END AS season,
CASE
	WHEN phase_type_id IN ('6','7','8') THEN 0 -- Tourney phase types
	ELSE NULL
END AS tournament,
CASE
	WHEN phase_type_id IN ('1','3','7') THEN DAY -- Gameday phase types
	ELSE NULL
END AS DAY,
CASE	
	when season = -1 AND first_time > '2021-03-01' then 'ELECTIONS' --Election S12 & S14
	WHEN season = 10 AND first_time > '2021-11-01' THEN 'SIESTA' -- Time after Cup, before S12
	ELSE phase_type
END as phase_type
FROM DATA.time_map tm
JOIN taxa.phases xp
ON (tm.phase_id = xp.phase_id AND tm.first_time BETWEEN xp.valid_from AND COALESCE(xp.valid_until,NOW()))
LEFT JOIN taxa.tournaments xt
ON (tm.season = xt.tournament_id)
WHERE first_time = 
(
	SELECT max(first_time)
	FROM data.time_map 
	WHERE first_time < in_timestamp
);
$$ ROWS 1;
--
-- Name: innings_from_outs(numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.innings_from_outs(in_outs numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
select ((round(in_outs/3,0))::TEXT || '.' ||  (mod(in_outs,3))::text)::numeric
$$;
--
-- Name: last_position_in_string(text, text); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.last_position_in_string(in_string text, in_search text) RETURNS integer
    LANGUAGE sql
    AS $$
Select length(in_string) - 
position(reverse(in_search) in reverse(in_string)) - length(in_search);
$$;
--
-- Name: on_base_percentage(bigint, bigint, bigint, bigint); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.on_base_percentage(in_hits bigint, in_raw_at_bats bigint, in_walks bigint, in_sacs bigint DEFAULT 0) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT ((in_hits + in_walks)/ (in_raw_at_bats +in_walks + in_sacs)::numeric)::numeric(10,3)
$$;
--
-- Name: pitcher_idol_coins(character varying, integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.pitcher_idol_coins(in_player_id character varying, in_season integer DEFAULT '-1'::integer) RETURNS bigint
    LANGUAGE sql
    AS $$
select
(
	SELECT 
	(count(1)) * 200
	FROM data.game_events ge
	WHERE ge.season = 
	CASE
  	  when in_season = -1 then (SELECT data.current_season())
  	  else in_season
	END
	AND ge.event_type = 'STRIKEOUT'
	AND ge.pitcher_id = in_player_id
) 
+
(
	SELECT coalesce(SUM(shutout),0) FROM
		(
		SELECT 10000 as shutout
		FROM DATA.game_events ge
		WHERE ge.season = 
		CASE
  		  when in_season = -1 then (SELECT data.current_season())
		  else in_season
		END
		AND ge.pitcher_id = in_player_id 
		GROUP BY game_id, top_of_inning
		HAVING 
		CASE
		  WHEN top_of_inning THEN MAX(away_score)
		  ELSE MAX(home_score)
		END = 0
		-- Removing all outs check for now, speed issue
		/*
		AND (MAX(inning) +1) * 3 = 
		SUM
		(
		  CASE 
		    WHEN event_type IN ('CAUGHT_STEALING','OUT','STRIKEOUT','FIELDERS_CHOICE')
		    THEN 1
		    ELSE 0
		  END 
		)
		*/
	) s
)
$$;
--
-- Name: pitching_rating(character varying, timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.pitching_rating(in_player_id character varying, in_timestamp timestamp without time zone DEFAULT timezone('utc'::text, now())) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
round(
power(p.unthwackability,0.5) * 
power(p.ruthlessness,0.4) *
power(p.overpowerment,0.15) * 
power(p.shakespearianism,0.1) * 
power(p.coldness,0.025),15)
FROM data.players_from_timestamp(in_timestamp) p
WHERE 
p.player_id = in_player_id;
$$;
--
-- Name: pitching_rating_raw(numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.pitching_rating_raw(in_unthwackability numeric, in_ruthlessness numeric, in_overpowerment numeric, in_shakespearianism numeric, in_coldness numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
round(
	power(in_unthwackability,0.5) * 
	power(in_ruthlessness,0.4) *
	power(in_overpowerment,0.15) * 
	power(in_shakespearianism,0.1) * 
	power(in_coldness,0.025),15);
$$;
--
-- Name: player_day_vibe(character varying, integer, timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.player_day_vibe(in_player_id character varying, in_gameday integer DEFAULT 0, in_timestamp timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT 
(0.5 * (p.pressurization + p.cinnamon) * sin(PI() * 
(2 / (6 + round(10 * p.buoyancy)) * in_gameday + .5)) - .5 
* p.pressurization + .5 * p.cinnamon)::numeric
FROM data.players_from_timestamp(in_timestamp) p
WHERE 
p.player_id = in_player_id;
$$;
--
-- Name: player_mods_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.player_mods_from_timestamp(in_timestamp timestamp without time zone) RETURNS TABLE(player_modifications_id integer, player_id character varying, modification character varying, valid_from timestamp without time zone, valid_until timestamp without time zone, tournament integer)
    LANGUAGE plpgsql
    AS $$
begin
	return query 
	select *
	from data.player_modifications m
	where m.valid_from <= in_timestamp 
	and in_timestamp < coalesce(m.valid_until,timezone('utc'::text, now()) + (INTERVAL '1 millisecond'));
end;
$$;
--
-- Name: player_slug_creation(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.player_slug_creation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.url_slug = replace(regexp_replace(lower(unaccent(replace(new.player_name,',',' comma'))), '[^A-Za-z'' ]', '','g'),' ','-');
	RETURN new;
END;
$$;
--
-- Name: rating_to_star(numeric); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.rating_to_star(in_rating numeric) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT ROUND((5 * in_rating),1);
$$;
--
-- Name: reblase_gameid(character varying); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.reblase_gameid(in_game_id character varying) RETURNS character varying
    LANGUAGE sql
    AS $$
select 'https://reblase.sibr.dev/game/' || in_game_id;
$$;

--
-- Name: reblase_gameeventid(character varying); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.reblase_gameeventid(in_game_event_id bigint) RETURNS UUID
    LANGUAGE sql
    AS $$
SELECT update_hash
FROM DATA.chronicler_hash_game_event ch
JOIN
(
	SELECT MIN(chronicler_hash_game_event_id) AS chronicler_hash_game_event_id
	FROM DATA.chronicler_hash_game_event
	GROUP BY game_event_id
) mch
ON (ch.chronicler_hash_game_event_id = mch.chronicler_hash_game_event_id)
WHERE game_event_id = in_game_event_id;
$$;

--
-- Name: ref_leaderboard_season_batting(integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.ref_leaderboard_season_batting(in_season integer) RETURNS TABLE(player_id character varying, player_name character varying, url_slug character varying, team_id character varying, team text, team_valid_from timestamp without time zone, team_valid_until timestamp without time zone, value numeric, rank bigint, stat text)
    LANGUAGE plpgsql
    AS $$
begin
	return query 
	SELECT 
	a.player_id, 
	a.player_name, 
	(SELECT DISTINCT u.url_slug FROM DATA.players u WHERE a.player_id = u.player_id AND a.player_name = u.player_name) AS url_slug,
	a.team_id,
	tt.nickname AS team,
	tt.valid_from AS team_valid_from,
	tt.valid_until AS team_valid_until,
	c.*
	FROM 
	(
		SELECT b.*, 
		ba.on_base_percentage, 
		ba.slugging, 
		ba.batting_average, 
		ba.on_base_slugging,
		ba.obp_rank, 
		ba.slugging_rank, 
		ba.ba_rank, 
		ba.ops_rank,
		r.runs,
		r.stolen_bases,
		r.caught_stealing,
		r.runs_rank,
		r.sb_rank,
		r.cs_rank
		from
		(
			SELECT x.player_id,
			x.player_name,
			x.team_id,
			season,
			hits_risp,
			walks,
			doubles,
			triples,
			quadruples,
			home_runs,
			total_bases,
			hits,
			runs_batted_in,
			sacrifice_bunts,
			sacrifice_flies,
			strikeouts,
			hit_by_pitches,
			gidp,
			rank() OVER (ORDER BY hits_risp DESC) AS hits_risp_rank,
			rank() OVER (ORDER BY walks DESC) AS bb_rank,
			rank() OVER (ORDER BY doubles DESC) AS dbl_rank,
			rank() OVER (ORDER BY triples DESC) AS trp_rank,
			rank() OVER (ORDER BY home_runs DESC) AS hr_rank,
			rank() OVER (ORDER BY total_bases DESC) AS tb_rank,
			rank() OVER (ORDER BY quadruples DESC) AS qd_rank,
			rank() OVER (ORDER BY hits DESC) AS hits_rank,
			rank() OVER (ORDER BY runs_batted_in DESC) AS rbi_rank,
			rank() OVER (ORDER BY x.sacrifice_bunts DESC) AS sacbunts_rank,
	        rank() OVER (ORDER BY x.sacrifice_flies DESC) AS sacflies_rank,
			rank() OVER (ORDER BY strikeouts DESC) AS k_rank,
			rank() OVER (ORDER BY hit_by_pitches DESC) AS hbp_rank,
			rank() OVER (ORDER BY gidp DESC) AS gidp_rank
			FROM DATA.batting_stats_player_season x
			WHERE season = in_season
		) b
		LEFT JOIN
		(
			SELECT y.player_id,
			y.team_id,
			on_base_percentage,
			slugging,
			batting_average,
			on_base_slugging,
			rank() OVER (ORDER BY on_base_percentage DESC) AS obp_rank,
			rank() OVER (ORDER BY slugging DESC) AS slugging_rank,
			rank() OVER (ORDER BY batting_average DESC) AS ba_rank,           
			rank() OVER (ORDER BY on_base_slugging DESC) AS ops_rank
			FROM DATA.batting_stats_player_season y
			WHERE season = in_season
			AND plate_appearances > (SELECT MAX(DAY)+1 FROM DATA.games WHERE season = in_season
			AND NOT is_postseason AND (home_score + away_score > 0))*2
		) ba
		ON (b.player_id = ba.player_id and b.team_id = ba.team_id)
		LEFT JOIN
		(
			SELECT z.player_id,
			z.team_id,
			season,
			runs,
			stolen_bases,
			caught_stealing,
			rank() OVER (ORDER BY runs DESC) AS runs_rank,
			rank() OVER (ORDER BY stolen_bases DESC) AS sb_rank,
			rank() OVER (ORDER BY caught_stealing DESC) AS cs_rank
			FROM DATA.running_stats_player_season z
			WHERE season = in_season
		) r
		ON (b.player_id = r.player_id and b.team_id = r.team_id)
	) a
	JOIN DATA.teams_from_timestamp(DATA.timestamp_from_gameday(in_season,0)) tt 
	ON (tt.team_id = a.team_id)
	CROSS JOIN LATERAL 
	(
		VALUES 
		(a.on_base_percentage, a.obp_rank, 'on_base_percentage'),
		(a.slugging, a.slugging_rank, 'slugging'),
		(a.batting_average,a.ba_rank,'batting_average'), 
		(a.on_base_slugging,a.ops_rank,'on_base_slugging'),
		(a.hits_risp,a.hits_risp_rank,'hits_risp'), 
		(a.walks,a.bb_rank,'walks'), 
		(a.doubles,a.dbl_rank,'doubles'), 
		(a.triples,a.trp_rank,'triples'), 
		(a.quadruples,a.qd_rank,'quadruples'),
		(a.home_runs,a.hr_rank,'home_runs'), 
		(a.total_bases,a.tb_rank,'total_bases'), 
		(a.hits,a.hits_rank,'hits'), 
		(a.runs_batted_in,a.rbi_rank,'runs_batted_in'), 
		(a.sacrifice_bunts,a.sacbunts_rank,'sacrifice_bunts'), 
		(a.sacrifice_flies,a.sacflies_rank,'sacrifice_flies'),  
		(a.strikeouts,a.k_rank,'strikeouts'),
		(a.hit_by_pitches,a.hbp_rank,'hit_by_pitches'),
		(a.gidp,a.gidp_rank,'gidp'),
		(a.runs,a.runs_rank,'runs_scored'),
		(a.stolen_bases,a.sb_rank,'stolen_bases'),
		(a.caught_stealing,a.cs_rank,'caught_stealing')
	) AS c(value, rank, stat)
	WHERE c.rank <= 10 
	ORDER BY c.stat, c.rank, a.player_name;	
	end;
$$;

--
-- Name: ref_leaderboard_season_pitching(integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.ref_leaderboard_season_pitching(in_season integer) RETURNS TABLE(player_id character varying, player_name character varying, url_slug character varying, team_id character varying, team text, team_valid_from timestamp without time zone, team_valid_until timestamp without time zone, value numeric, rank bigint, stat text)
    LANGUAGE plpgsql
    AS $$
begin
	return query 

	SELECT 

	a.player_id, 
	a.player_name, 
	(SELECT DISTINCT u.url_slug FROM DATA.players u WHERE a.player_id = u.player_id AND a.player_name = u.player_name) AS url_slug,
	a.team_id,
	tt.nickname AS team,
	tt.valid_from AS team_valid_from,
	tt.valid_until AS team_valid_until,
	c.*
	FROM 
	(
		SELECT p.*,
		pa.earned_run_average,
		pa.walks_per_9,
		pa.hits_per_9,
		pa.home_runs_per_9,
		pa.strikeouts_per_9,
		pa.era_rank,
		pa.bb9_rank,
		pa.hits9_rank,
		pa.hr9_rank,
		pa.k9_rank
		from
		(
			SELECT x.player_id,
			x.player_name,
			x.team_id,
			season,
			walks,
			ROUND(walks/batters_faced,3) AS walk_percentage,
			strikeouts,
			case
				WHEN walks = 0 THEN strikeouts ELSE round(strikeouts/walks,2)
			end AS strikeouts_per_walk,
			ROUND(strikeouts/batters_faced,3) AS strikeout_percentage,
			runs_allowed,
			hits_allowed,
			home_runs_allowed,
			innings,
			pitches_thrown,
			hit_by_pitches,
			wins,
			losses,
			shutouts,
			quality_starts,
			whip,
			round(wins::DECIMAL/(wins::DECIMAL+losses::DECIMAL),3) AS win_pct,
			rank() OVER (ORDER BY walks DESC) AS bb_rank,
			rank() OVER (ORDER BY round(walks/batters_faced,3)) AS bbpct_rank,		
			rank() OVER (ORDER BY strikeouts DESC) AS k_rank,
			rank() OVER (ORDER BY CASE WHEN walks = 0 THEN strikeouts ELSE round(strikeouts/walks,2) END DESC) AS kbb_rank,
			rank() OVER (ORDER BY round(strikeouts/batters_faced,3) DESC) AS kpct_rank,		
			rank() OVER (ORDER BY runs_allowed DESC) AS runs_rank,
			rank() OVER (ORDER BY hits_allowed DESC) AS hits_rank,
			rank() OVER (ORDER BY home_runs_allowed DESC) AS hrs_rank,
			rank() OVER (ORDER BY innings DESC) AS inn_rank,
			rank() OVER (ORDER BY pitches_thrown DESC) AS ptch_rank,
			rank() OVER (ORDER BY hit_by_pitches DESC) AS hbp_rank,
			rank() OVER (ORDER BY wins DESC) AS win_rank,
			rank() OVER (ORDER BY losses DESC) AS loss_rank,
			rank() OVER (ORDER BY shutouts DESC) AS shut_rank,
			rank() OVER (ORDER BY quality_starts DESC) AS qual_rank,
			rank() OVER (ORDER BY whip) AS whip_rank
			FROM DATA.pitching_stats_player_season x
			WHERE season = in_season
		) p
		LEFT JOIN
		(
			SELECT x.player_id,
			earned_run_average,
			walks_per_9,
			hits_per_9,
			home_runs_per_9,
			strikeouts_per_9,
			rank() OVER (ORDER BY earned_run_average) AS era_rank,
			rank() OVER (ORDER BY walks_per_9) AS bb9_rank,
			rank() OVER (ORDER BY hits_per_9) AS hits9_rank,
			rank() OVER (ORDER BY home_runs_per_9) AS hr9_rank,
			rank() OVER (ORDER BY strikeouts_per_9 DESC) AS k9_rank
			FROM DATA.pitching_stats_player_season x
			WHERE season = in_season
			
			--at least 1 inning per team's regular season games for averaging stats
			AND outs_recorded > (SELECT MAX(DAY)+1 FROM DATA.games WHERE season = in_season
			AND NOT is_postseason AND (home_score + away_score > 0))*3
		) pa
		ON (p.player_id = pa.player_id)
	) a
	JOIN DATA.teams_from_timestamp(DATA.timestamp_from_gameday(in_season,0)) tt 
	ON (tt.team_id = a.team_id)
	CROSS JOIN LATERAL 
	(
		VALUES 
		(a.walks, a.bb_rank, 'walks'),
		(a.walk_percentage, a.bbpct_rank, 'walk_percentage'),
		(a.strikeouts, a.k_rank, 'strikeouts'),
		(a.strikeouts_per_walk, a.kbb_rank, 'strikeouts_per_walk'),
		(a.strikeout_percentage, a.kpct_rank, 'strikeout_percentage'),
		(a.runs_allowed, a.runs_rank, 'runs_allowed'),
		(a.hits_allowed, a.hits_rank, 'hits_allowed'),
		(a.home_runs_allowed, a.hrs_rank, 'home_runs_allowed'),
		(a.innings, a.inn_rank, 'innings'),
		(a.pitches_thrown, a.ptch_rank, 'pitches_thrown'),
		(a.hit_by_pitches, a.hbp_rank, 'hit_by_pitches'),
		(a.wins, a.win_rank, 'wins'),
		(a.losses, a.loss_rank, 'losses'),
		(a.shutouts, a.shut_rank, 'shutouts'),
		(a.quality_starts, a.qual_rank, 'quality_starts'),
		(a.earned_run_average, a.era_rank, 'earned_run_average'),
		(a.walks_per_9, a.bb9_rank, 'walks_per_9'),
		(a.hits_per_9, a.hits9_rank, 'hits_per_9'),
		(a.home_runs_per_9, a.hr9_rank, 'home_runs_per_9'),
		(a.strikeouts_per_9, a.k9_rank, 'strikeouts_per_9')
	) AS c(value, rank, stat)
	WHERE c.rank <= 10 
	ORDER BY c.stat, c.rank, a.player_name;		
	end;
$$;

--
-- Name: refresh_matviews(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.refresh_matviews() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
REFRESH MATERIALIZED VIEW data.teams_info_expanded_all;
REFRESH MATERIALIZED VIEW data.player_debuts;
REFRESH MATERIALIZED VIEW data.players_info_expanded_all;
REFRESH MATERIALIZED VIEW data.players_info_expanded_tourney;
REFRESH MATERIALIZED VIEW data.batting_stats_all_events;
REFRESH MATERIALIZED VIEW data.batting_stats_player_single_game;
REFRESH MATERIALIZED VIEW data.batting_stats_player_season;
REFRESH MATERIALIZED VIEW data.batting_stats_player_season_combined;
REFRESH MATERIALIZED VIEW data.batting_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW data.batting_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW data.batting_stats_player_lifetime;
REFRESH MATERIALIZED VIEW data.batting_stats_all_events;
REFRESH MATERIALIZED VIEW data.batting_stats_team_season;
REFRESH MATERIALIZED VIEW data.batting_stats_team_playoffs_season;
REFRESH MATERIALIZED VIEW data.fielder_stats_all_events;
REFRESH MATERIALIZED VIEW data.running_stats_all_events;
REFRESH MATERIALIZED VIEW data.running_stats_player_season;
REFRESH MATERIALIZED VIEW data.running_stats_player_season_combined;
REFRESH MATERIALIZED VIEW data.running_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW data.running_stats_team_season;
REFRESH MATERIALIZED VIEW data.running_stats_team_playoffs_season;
REFRESH MATERIALIZED VIEW data.running_stats_player_lifetime;
REFRESH MATERIALIZED VIEW data.running_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW data.pitching_stats_all_appearances;
REFRESH MATERIALIZED VIEW data.pitching_stats_player_season;
REFRESH MATERIALIZED VIEW data.pitching_stats_player_season_combined;
REFRESH MATERIALIZED VIEW data.pitching_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW data.pitching_stats_player_lifetime;
REFRESH MATERIALIZED VIEW data.pitching_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW data.pitching_stats_team_season;
REFRESH MATERIALIZED VIEW data.pitching_stats_team_playoffs_season;
$$;

--
-- Name: refresh_matviews_concurrently(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.refresh_matviews_concurrently() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
REFRESH MATERIALIZED VIEW CONCURRENTLY data.teams_info_expanded_all;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.player_debuts;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.players_info_expanded_all;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.players_info_expanded_tourney;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_all_events;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_single_game;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_season_combined;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_player_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_all_events;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_team_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.batting_stats_team_playoffs_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.fielder_stats_all_events;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_all_events;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_player_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_player_season_combined;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_team_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_team_playoffs_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_player_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.running_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_all_appearances;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_player_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_player_season_combined;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_player_playoffs_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_player_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_player_playoffs_lifetime;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_team_season;
REFRESH MATERIALIZED VIEW CONCURRENTLY data.pitching_stats_team_playoffs_season;
$$;

--
-- Name: rosters_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.rosters_from_timestamp(in_timestamp timestamp without time zone) RETURNS TABLE(team_roster_id integer, team_id character varying, position_id integer, valid_from timestamp without time zone, valid_until timestamp without time zone, player_id character varying, position_type_id numeric, tournament integer)
    LANGUAGE plpgsql
    AS $$
begin
	return query 
	select *
	from data.team_roster r
	where r.valid_from <= in_timestamp 
	and in_timestamp < coalesce(r.valid_until,timezone('utc'::text, now()) + (INTERVAL '1 millisecond'));
end;
$$;

--
-- Name: season_timespan(integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.season_timespan(in_season integer) RETURNS TABLE(season_start timestamp without time zone, season_end timestamp without time zone)
    LANGUAGE sql
    AS $$
SELECT
(
	SELECT first_time FROM data.time_map WHERE DAY = 0 AND season = in_season
) AS season_start,
COALESCE
(
	(
		SELECT first_time - INTERVAL '1 SECOND' FROM data.time_map WHERE DAY = 0 AND season = 
		(in_season + 1)
	), 
	timezone('utc'::text, now())
) AS season_end
$$;
--
-- Name: slugging(bigint, bigint); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.slugging(in_total_bases_from_hits bigint, in_at_bats bigint) RETURNS numeric
    LANGUAGE sql
    AS $$
SELECT (in_total_bases_from_hits::numeric/in_at_bats::numeric)::numeric(10,3)
$$;
--
-- Name: team_slug_creation(); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.team_slug_creation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.url_slug = replace(regexp_replace(lower(unaccent(replace(new.nickname,'&','and'))), '[^A-Za-z'' ]', '','g'),' ','-');
	RETURN new;
END;
$$;
--
-- Name: teams_from_timestamp(timestamp without time zone); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.teams_from_timestamp(in_timestamp timestamp without time zone) RETURNS TABLE(teams_info_expanded_all_id bigint, team_id character varying, location text, nickname text, full_name text, team_abbreviation character varying, url_slug character varying, current_team_status text, valid_from timestamp without time zone, valid_until timestamp without time zone, gameday_from integer, season_from integer, tournament_from integer, phase_type_from character varying, team_main_color character varying, team_secondary_color character varying, team_slogan character varying, team_emoji character varying, division character varying, division_id character varying, league character varying, league_id character varying, tournament_name character varying, modifications character varying[], stadium_id character varying, stadium_name text, stadium_nickname text)
    LANGUAGE plpgsql
    AS $$
begin
	return query 
		select *
		from data.teams_info_expanded_all t
		where t.valid_from <= in_timestamp 
		and in_timestamp < coalesce(t.valid_until,timezone('utc'::text, now()) + (INTERVAL '1 millisecond'));
end;
$$;

--
-- Name: timestamp_from_gameday(integer, integer); Type: FUNCTION; Schema: data; Owner: -
--
CREATE FUNCTION data.timestamp_from_gameday(in_season integer, in_gameday integer) RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$
SELECT first_time FROM data.time_map where season = in_season and day = in_gameday;
$$;


--
-- Name: players player_insert; Type: TRIGGER; Schema: data; Owner: -
--
CREATE TRIGGER player_insert BEFORE INSERT ON data.players FOR EACH ROW EXECUTE FUNCTION data.player_slug_creation();
--
-- Name: teams team_insert; Type: TRIGGER; Schema: data; Owner: -
--
CREATE TRIGGER team_insert BEFORE INSERT ON data.teams FOR EACH ROW EXECUTE FUNCTION data.team_slug_creation();


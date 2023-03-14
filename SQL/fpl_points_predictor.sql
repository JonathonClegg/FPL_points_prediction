CREATE DATABASE IF NOT EXISTS fpl_points_predictions;
USE fpl_points_predictions;


CREATE TABLE teams (
	team_ID int,
    team_name varchar(50),
    PRIMARY KEY (team_ID)
);
CREATE TABLE players(
	player_ID int,
    player_name varchar(50),
    PRIMARY KEY (player_ID)
);
CREATE TABLE positions(
	position_ID int,
    position_name varchar(50),
    PRIMARY KEY (position_ID)
);
CREATE TABLE seasons(
	season_ID int,
    year YEAR,
    PRIMARY KEY (season_ID)
);
CREATE TABLE matches(
	match_ID INT,
    season_id INT,	
    date DATE,
    h_team_id INT,
    a_team_id INT,
    h_team_spi FLOAT,
    a_team_spi FLOAT,
    prob_h_win FLOAT,
    prob_a_win FLOAT,
    prob_tie FLOAT,
    h_proj_score FLOAT,
    a_proj_score FLOAT,
    importance_h FLOAT,
    importance_a FLOAT,
    h_score INT,
    a_score INT,
    h_xg FLOAT,
    a_xg FLOAT,
    h_nsxg FLOAT,
    a_nsxg FLOAT,
    PRIMARY KEY (match_ID),
    FOREIGN KEY (season_id) REFERENCES seasons (season_ID),
    FOREIGN KEY (h_team_id) REFERENCES teams (team_ID),
    FOREIGN KEY (a_team_id) REFERENCES teams (team_ID)
);

CREATE TABLE player_matches(
	player_match_ID INT,
    player_id INT,
    position_id INT,
    player_team_id INT,	
    was_home INT,	
    h_team_id INT,	
    a_team_id INT,	
    date DATE,	
    season_id INT,	
    round INT,	
    total_points INT,	
    xP FLOAT,
    bonus INT,	
    bps INT,	
    minutes INT,	
    goals INT,	
    shots INT,	
    xG FLOAT,
    xA FLOAT,
    assists INT,	
    key_passes INT,	
    npg INT,
    xGChain FLOAT,
    xGBuildup FLOAT,
    yellow_cards INT,	
    red_cards INT,	
    clean_sheets INT,	
    goals_conceded INT,	
    own_goals INT,	
    penalties_missed INT,	
    penalties_saved INT,
    saves INT,	
    influence FLOAT,
    creativity FLOAT,
    threat FLOAT,
    ict_index FLOAT,
    npxG FLOAT,
    selected FLOAT,
    transfers_in INT,
    transfers_out INT,
    value INT,
    PRIMARY KEY (player_match_ID),
    FOREIGN KEY (season_id) REFERENCES seasons (season_ID),
    FOREIGN KEY (h_team_id) REFERENCES teams (team_ID),
    FOREIGN KEY (a_team_id) REFERENCES teams (team_ID),
    FOREIGN KEY (player_id) REFERENCES players (player_ID),
    FOREIGN KEY (position_id) REFERENCES positions (position_ID),
    FOREIGN KEY (player_team_id) REFERENCES teams (team_ID)
);

ALTER TABLE player_matches
ADD match_id INT;

SET SQL_SAFE_UPDATES = 0;
UPDATE player_matches pm
SET pm.match_id = (
    SELECT m.match_ID
    FROM matches m
    WHERE m.date = pm.date
      AND m.h_team_id = pm.h_team_id
      AND m.a_team_id = pm.a_team_id
);
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE player_matches MODIFY COLUMN match_id VARCHAR(50) AFTER player_match_ID;
ALTER TABLE player_matches MODIFY COLUMN match_id INT;

ALTER TABLE player_matches
ADD FOREIGN KEY (match_id) REFERENCES matches(match_ID);

ALTER TABLE player_matches
DROP FOREIGN KEY player_matches_ibfk_2,
DROP FOREIGN KEY player_matches_ibfk_3
;

ALTER TABLE player_matches
DROP COLUMN h_team_id,
DROP COLUMN a_team_id,
DROP COLUMN date
;


###QUERIES###

SELECT pm.player_id AS "Player ID", p.player_name AS "Player Name", 
		SUM(pm.total_points) AS "Total Points"
FROM player_matches pm
LEFT JOIN players p
ON pm.player_id = p.player_ID
GROUP BY pm.player_id
ORDER BY SUM(pm.total_points) DESC
LIMIT 5;

SELECT pm.player_id AS "Player ID", p.player_name AS "Player Name", 
		SUM(pm.total_points) AS "Total Points", 
		ROUND(SUM(pm.xP),2) AS "Total Expected Points", 
        ROUND(SUM(pm.total_points) - SUM(pm.xP),2) AS "Total Points - xP"
FROM player_matches pm
LEFT JOIN players p
ON pm.player_id = p.player_ID
GROUP BY pm.player_id
ORDER BY SUM(total_points - xP) DESC
LIMIT 5;


WITH player_performance AS (
    SELECT pm.player_id, p.player_name, 
    ((pm.total_points) - (pm.xP)) AS "total_points - xP",
    CASE
        WHEN (pm.total_points) - (pm.xP) > 0 THEN 1
        ELSE 0
    END AS over_performance
    FROM player_matches pm
    LEFT JOIN players p
    ON pm.player_id = p.player_ID
)
SELECT player_name AS "Player Name", 
		SUM(over_performance) AS "# of Over Performances"
FROM player_performance
GROUP BY player_name
ORDER BY SUM(over_performance) DESC
LIMIT 5;

SELECT t.team_name AS "Team", SUM(pm.total_points) "Total Points", 
	SUM(pm.goals) AS "Goals", 
    SUM(pm.assists) AS "Assists", 
    SUM(pm.goals_conceded) AS " Goals Conceded", 
	SUM(pm.bonus) AS "Bonus Points", 
    RANK() OVER (ORDER BY SUM(pm.bonus) DESC) AS "Bonus Points Index" 
FROM player_matches pm
LEFT JOIN teams t
ON pm.player_team_id = t.team_ID
WHERE pm.season_id = 3
GROUP BY pm.player_team_id
ORDER BY SUM(pm.total_points) DESC
LIMIT 5;

SELECT p.player_name AS "Player Name", 
       SUM(CASE WHEN pm.was_home = 1 THEN pm.goals ELSE 0 END) AS "Home Goals",
       SUM(CASE WHEN pm.was_home = 0 THEN pm.goals ELSE 0 END) AS "Away Goals",
       SUM(pm.goals) AS "Total Goals",
       SUM(pm.total_points) AS "Total Points"
FROM player_matches pm
LEFT JOIN players p ON pm.player_id = p.player_ID
WHERE pm.season_id = 3
GROUP BY pm.player_id
ORDER BY SUM(pm.goals) DESC
LIMIT 5;


#Players per position, avergae points per position
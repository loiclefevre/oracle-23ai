-- Check our user
select user, sys_context( 'userenv', 'proxy_user' ) from dual;














-- SELECT without FROM!
select user, sys_context( 'userenv', 'proxy_user' );
-- Trusty old dual is staying!










-- Create Data Usecase Domains
-- Define usage information for common attributes

-- Standard surrogate primary key column
create domain if not exists surrogate_id as
  --
  integer not null
  ---
  annotations( PK, system_generated );
  
  
  
  


-- Create standard value for insert timestamps
create domain if not exists insert_timestamp as 
  --
  timestamp default on null systimestamp
  ---
  annotations( system_generated );




  
  
  
-- Create standard value for update timestamps
create domain if not exists update_timestamp as 
  --
  timestamp default on null for insert and update systimestamp
  ---
  annotations( system_generated );
  
  
  
  
  
 
  
  
  
  
-- Team points: goals/runs/tries/baskets/...
create domain if not exists game_score as 
  integer 
  --
  constraint zero_or_higher
    check ( game_score >= 0 )
  ---
  annotations( Title 'Points earned during game' );






-- Ensure positive values for game lengths
create domain if not exists game_duration as
  interval day(0) to second(0)
  --
  constraint gt_zero_duration
    check ( game_duration > interval '0' hour )
  ---
  annotations( Title 'Length of matches' );




-- Create tables 
create table if not exists locations (
  location_id     surrogate_id            constraint location_pk primary key,
  location_name   varchar2(255)           not null annotations( Display 'Stadium name' ),
  insert_datetime domain insert_timestamp,
  update_datetime timestamp domain update_timestamp
)
annotations( Display 'Sporting stadiums' );

desc locations;






-- Table exists => do nothing; NOT create or replace
create table if not exists locations (
  different_columns json 
);

desc locations;







create table if not exists teams (
  team_id   int domain surrogate_id
    constraint teams_pk primary key
    annotations( Display 'Team ID' ),
  --
  team_name varchar2(255)
    constraint teams_c unique not null
    annotations( UC ),
  --
  home_stadium
    references locations ( location_id ) not null
    annotations( FK 'locations' ),
  insert_datetime timestamp domain insert_timestamp,
  update_datetime timestamp domain update_timestamp
) annotations( Display 'Team details' );
  
  
  
  
  
  
  
create table if not exists games (
  home_team_id          references teams ( team_id ) not null,
  away_team_id          references teams ( team_id ) not null,
  location_id           references locations ( location_id ) not null,
  game_start_time       timestamp not null,
  scheduled_game_length game_duration not null,
  actual_game_length    game_duration,
  home_team_score       integer,
  away_team_score       integer,
  insert_datetime       timestamp,
  update_datetime       timestamp,
  constraint games_pk
    primary key ( home_team_id, away_team_id, game_start_time ),
  constraint games_location_u 
    unique ( location_id, game_start_time )
);



-- Put the data usecase domains to work!
-- Find all the SURROGATE_ID columns
select table_name, column_name, nullable
from   user_tab_cols
where  domain_name = 'SURROGATE_ID';


-- Find all the GAME_DURATION columns
select table_name, column_name
from   user_tab_cols
where  domain_name = 'GAME_DURATION';





-- Check the data usecase domains on GAMES
select column_name, tc.domain_name, nullable, data_default, search_condition_vc
from   user_tab_cols tc 
left join (
  select table_name, column_name, search_condition_vc 
  from   user_cons_columns cc
  join   user_constraints c
  using ( table_name, constraint_name )
  where  c.constraint_type = 'C' 
  and    search_condition_vc not like '%NOT NULL%'
  and    table_name = 'GAMES'
) c
using ( table_name, column_name )
where  table_name = 'GAMES'
order  by tc.column_id;







-- Whooops, we forgot some!
-- Apply the data usecase domains to existing columns
alter table games
  modify ( 
    home_team_score domain game_score,  
    away_team_score domain game_score,  
    
    insert_datetime domain insert_timestamp,  
    update_datetime domain update_timestamp 
  );




-- Now Domains are in place now
select column_name, tc.domain_name, nullable, data_default, search_condition_vc
from   user_tab_cols tc 
left join (
  select table_name, column_name, search_condition_vc 
  from   user_cons_columns cc
  join   user_constraints c
  using ( table_name, constraint_name )
  where  c.constraint_type = 'C' 
  and    search_condition_vc not like '%NOT NULL%'
  and    table_name = 'GAMES'
) c
using ( table_name, column_name )
where  table_name = 'GAMES'
order  by tc.column_id;









-- Usage annotations
-- Define usage metadata on objects

-- View the annotations details
select object_name, column_name, domain_name, annotation_name, annotation_value
from   user_annotations_usage
where  object_name in ( 'LOCATIONS', 'TEAMS', 'GAMES' )
order  by annotation_name, object_name;




-- Add the annotations for GAMES
alter table if exists games 
  modify (
    home_team_id          annotations( FK 'teams', PK ),
    away_team_id          annotations( FK 'teams', PK ),
    location_id           annotations( FK 'locations', UC ),
    game_start_time       annotations( UC, PK, Display 'Kick-off time' ),
    scheduled_game_length annotations( Display 'Scheduled length' ),
    actual_game_length    annotations( Display 'Time played' ),
    home_team_score       annotations( Display 'Home team goals' ),
    away_team_score       annotations( Display 'Away team goals' )
);


-- Find the GAMES annotations
select object_name, column_name, domain_name, annotation_name, annotation_value
from   user_annotations_usage
where  object_name = 'GAMES'
order  by annotation_name;




-- Find the system generated columns
select object_name, column_name, annotation_value 
from   all_annotations_usage
where  annotation_name = 'SYSTEM_GENERATED'
  and  object_type = 'TABLE'
order  by object_name, column_name;



-- Find the Foreign Keys via annotations
select object_name, column_name, annotation_value 
from   all_annotations_usage
where  annotation_name = 'FK';






-- Data Load

-- Single row inserts 
--  - Slow if adding many rows
--  - Fiddly if you need to change column list
-- insert into locations values ( 1, 'Winner stadium' );
-- insert into locations values ( 2, 'Big park' );
-- insert into locations values ( 3, 'Loser road' );
-- insert into locations values ( 4, 'Small street' );
-- insert into locations values ( 5, 'Old town lane' ); 
-- insert into locations values ( 6, 'Giant stadium' );







-- Table values constructor - insert many rows in one statement
insert into locations ( location_id, location_name )
values ( 1, 'Winner stadium' ), 
       ( 2, 'Big park' ), 
       ( 3, 'Loser road' ), 
       ( 4, 'Small street' ), 
       ( 5, 'Old town lane' ), 
       ( 6, 'Giant stadium' );
       
      
      
      
   
   
-- Can also query TVC
select t.* from ( 
  values ( 1, 'Champions United',   1 ), 
         ( 2, 'Runner-up City',     2 ), 
         ( 3, 'Relegated Athletic', 3 ), 
         ( 4, 'Underdogs United',   4 ), 
         ( 5, 'Midtable Town',      5 ), 
         ( 6, 'Upstart FC',         6 ) 
) t ( team_id, team_name, home_stadium );
      
      
      
-- TVC to generate data - teams list
merge into teams t
using ( select * from ( 
          values ( 1, 'Champions United', 1 ), 
                 ( 2, 'Runner-up City', 2 ), 
                 ( 3, 'Upstart FC', 3 ), 
                 ( 4, 'Underdogs United', 4 ), 
                 ( 5, 'Midtable Town', 5 ), 
                 ( 6, 'Relegated Athletic', 6 ) 
        ) t ( team_id, team_name, home_stadium ) ) v
on ( t.team_id = v.team_id )
when not matched then 
  insert ( t.team_id, t.team_name, t.home_stadium )
  values ( v.team_id, v.team_name, v.home_stadium )
when matched then 
  update set t.team_name = v.team_name, t.home_stadium = v.home_stadium; 
       
       



exec dbms_random.seed(0);

-- Insert match data
insert into games ( 
  home_team_id, away_team_id, location_id, 
  game_start_time, scheduled_game_length
)
with game_details as (
  select 
    floor ( systimestamp - 94, 'iw' ) + interval '6 15' day to hour first_date,
    interval '90' minute scheduled_game_length 
), all_games as (
  select home.team_id home_team_id, away.team_id away_team_id, loca.location_id,
         scheduled_game_length, first_date
  from   teams home
  join   teams away
  on     home.team_id <> away.team_id
  join   locations loca
  on     loca.location_id = home.home_stadium
  cross join game_details
  order  by dbms_random.value
)
  select home_team_id, away_team_id, location_id, 
         first_date + 
           numtodsinterval ( 
             ( floor ( ( rownum - 1 ) / 2 ) * 7 ) +
               ( case mod ( rownum, 2 ) when 0 then 6 else 7 end ), 
             'day' 
           ) start_date,
         scheduled_game_length
  from   all_games a
  order  by start_date;

commit;


-- Check the data
select * from locations;
select * from teams;



-- View the games - intervals in DD HH24:MI:SS format
select home_team_id, away_team_id, location_id, scheduled_game_length
from   games g;





-- Add domain expression to convert Day to Second Interval => minutes
alter domain if exists game_duration
  add display to_char (
    extract ( hour from game_duration ) * 60 + 
    extract ( minute from game_duration ) + 
    round ( extract ( second from game_duration ) / 60 ) 
  ) || ' minutes' ;


-- Use domain formatting for duration with DOMAIN_DISPLAY()
select home_team_id, away_team_id, location_id, scheduled_game_length,
       DOMAIN_DISPLAY( scheduled_game_length ) game_minutes
from   games g;






-- Enter results

-- Constraint from domain (23ai) => can't have negative scores
update games 
set    home_team_score = -1;





-- Assign score based on ID diff between teams
create or replace function get_score ( first_team_id int, second_team_id int ) return int 
as
begin
  return case 
    when first_team_id - second_team_id in ( -5, -4 ) then 4
    when first_team_id - second_team_id in ( -1, 2 ) then 2
    when first_team_id - second_team_id > 0 then 1
    when first_team_id - second_team_id < -3 then 1
    when first_team_id - second_team_id in ( -3, 3 ) then 1
    else 0 
  end;
end get_score;
/



-- Extended CASE expressions in PL/SQL
create or replace function get_score ( first_team_id int, second_team_id int ) return int 
as
begin
  /* Dangling predicate */
  return case first_team_id - second_team_id
    when -5, -4 then 4 -- equal any
    when in ( -1, 2 ) then 2
    when > 0, < -3, in ( -3, 3 ) then 1
    else 0 
  end;
end get_score;
/




-- Enter some results
update games
set    home_team_score = get_score ( home_team_id, away_team_id ),
       away_team_score = get_score ( away_team_id, home_team_id ),
       actual_game_length = 
         scheduled_game_length 
           + numtodsinterval ( dbms_random.value ( 0, 10 ), 'minute' )
where  game_start_time < systimestamp;

commit;






-- View results => sorts low -> high: opposite of desired!
select home.team_name, home_team_score, 
       away.team_name, away_team_score
from   games
join   teams home
on     home_team_id = home.team_id
join   teams away
on     away_team_id = away.team_id
where  game_start_time < systimestamp
order  by home_team_score, away_team_score;







-- Add sort expression to score domain
alter domain if exists game_score
  add order game_score * -1;


-- View results; use domain sorting with DOMAIN_ORDER()
select home.team_name, home_team_score, 
       away.team_name, away_team_score,
       DOMAIN_ORDER( home_team_score ) home_sort,
       DOMAIN_ORDER( away_team_score ) away_sort
from   games
join   teams home
on     home_team_id = home.team_id
join   teams away
on     away_team_id = away.team_id
where  game_start_time < systimestamp
order  by DOMAIN_ORDER( home_team_score ),
          DOMAIN_ORDER( away_team_score );









-- Report total time played/month
select trunc( game_start_time, 'mm' ) games_month, 
       actual_game_length
from   games
group  by trunc( game_start_time, 'mm' );










-- Floor & ceil for datetimes; sum over interval; group by alias
select floor( game_start_time, 'mm' ) games_month, 
       sum( actual_game_length ) actual_duration, 
       floor( sum( actual_game_length ), 'hh' ) round_down_hour, 
       ceil( sum( actual_game_length ), 'mi' ) round_up_minute
from   games
group  by games_month;







-- Find "Runnerup" team - use LIKE?
select team_id, team_name
from   teams
where  team_name like 'Runnerup%';






select * from teams;







-- Use fuzzy matching!
select team_id, team_name, 
       fuzzy_match( jaro_winkler, team_name, 'Runnerup' ) jw_similarity, 
       fuzzy_match( levenshtein, team_name, 'Runnerup' ) lev_similarity,
       fuzzy_match( longest_common_substring, team_name, 'Runnerup' ) lcs
from   teams
order  by fuzzy_match( jaro_winkler, team_name, 'Runnerup' ) desc
fetch  first row only;











-- Champions United moves to new home stadium; 
-- update their future home games to this new location
insert into locations 
  values ( 7, 'New stadium', default, default );

update teams
set    home_stadium = 7
where  team_id = 1;

commit;
-- Need to update future games to new location




-- Correlated update to change the locations
update games g
set    g.location_id = ( 
          select t.home_stadium from teams t
          where  g.home_team_id = t.team_id
          and    t.team_id = 1
       )
where  g.home_team_id = 1
and    g.game_start_time > systimestamp;  
-- But what's changed?

rollback;




declare
  type game_changes is record (
    away_team_id    integer,
    old_update_time timestamp,
    new_update_time timestamp,
    old_location    integer,
    new_location    integer
  );
  type game_changes_arr 
    is table of game_changes
    index by pls_integer;
  
  away_teams dbms_sql.number_table;
  game_start_times dbms_sql.timestamp_table;
  
  changes game_changes_arr;
begin

  /* 
     Direct join to get new home location
     OLD/NEW returning clauses to find changed values 
   */
  update games game
  set    game.location_id = team.home_stadium,
         game.update_datetime = null -- default will kick in
  from   teams team
  where  game.home_team_id = team.team_id
  and    game.game_start_time > systimestamp
  and    team.team_id = 1
  returning 
    new away_team_id, 
    old game.update_datetime, 
    game.update_datetime, -- defaults to new
    old location_id, 
    new location_id
  bulk collect into changes;
  
  
  
  
  -- Convert change array to JSON
  dbms_output.put_line ( 
    json_serialize ( 
      json ( changes ) returning varchar2 pretty 
    )
  );
  
  
  
  dbms_output.put_line ( '*********************' );
  dbms_output.put_line ( '*********************' );
  
  
  
  -- Convert to a JSON array
  dbms_output.put_line ( 
    json_serialize ( 
      json_query ( json ( changes ), '$.*' with array wrapper ) 
        returning varchar2 pretty 
    )
  );
  
  
  rollback;
  
end;
/






-- Get time difference between updates in seconds
--   => Intervals are fiddly
--   => Translate datetimes to epochs
--   => no built-in support for epochs :(
   
   
   
--   So let's use JavaScript!





create or replace function timestamp_to_epoch (
  "ts" timestamp
) return number
as mle language javascript
{
    var d = new Date(ts);
    var utcSeconds = d.getTime() / 1000;
    return utcSeconds;
};
/




-- Call the JavaScript function
select game_start_time, 
       timestamp_to_epoch( game_start_time ) start_epoch 
from   games;







set serveroutput on
declare
  type game_changes is record (
    away_team_id    integer,
    old_update_time integer,
    new_update_time integer,
    old_location    integer,
    new_location    integer
  );
  type game_changes_arr 
    is table of game_changes
    index by pls_integer;
  
  away_teams dbms_sql.number_table;
  game_start_times dbms_sql.timestamp_table;
  
  changes game_changes_arr;
  change_json json;
begin

  /* 
     Direct join to get new home location
     OLD/NEW returning clauses to find changed values 
   */
  update games game
  set    game.location_id = team.home_stadium,
         game.update_datetime = null -- default will kick in
  from   teams team
  where  game.home_team_id = team.team_id
  and    game.game_start_time > systimestamp
  and    team.team_id = 1
  returning 
    new away_team_id, 
    timestamp_to_epoch( old game.update_datetime ), 
    timestamp_to_epoch( game.update_datetime ), -- defaults to new
    old location_id, 
    new location_id
  bulk collect into changes;
  
  -- Convert to array
  change_json := json_query ( 
    json ( changes ), 
    '$.*' with array wrapper returning json 
  );
  
  
  /* JSON_transform enhancements - apply expression to all array elements */
  select json_transform ( 
           change_json,
           nested '$[*]' (
             set '@.secondsSincePrevUpdate' = 
               path '@.NEW_UPDATE_TIME - @.OLD_UPDATE_TIME',
             remove '@.NEW_UPDATE_TIME',
             remove '@.OLD_UPDATE_TIME'
           )
         )
  into   change_json;
  
  dbms_output.put_line ( 
    json_serialize ( 
      change_json returning varchar2 pretty
    )
  );
  
  rollback;
end;
/

desc games;


-- JSON API
create or replace json relational duality view games_json as
select json {'_id': { 
                'homeTeam' : g.home_team_id,
                'awayTeam' : g.away_team_id, 
                'startTime': g.game_start_time 
              },
             'duration': g.scheduled_game_length,
             'location': (
                select json { 'locationId' : l.location_id, 'locationName': l.location_name }
                from   locations l with update 
                where  l.location_id = g.location_id
             ), 
             'home':
               ( select json {'teamId' :home.team_id, 'teamName' : home.team_name}
                 from   teams home 
                 where  home.team_id = g.home_team_id ),
             'away':
               ( select json {'teamId' : away.team_id, 'teamName' : away.team_name}
                 from   teams away 
                 where  away.team_id = g.away_team_id )}
from games g with insert update delete;


select json_serialize ( data returning varchar2 ) from games_json;







-- No games 60 minutes long
select * from games where scheduled_game_length = interval '1' hour;

-- Insert JSON into the view
insert into games_json values (
  '{
      "_id": { "homeTeam": 3, "awayTeam": 4, "startTime": "2024-03-13T15:00:00" },
      "duration": "PT1H00M",
      "location": { "locationId": 3, "locationName": "Loser road" },
      "home": { "teamId": 3, "teamName": "Upstart FC" },
      "away": { "teamId": 4, "teamName": "Midtable Town" }
  }' 
);

-- Now there is!
select * from games where scheduled_game_length = interval '1' hour;

commit;












-- Function to say if home team won
create or replace function home_win( home_score int, away_score int ) return boolean 
as
begin
  return home_score > away_score;
end home_win;
/





-- But to use in SQL you needed a wrapper function
with function home_win_yes_no( home_score int, away_score int ) return varchar2 
as
begin
  return case 
    when home_win( home_score, away_score) then 'Y'
    else 'N'
  end;
end;
select * from games
where  home_win_yes_no( home_team_score, away_team_score ) = 'Y';
/






-- No more! You can use Boolean in SQL!
select * from games
where  home_win( home_team_score, away_team_score ) is true;








-- Lots of Boolean implicit conversions
select * from games
where  home_win( home_team_score, away_team_score ) 
         in ( true, 'Y', 'TRUE', 1, 'ON', 'YES' );

       
       
       
       

-- Can select boolean expressions
select
  true, 
  1 = 2, 
  exists( select null from games );






-- Add result flags as boolean virtual columns
alter table games
  add ( 
    is_finished boolean 
      as ( actual_game_length is not null ),
    is_home_win boolean 
      as ( actual_game_length is not null and home_team_score > away_team_score ),
    is_draw boolean 
      as ( actual_game_length is not null and home_team_score = away_team_score )
  );
  
  
  
  
  
-- Return boolean values
select is_home_win, is_draw, count(*)
from   games
where  is_finished --is true
group  by is_home_win, is_draw
order  by is_home_win, is_draw;









create index home_away_scores 
  on games( home_team_score > away_team_score );

-- Back to the function: view the plan => no index access
select * from games
where  home_win( home_team_score, away_team_score ) = true;







-- Enable the transpiler; Faster = true!
alter session set sql_transpiler = on;




-- View the plan
select * from games
where  home_win( home_team_score, away_team_score ) = true;




-- Only transpile pure functions with no SQL statements or PL/SQL
create or replace function home_win( home_score int, away_score int ) return boolean 
as
  dummy dual%rowtype;
begin
  return home_score > away_score;
end home_win;
/

select * from games
where  home_win( home_team_score, away_team_score ) = true;


-- Disable the transpiler (default)
alter session set sql_transpiler = off;





-- Find Rock-paper-scissors "result triangle"
--
--   * A beat B
--   * B beat C
--   * C beat A 
--   
--  This is tricky in SQL!
--  
-- 
--  => Enter property graphs & SQL/PGQ!




-- First create property graph
create property graph if not exists results_graph
  vertex tables (
    teams
      key ( team_id )
      properties all columns
  )
  edge tables (
    games
      source key ( home_team_id ) references teams ( team_id )
      destination key ( away_team_id ) references teams ( team_id )
      properties all columns
  );
  
  
  
  
-- Then run SQL/PGQ query
select * from GRAPH_TABLE(
  results_graph
  match ( a )
  -[ g1 where home_win( g1.home_team_score, g1.away_team_score ) is true ]-> ( b )
  -[ g2 where home_win( g2.home_team_score, g2.away_team_score ) is true ]-> ( c )
  -[ g3 where home_win( g3.home_team_score, g3.away_team_score ) is true ]-> ( a )
  columns ( 
    a.team_name || ' beat ' || b.team_name || ' beat ' || c.team_name as res
  )
);




-- Reporting access

-- READ => SELECT without FOR UPDATE
grant read on games 
  to reporting_user;
  








-- Give reporting user query privileges on all league_owner tables
grant read any table
  on schema league_owner 
  to reporting_user;
-- Now run reporting queries






-- Create new table - automatically have access!
create table players (
  player_id   surrogate_id primary key,
  player_name varchar2(255) not null
);

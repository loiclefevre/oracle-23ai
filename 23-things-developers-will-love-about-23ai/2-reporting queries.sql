select user;

select count(*) 
from   league_owner.games;

/* No access */
select count(*) 
from   league_owner.locations;

/* Doesn't exist */
select count(*) 
from   league_owner.players;



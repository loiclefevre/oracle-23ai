-- Remove users to reset 
-- Doesn't exist? => no error!
drop user if exists reporting_user cascade;
drop user if exists admin_user     cascade;
drop user if exists league_owner   cascade;





  
  
  
  
-- LEAGUE_OWNER can't login (18c feature)
create user if not exists league_owner
  no authentication;









-- Create user ADMIN_USER to run script with low privileges.
grant create session 
  to admin_user 
  identified by "free";

-- Allow ADMIN_USER user to proxy through the league owner
alter user league_owner 
  grant connect through admin_user;





-- New Developer role grants league_owner system privileges needed
grant db_developer_role, unlimited tablespace
  to league_owner;

-- Also grant the possibility for creating JavaScript stored procedures!
grant execute on javascript
  to league_owner;








-- Make reporting user with only create session privs
grant create session 
  to reporting_user
  identified by "free";

grant unlimited tablespace to gerald;
grant execute on javascript to gerald;
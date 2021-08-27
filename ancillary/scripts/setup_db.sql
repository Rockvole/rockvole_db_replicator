create database client_db;
create user 'aversions'@'localhost' identified by 'aversions';
grant all on client_db.* to 'aversions'@'localhost' with max_user_connections 20;

create database server_db;
grant all on server_db.* to 'aversions'@'localhost' with max_user_connections 20;

create database admin1;
grant all on admin1.* to 'aversions'@'localhost' with max_user_connections 20;

create database admin2;
grant all on admin2.* to 'aversions'@'localhost' with max_user_connections 20;

create database sharecal;
grant all on sharecal.* to 'aversions'@'localhost' with max_user_connections 20;

create database default_db;
grant all on default_db.* to 'aversions'@'localhost' with max_user_connections 20;

./rockvole_helper.sh addserver WRITE

CREATE USER IF NOT EXISTS 'travelo_user'@'%' IDENTIFIED BY 'travelo_pass';
GRANT ALL PRIVILEGES ON travelo.* TO 'travelo_user'@'%';
FLUSH PRIVILEGES;

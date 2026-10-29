-- Replication MariaDB maitre (web1) / esclave (web2) - TP3
-- Mots de passe masques dans ce fichier

-- Sur web1 (maitre) : compte de replication autorise depuis web2 uniquement
CREATE USER 'repl'@'192.168.56.12' IDENTIFIED BY '********';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.56.12';
SHOW MASTER STATUS;          -- mysql-bin.000001, position 672
SELECT @@gtid_binlog_pos;    -- 0-1-2

-- Sur web2 (esclave) : suivi du maitre par GTID
CHANGE MASTER TO MASTER_HOST='192.168.56.11', MASTER_USER='repl',
  MASTER_PASSWORD='********', MASTER_USE_GTID=slave_pos;
START SLAVE;
SHOW SLAVE STATUS\G          -- Slave_IO_Running: Yes / Slave_SQL_Running: Yes

-- Sur web1 : base et utilisateur de l'application
CREATE DATABASE boutique;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY '********';
GRANT ALL PRIVILEGES ON boutique.* TO 'appuser'@'localhost';
CREATE TABLE boutique.produits (id INT AUTO_INCREMENT PRIMARY KEY, nom VARCHAR(50), prix DECIMAL(6,2));
INSERT INTO boutique.produits (nom, prix) VALUES ('Clavier', 29.90), ('Souris', 15.50);

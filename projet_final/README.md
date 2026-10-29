# Projet final - Infrastructure web securisee, automatisee et supervisee

Auteur : Nihad
Outil : Ansible (playbook `site.yml`)

## Architecture

| Serveur | IP privee      | Roles Ansible                                              |
|---------|----------------|------------------------------------------------------------|
| srv-tp  | 192.168.56.10  | common, firewall, ssh_hardening, node_exporter, haproxy, monitoring |
| web1    | 192.168.56.11  | common, firewall, ssh_hardening, node_exporter, webserver, mariadb (maitre) |
| web2    | 192.168.56.12  | common, firewall, ssh_hardening, node_exporter, webserver, mariadb (esclave) |

Flux :
- Visiteurs -> srv-tp:80 (HAProxy) -> web1:80 / web2:80 (Nginx), repartition round robin.
- web1 (MariaDB maitre) -> web2 (MariaDB esclave) : replication par GTID sur le port 3306.
- Prometheus (srv-tp:9090) interroge les node_exporter (port 9100) des 3 serveurs.
- Grafana (srv-tp:3000) affiche le tableau de bord "TP5 - Supervision des serveurs".

## Securite appliquee

- SSH : connexion root interdite, authentification par cle uniquement, liste blanche
  (`alice` sur srv-tp, `nina` sur web1/web2), 3 essais maximum.
- fail2ban : bannissement 10 min apres 3 echecs SSH en 10 min (srv-tp jamais banni par les serveurs web).
- nftables : politique "tout bloquer par defaut".
  - srv-tp : 22, 80, 443, 8404 ouverts ; 3000 et 9090 reserves au poste admin (192.168.56.1).
  - web1/web2 : 22 ouvert ; 80 et 9100 reserves a srv-tp ; 3306 reserve a l'autre serveur de base de donnees.
- Mots de passe MariaDB chiffres avec ansible-vault (`group_vars/all/vault.yml`).

## Prerequis

- Ansible installe sur srv-tp (noeud de controle).
- Cle SSH de nina (srv-tp) deployee sur web1 et web2, empreintes enregistrees dans `known_hosts`.
- Ubuntu 26.04 : sudo-rs n'est pas compatible avec l'invite d'Ansible, on utilise `sudo.ws`
  (`ansible_become_exe=sudo.ws` dans l'inventaire).

## Deploiement

    cd ~/projet
    cp group_vars/all/vault.yml.example group_vars/all/vault.yml   # puis y mettre les mots de passe
    ansible-vault encrypt group_vars/all/vault.yml                 # une seule fois
    ansible-playbook site.yml --syntax-check
    ansible-playbook site.yml -K --ask-vault-pass

Relancer la meme commande ne modifie rien si l'infrastructure est conforme (idempotence).

## Exploitation courante

- Ajouter un serveur web : l'ajouter au groupe `[web]` de `inventory.ini` avec son `ip_privee`,
  creer son fichier `host_vars/`, puis relancer `site.yml`. HAProxy, Prometheus et /etc/hosts
  sont mis a jour automatiquement.
- Modifier un mot de passe : `ansible-vault edit group_vars/all/vault.yml`.
- Administrer web1/web2 : passer par srv-tp (bastion) : `ssh alice@srv-tp`, `su - nina`, `ssh web1`.
- Statistiques HAProxy : http://192.168.56.10:8404/stats
- Prometheus (alertes) : http://192.168.56.10:9090 > classic web UI > Alerts
- Grafana : http://192.168.56.10:3000

## Alertes configurees (Prometheus)

| Alerte              | Condition                         | Delai | Niveau   |
|---------------------|-----------------------------------|-------|----------|
| ServeurInjoignable  | exporter injoignable (up == 0)    | 1 min | critical |
| MemoireElevee       | RAM utilisee > 80 %               | 1 min | warning  |
| CPUEleve            | CPU > 90 %                        | 5 min | warning  |
| DisquePresquePlein  | partition / remplie > 85 %        | 5 min | warning  |

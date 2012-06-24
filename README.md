Admin LinuxFr.org
=================

Ce dépôt git contient les fichiers qui servent à l'administration
du serveur LinuxFr.org -- pas les informations confidentielles ;-)


Install on Debian Squeeze
-------------------------

On commence par installer quelques paquets debian pour jouer :

    # aptitude install vim git zsh ack-grep curl openssl colordiff
    # aptitude install python-pygments imagemagick hunspell hunspell-fr

Et de quoi compiler :

    # aptitude install build-essential autoconf libxml2-dev libreadline-dev libssl-dev
    # aptitude install libxslt1-dev zlib1g-dev

Si vous le souhaitez, vous pouvez en profiter pour mettre en place un Openssh :

    # aptitude install openssh-server
    # /etc/init.d/ssh start

Un serveur web, nginx :

    # aptitude install nginx

On va maintenant se créer un compte utilisateur linuxfr :

    # adduser --home /data/prod/linuxfr --gecos 'LinuxFr <linuxfr@linuxfr>' --disabled-password linuxfr
    # ln -s /data/prod/linuxfr /var/www/linuxfr

Si vous souhaitez vous connecter en ssh, c'est probablement le bon moment pour
ajouter votre clé ssh publique à `/data/prod/linuxfr/.ssh/authorized_keys` et
modifier `/etc/ssh/sshd_config` pour whitelister cet utilisateur.

Vous pouvez maintenant vous logger avec cet utilisateur et en profiter pour
installer vos fichiers _dotfiles_ (les miens sont sur
https://github.com/nono/dotfiles si ça vous intéresse).

N'oubliez pas de créer le fichier `ruby-env`, sourcé depuis le
`{bash|zsh}rc` :

    $ git clone git://github.com/nono/admin-linuxfr.org.git admin
    $ ln -s ~/admin/dotfiles/ruby-env .
    $ ln -s ~/admin/dotfiles/go-env .
    $ vim .bashrc   ## Ajouter "source ~/ruby-env ; source ~/go-env" au début
    $ source ruby-env
    $ source go-env

On retourne en root pour installer Redis :

    # echo 'deb http://deb.bearstech.com/squeeze redis/' >> /etc/apt/sources.list.d/40bearstech.list
    # aptitude update
    # aptitude install redis-server
    # ln -sf /data/prod/linuxfr/admin/conf/redis/redis.conf /etc/redis/
    # /etc/init.d/redis-server start

Un mysql, avec création de la base de données :

    # aptitude install mysql-server mysql-client libmysql++-dev
    # ln -sf /data/prod/linuxfr/admin/conf/mysql/conf.d/utf8.cnf /etc/mysql/conf.d/
    # ln -sf /data/prod/linuxfr/admin/conf/mysql/my.cnf /etc/mysql/
    # /etc/init.d/mysql restart
    # mysql -p -u root
    > CREATE DATABASE linuxfr_production;
    > CREATE USER linuxfr@localhost IDENTIFIED BY 'password';
    > GRANT ALL PRIVILEGES ON linuxfr_production.* TO linuxfr@localhost;
    (si /var est une partition avec peu de place, ne pas oublier de déplacer /var/lib/mysql ailleurs)

Ruby 1.9.3 (livré avec rubygems) :

    # echo 'deb http://deb.bearstech.com/squeeze ruby-1.9.3/' >> /etc/apt/sources.list.d/40bearstech.list
    # aptitude update
    # aptitude install ruby1.9.1 ruby1.9.1-dev

Puis, on continue avec notre utilisateur linuxfr
et on installe quelques gems qui vont bien :

    $ gem install bundler unicorn

Déployer l'application Rails à distance avec capistrano :

    (desktop) $ cap env:prod deploy:setup
    $ vim ~/production/shared/config/database.yml
    (desktop) $ cap env:prod deploy:check
    (desktop) $ cap env:prod deploy:update

Import des données existantes en provenance de templeet :

    $ w3m https://github.com/nono/migration-linuxfr.org

Installer la crontab :

    $ crontab -e
    0 1 * * *   source ruby-env && cd $RAILS_ENV/current && rake linuxfr:daily

Lancer le serveur applicatif (unicorn) :

    # ln -sf /data/prod/linuxfr/admin/init.d/unicorn /etc/init.d/
    # /etc/init.d/unicorn start
    # update-rc.d unicorn defaults 99

Mettre en place la conf nginx :

    # ln -sf /data/prod/linuxfr/admin/conf/nginx/nginx.conf /etc/nginx/
    # ln -sf /data/prod/linuxfr/admin/conf/nginx/mime.types /etc/nginx/
    # ln -s /data/prod/linuxfr/admin/conf/nginx/sites-available/linuxfr.org /etc/nginx/sites-available/
    # ln -s /etc/nginx/sites-available/linuxfr.org /etc/nginx/sites-enabled/

Recopier le certificat SSL dans `/etc/nginx` ou en générer un nouveau
en suivant les instructions de
http://wiki.nginx.org/NginxHttpSslModule#Generate\_Certificates

Puis relancer nginx :

    # /etc/init.d/nginx restart

On peut alors finit l'installation avec :

* webalizer
* [board-linuxfr](https://github.com/nono/board-sse-linuxfr.org)
* [share-linuxfr](https://github.com/nono/share-LinuxFr.org)
* [img-linuxfr](https://github.com/nono/img-LinuxFr.org)


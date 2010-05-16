Admin LinuxFr.org
=================

Ce dépôt git contient les fichiers qui servent à l'administration
du serveur LinuxFr.org -- pas les informations confidentielles ;)


Install on Debian Lenny
-----------------------

On commence par installer quelques paquets debian pour jouer :

    # aptitude install vim git-core zsh ack-grep curl openssl colordiff

Et de quoi compiler :

    # aptitude install build-essential autoconf libxml2-dev libreadline-dev
    # aptitude install libxslt1-dev aspell libaspell-dev aspell-fr zlib1g-dev

Si vous le souhaitez, vous pouvez en profiter pour mettre en place un Openssh :

    # aptitude install openssh-server
    # /etc/init.d/ssh start

Avec un ruby :

    # aptitude install ruby1.8 irb1.8 ruby1.8-dev libopenssl-ruby1.8

Un serveur web, nginx (en utilisant les backports) :

    # echo 'deb http://www.backports.org/debian lenny-backports main contrib non-free' > /etc/apt/sources.list.d/30lenny-backports.list
    # aptitude update
    # aptitude install debian-backports-keyring
    # aptitude -t lenny-backports install nginx

Un mysql, avec création de la base de données :

    # aptitude -t lenny-backports install mysql-server mysql-client libmysql++-dev
    # cp conf/mysql/conf.d/* /etc/mysql/conf.d/
    # /etc/init.d/mysql restart
    # mysql -p -u root
    > CREATE DATABASE linuxfr_production;
    > CREATE USER linuxfr@localhost IDENTIFIED BY 'password';
    > GRANT ALL PRIVILEGES ON linuxfr_production.* TO linuxfr@localhost;

On va maintenant se créer un compte utilisateur linuxfr :

    # adduser --home /data/web/linuxfr --gecos 'LinuxFr <linuxfr@linuxfr>' --disabled-password linuxfr
    # mkdir /www
    # ln -s /data/web/linuxfr /www/linuxfr.org

Si vous souhaitez vous connecter en ssh, c'est probablement le bon moment pour
ajouter votre clé ssh publique à `/var/www/linuxfr/.ssh/authorized_keys`.

Vous pouvez maintenant vous logger avec cet utilisateur et en profiter pour
installer vos fichiers _dotfiles_ (les miens sont sur
http://github.com/nono/dotfiles si ça vous intéresse).

N'oubliez pas de créer le fichier `ruby-env`, sourcé depuis le
`{bash|zsh}rc` :

    $ git clone git://github.com/nono/admin-linuxfr.org.git admin
    $ ln -s ~/admin/dotfiles/ruby-env .
    $ echo "source ~/ruby-env" >> .bashrc
    $ source ruby-env

On peut alors passer à l'installation de Rubygems :

    $ wget http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz
    $ tar xvzf rubygems-1.3.7.tgz
    $ cd rubygems-1.3.7 && ruby1.8 setup.rb --prefix=$HOME
    $ cd && ln -s gem1.8 bin/gem

Puis installer quelques gems qui vont bien :

    $ gem install rake rdoc bundler thin
    $ gem install rails rspec-rails compass haml devise will_paginate --pre

Déployer l'application Rails :

    $ git clone git://github.com/nono/linuxfr.org.git prod
    $ cd prod
    $ cp config/database.yml{.sample,}
    $ bundle install
    $ rake db:setup

Lancer le serveur applicatif (thin) :

    # cp /var/www/linuxfr/admin/init.d/thin /etc/init.d/
    # /etc/init.d/thin start
    # update-rc.d thin defaults 99

Mettre en place la conf nginx :

    # cp /var/www/linuxfr/admin/conf/nginx/nginx.conf /etc/nginx/
    # cp /var/www/linuxfr/admin/conf/nginx/sites-available/linuxfr.org /etc/nginx/sites-available/
    # ln -s /etc/nginx/sites-available/linuxfr.org /etc/nginx/sites-enabled/
    # ln -sf /var/www/linuxfr/admin/conf/nginx/nginx.conf /etc/nginx/

Recopier le certificat SSL dans `/etc/nginx` ou en générer un nouveau
en suivant les instructions de
http://wiki.nginx.org/NginxHttpSslModule#Generate\_Certificates

Puis relancer nginx :

    # /etc/init.d/nginx restart


TODO
----

 * Logrotate
 * Install crontab
 * Sphinx
 * Webalizer
 * S'occuper de mettre en place les redirections pour assurer la continuité avec la version templeet
 * Import des données existantes : http://github.com/nono/migration-linuxfr.org


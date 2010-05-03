Admin LinuxFr.org
=================

Ce dépôt git contient les fichiers qui servent à l'administration
du serveur LinuxFr.org -- pas les informations confidentielles ;)


Install on Debian Lenny
-----------------------

On commence par installer quelques paquets debian pour jouer :

    # aptitude install vim git-core zsh ack-grep curl openssl

Avec un ruby :

    # aptitude install ruby1.8 irb1.8 ruby1.8-dev

Un mysql, avec création de la base de données :

    # aptitude install mysql-server mysql-client libmysql++-dev
    # mysql -p -u root
	> CREATE DATABASE linuxfr_rails;
	> GRANT ALL PRIVILEGES ON linuxfr_rails.* TO linuxfr_rails@localhost;

Et de quoi compiler :

    # aptitude install build-essential autoconf libxml2-dev libreadline-dev
    # aptitude install libxslt1-dev aspell libaspell-dev aspell-fr

On va maintenant se créer un compte utilisateur linuxfr :

    # adduser --home /var/www/linuxfr --gecos 'LinuxFr <linuxfr@linuxfr>' --disabled-password linuxfr

Si vous souhaitez vous connecter en ssh, c'est probablement le bon moment pour
ajouter votre clé ssh publique à `/var/www/linuxfr/.ssh/authorized_keys`.

Vous pouvez maintenant vous logger avec cet utilisateur et en profiter pour
installer vos fichiers _dotfiles_ (les miens sont sur
http://github.com/nono/dotfiles si ça vous intéresse).

N'oubliez pas de créer le fichier `ruby-env`, sourcé depuis le
`{bash|zsh}rc` :

    $ git clone git://github.com/nono/admin-linuxfr.org.git admin
    $ ln -s ~/admin/dotfiles/ruby-env .
    $ echo "source ruby-env" >> .bashrc
    $ source ruby-env

On peut alors passer à l'installation de Rubygems :

    $ wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
    $ tar xvzf rubygems-1.3.6.tgz
    $ cd rubygems-1.3.6 && ruby1.8 setup.rb --prefix=$HOME
    $ cd && ln -s bin/gem1.8 bin/gem

Puis installer quelques gems qui vont bien :

    $ gem install rake rdoc bundler
	$ gem install rails rspec-rails compass haml devise will_paginate --pre -y

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


TODO
----

 * Nginx + logrotate
 * [Chat](http://github.com/nono/chat-linuxfr.org)
 * S'occuper de mettre en place les redirections pour assurer la continuité avec la version templeet


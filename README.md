Admin LinuxFr.org
=================

Ce dépôt git contient les fichiers qui servent à l'administration
du serveur LinuxFr.org -- pas les informations confidentielles ;)


Install on Debian Lenny
-----------------------

On commence par installer quelques paquets debian pour jouer :

    # aptitude install vim git-core zsh ack-grep curl openssl

Avec un ruby :

    # aptitude install ruby1.8

Et de quoi compiler :

    # aptitude install build-essential autoconf libxml2-dev libreadline-dev

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
    $ echo "source ruby-env" >> .zshrc
    $ source ruby-env

On peut alors passer à l'installation de Rubygems :




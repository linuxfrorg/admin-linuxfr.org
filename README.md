Admin LinuxFr.org
=================

Ce dépôt git contient les fichiers qui servent à l'administration du serveur LinuxFr.org -- pas les informations confidentielles ;)


Vagrant
-------

Pour le développement en local, il est plus aisé de passer par une machine virtuelle.
Nous utilisons [Vagrant](http://vagrantup.com/) pour construire une VM pour Virtual Box.

Voici les instructions pour recréer la VM à partir de ce dépôt :
    aptitude install virtualbox-ose rubygems expect git-core
	git clone git://github.com/nono/linuxfr.org.git www
    gem install vagrant
    vagrant add debian_lenny http://files.vagrantup.com/contrib/debian_lenny.box
	vagrant up
	(attendre pendant que la magie opère)_

*Note* : le fichier `Vagrantfile` existe déjà, ce n'est donc pas la peine de faire un `vagrant init`.

Nous avons maintenant une machine virtuelle qui tourne avec un environement fonctionnel.
En particulier, vous pouvez afficher le site en tappant `http://localhost:8080` dans la barre d'adresse de votre navigateur.
Vous pouvez également vous connecter en ssh sur la machine virtuelle avec `vagrant ssh`, ce qui peut être pratique pour débugger.


Chef
----

Nous utilisons [Chef](http://www.opscode.com/chef) comme outil de déploiement automatique.
En pratique, nous nous servons de `chef-solo`, car nous n'avons jamais à gérer plus d'une instance à la fois.

**Description et source des recipes :**
* debug : tout ce qu'il faut pour débugger (ltrace, strace, vim, etc.)
* nginx : le serveur web - http://github.com/opscode/cookbooks
* vagrant\_main : la recipe utilisée par vagrant pour (re)créer l'environnement


TODO
----

* S'occuper de mettre en place les redirections pour assurer la continuité avec la version templeet
* Indiquer quelle est la procédure pour juste mettre à jour la VM


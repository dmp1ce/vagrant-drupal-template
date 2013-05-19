Drupal Vagrant Template
=======================

This project is designed to be a starting point for creating Drupal test environments.  It uses git submodules to load the Drupal source.  Users of this template are encouraged to add more submodules to the `modules` directory to fit the work you are doing.  For example, you might want to add the `devel` module to the `modules` folder and then add it as a git submodule.

The database and settings file have already been created on the server.  This should allow you to simple `vagrant up` and begin using the environment.  Take not to the requirements below if things do not work.

Requirements
------------

- NFS server available on your host machine.  This allows Drupal to load faster because Drupal can use many files which is slow without NFS.
- You must change your `/etc/hosts` file to match the virtual server set in Apache.  By default this is `10.1.1.100	drupal-vagrant.local`.  The IP can be changed in the `Vagrantfile` file and the hostname can be changed in the `files/drupal` file.

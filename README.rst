conf-mgmt-like-a-sir
====================

Set of Ansible tasks to configure Gentoo-based workstations.

Intentionally none of the roles will install packages, and fail, if the binaries are not out there.

Usage
-----
To apply example host, set hostname to ``example`` and run::

    ./apply -t bootstrap

Then which will apply minimal configuration (/etc/portage), then merge your packages and follow it up by::

    ./apply 

When (re)starting or reloading services is not desired, like, when running inside chroot, one can set ``skip_handlers`` variable to any value to skip them, for example::

    ./apply -e skip_handlers=1

that will apply all of the configuration

Secrets
=======

Secrets handling via separated repository is supported by the ``apply``` script. Check it's header comments for more information.

Roles
=====

Too many of them, check ``roles/`` directory and ``example.yml`` playbook.

ansible-like-a-sir
==================

Set of Ansible tasks to configure Gentoo-based workstations.

Intentionally none of the roles will install packages, and fail, if the binaries are not out there.

Usage
-----
To apply *defaults* one can run ``default.yml`` script.
::

    python2 $(command -v virtualenv) venv
    . venv/bin/activate
    pip install -r requirements.txt
    ./default.yml

Roles
=====

connman
-------

- Disables DNS proxy. I prefer to use dnsmasq.
- Disables NTP client. I prefer to use chrony.
- Disables hostname changes via DHCP.
- Disables timezone updates. It uses DBus, nothing listen here for the timezone changes. ¯\\_(ツ)_/¯
- Allow wheel group to use ``connmanctl`` and in general talk with connman via DBus.
- ensure ``/var/run/connman`` exists, opentmpfiles creates it, but unless triggered (like, reboot) it won't.

dnsmasq
-------

- Get ``dnsmasq.conf`` that either uses connman's ``/var/run/connman/resolv.conf``, directly Google DNS servers or OpenDNS, depending on ``upstream`` set to either ``connman``, ``google``, or ``opendns``.

resolve_dns_via_localhost
-------------------------

- Set ``/etc/resolv.conf`` to ``nameserver 127.0.0.1`` and apply immutable bit on the file.

sshd
----

- Allow root login with key-only auth.
- Disable password login all together, when ``no_password_login`` set to ``True``.

system_groups
-------------

- ``view_proc`` gid ``50001``
- ``with_symlinksifownermatch`` gid ``50002``
- ``with_audit`` gid ``50003``
- ``without_tpe`` gid ``50004``
- ``deny_client_socket`` gid ``50006``
- ``deny_server_socket`` gid ``50006``

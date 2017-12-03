ansible-like-a-sir
==================

Set of Ansible tasks to configure Gentoo-based workstations.

Intentionally none of the roles will install packages, and fail, if the binaries are not out there.

Usage
-----
::

    python2 $(command -v virtualenv) venv
    . venv/bin/activate
    pip install -r requirements.txt
    ./default.yml

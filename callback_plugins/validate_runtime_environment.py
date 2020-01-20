from __future__ import absolute_import, division, print_function, unicode_literals

import os
import sys

import ansible

try:
    from pip_lock import check_requirements
    HAVE_PIP_LOCK = True
except ImportError:
    HAVE_PIP_LOCK = False

try:
    # Version 2.0+
    from ansible.plugins.callback import CallbackBase
except ImportError:
    CallbackBase = object


class CallbackModule(CallbackBase):
    def __init__(self):
        if not ( 
            sys.version_info[:2] == (2, 7) or
            sys.version_info[:2] == (3, 5) or
            sys.version_info[:2] == (3, 6) or
            sys.version_info[:2] == (3, 7) or
            sys.version_info[:2] == (3, 8)
        ):
            print('Your runtime Python environment is not supported. Check README.rst for more information how to set it up', file=sys.stderr)
            sys.exit(1)

        if not HAVE_PIP_LOCK:
            print('The pip-lock is not installed, unable to validate environment. Check README.rst for more information', file=sys.stderr)
            sys.exit(1)

        check_requirements(
            os.path.abspath(os.path.join(module_dir, '../', 'requirements.txt')),
            post_text='\nRun the following on your machine: \n\n\tpip install -r requirements.txt\n'
        )


module_dir = os.path.dirname(__file__)

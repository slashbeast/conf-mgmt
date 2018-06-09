#!/usr/bin/env python

from __future__ import absolute_import, division, print_function, unicode_literals
import json
import os


def get_ansible_root_directory():
    inventory_directory = os.path.dirname(os.path.realpath(__file__))
    ansible_root = os.path.realpath(os.path.join(inventory_directory, '..'))

    return ansible_root


def main():
    ansible_root = get_ansible_root_directory()

    inventory = {
        'hosts': [
            'localhost'
        ],
        '_meta': {
            'hostvars': {
                'localhost': {
                    'ansible_python_interpreter': '/usr/bin/env python'
                }
            }
        }
    }

    global_vars = inventory.setdefault('all', {}).setdefault('vars', {})

    global_vars['ansible_root'] = ansible_root
    global_vars['common'] = os.path.join(ansible_root, 'common')

    print(json.dumps(inventory, sort_keys=True, indent=2))


if __name__ == '__main__':
    main()

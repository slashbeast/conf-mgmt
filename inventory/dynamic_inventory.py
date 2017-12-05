#!/usr/bin/env python

# Not *that* needed now, but may be very handy in the future, to gather 'better' facts.

import json


def main():
    inventory = {}

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
    print(json.dumps(inventory, sort_keys=True, indent=2))


if __name__ == '__main__':
    main()


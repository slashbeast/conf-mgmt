import gnupg


gpg = gnupg.GPG()


def gpg_decrypt(string):
    return gpg.decrypt(string).data.decode('utf-8')


class FilterModule(object):
    def filters(self):
        return {
            'gpg_decrypt': gpg_decrypt
        }

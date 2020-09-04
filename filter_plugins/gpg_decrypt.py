from functools import lru_cache


@lru_cache
def get_gpg():
    import gnupg
    return gnupg.GPG()


def gpg_decrypt(string):
    gpg = get_gpg()
    return gpg.decrypt(str(string).encode('utf-8')).data.decode('utf-8')


class FilterModule(object):
    def filters(self):
        return {
            'gpg_decrypt': gpg_decrypt
        }

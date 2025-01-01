#!/usr/bin/env python3

import ipaddress

def extra_filters():
    """ Declare some custom filters.

        Returns: dict(name = function)
    """
    return dict(
        in_addr_arpa=lambda ip: '.'.join(list(reversed(ipaddress.IPv4Address(ip).compressed.split('.')))[:-1]),
    )

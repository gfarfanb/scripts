#!/usr/bin/env python

from os import environ

import sys
import argparse
import json
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

logger = logging.getLogger()


# http://fileformats.archiveteam.org/wiki/Netscape_cookies.txt
def format_cookies(json_cookies, netscape_cookies):
    with open(json_cookies, 'r') as f:
        payload = json.load(f)

    lines = ['# Netscape HTTP Cookie File']

    for cookie in payload:
        domain = cookie.get('domain', '')
        flag = 'TRUE' if cookie.get('subdomains', 'false').lower() == 'true' else 'FALSE'
        path = cookie.get('path', '/')
        secure = 'TRUE' if cookie.get('secure', 'false').lower() == 'true' else 'FALSE'
        expiry = str(int(cookie.get('expiry', 0) // 1000)) # Convert to seconds
        name = cookie.get('name', '')
        value = cookie.get('value', '')

        line = '\t'.join([domain, flag, path, secure, expiry, name, value])
        lines.append(line)

    with open(netscape_cookies, 'w') as f:
        f.write('\n'.join(lines))


def main():
    try:
        logging.basicConfig(
            format='%(asctime)s %(levelname)s - %(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-j', '--json',
                            help='Cookies file in JSON format')
        parser.add_argument('-n', '--netscape',
                            help='Ouput file for Netscape cookies')
        args = parser.parse_args()

        format_cookies(args.json, args.netscape)
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

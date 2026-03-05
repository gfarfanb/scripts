
from os import environ
import subprocess

import logging
import sys


def prop_value(name):
    if sys.platform == 'win32':
        command = "{dir}\\props".format(dir=environ['ENVVARSPATH'])
        value = subprocess.run(['props', name], capture_output=True, shell=True, text=True)
    else:
        command = "{dir}/props".format(dir=environ['ENVVARSPATH'])
        value = subprocess.run(['sh', command, name], capture_output=True, text=True)

    return value.stdout.rstrip()


def env_value(name, default_value=None, only_envs=False):
    try:
        return environ[name]
    except KeyError:
        if only_envs:
            return get_default_or_fail(name, default_value)
        else:
            value = prop_value(name)
            return value if value else get_default_or_fail(name, default_value)


def get_default_or_fail(name, default_value):
    if default_value:
        return default_value
    else:
        raise ValueError("Undefined environment variable: {name}".format(name=name))


def logging_level() -> int:
    return logging.getLevelNamesMapping()[
        env_value(
            name="LOGGING_LEVEL",
            default_value="INFO",
            only_envs=True)
    ]

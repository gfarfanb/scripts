
from os import environ
import subprocess

import logging
import sys
import re


def prop_value(name):
    if sys.platform == 'win32':
        command = "{dir}\\sys\\props".format(dir=environ['SCRIPTS_HOME'])
        value = subprocess.run([command, name], capture_output=True, text=True, shell=True)
    else:
        command = "{dir}/sys/props".format(dir=environ['SCRIPTS_HOME'])
        value = subprocess.run(['bash', command, name], capture_output=True, text=True)

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


def logging_level(default_level='INFO') -> int:
    return logging.getLevelNamesMapping()[
        env_value(
            name='LOGGING_LEVEL',
            default_value=default_level,
            only_envs=True)
    ]


def replace_all_envs(value, values: dict = {}):
    env_vars = re.findall(r'\{env:([^}]+)\}', value)
    env_values = {}
    for env_var in env_vars:
        env_values[env_var] = env_value(env_var)
    if values:
        env_values.update(values)
    return value.replace('env:', '').format(**env_values)

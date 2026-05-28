#!/usr/bin/env python3

from os import environ

import sys
import sqlite3
import argparse
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

sys_control_db = env_vars.env_value('SYS_CONTROL_DB_FILE')

logger = logging.getLogger()

commands_query = """
    SELECT c.command,
            c.approval,
            c.approval_msg,
            c.reject_cmd
        FROM commands c
            JOIN machines m ON c.machine_id = m.id
            JOIN operating_systems o ON m.os_id = o.id
        WHERE m.name = '{machine}'
            AND o.name = '{os}'
            AND c.mode = '{mode}'
            AND c.deleted = 0
        ORDER BY ordinal
"""

class Command:
    def __init__(self, command, approval, approval_msg, reject_cmd):
        self.command = command
        self.approval = approval
        self.approval_msg = approval_msg,
        self.reject_cmd = reject_cmd


def __get_commands(mode, machine_name, os_name):
    query = commands_query.format(machine=machine_name,
                                  os=os_name,
                                  mode=mode) 
    conn = sqlite3.connect(sys_control_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    commands = []
    for row in rows:
        command, approval, approval_msg, reject_cmd = row

        commands.append(Command(command, bool(approval), approval_msg, reject_cmd))

    return commands


def generate_bash(machine_name, os_name, tmp_file):
    with open(tmp_file, "a") as file:
        file.write('#! /usr/bin/env bash\n')

        commands = __get_commands(mode='EXECUTION',
                                  machine_name=machine_name,
                                  os_name=os_name)

        for command in commands:
            if command.approval:
                command_entry = """
                    echo >&2
                    _update_flag=""
                    read -p "{confirm} [y/n] > " _update_flag
                    case $_update_flag in
                        [Yy])
                            echo "Executing: [{cmd}]" >&2
                            {cmd}
                            ;;
                        *)
                            {reject}
                            ;;
                    esac
                """.format(confirm=command.approval_msg,
                           cmd=command.command,
                           reject=command.reject_cmd)
            else:
                command_entry = """
                    echo >&2
                    echo "Executing: [{cmd}]" >&2
                    {cmd}
                """.format(cmd=command.command)

            file.write(command_entry)

        commands = __get_commands(mode='READONLY',
                                  machine_name=machine_name,
                                  os_name=os_name)

        if commands:
            file.write('echo >&2\n')
            file.write('echo "Execute these commands if needed:" >&2\n')

            for command in commands:
                file.write('echo >&2\n')
                file.write("echo \"> {cmd}\" >&2\n".format(cmd=command.command))


def generate_batch(machine_name, os_name, tmp_file):
    with open(tmp_file, "a") as file:
        file.write('@echo OFF\n')

        commands = __get_commands(mode='EXECUTION',
                                  machine_name=machine_name,
                                  os_name=os_name)

        for command in commands:
            print(command.command)
            if command.approval:
                command_entry = """
                    echo:
                    set "_update_flag="
                    set /P _update_flag="{confirm} [y/n] > "
                    if "%_update_flag%"=="Y" set _approval=1
                    if "%_update_flag%"=="y" set _approval=1
                    if "%_approval%"=="1" (
                        echo Executing: [{cmd}]
                        call %SCRIPTS_HOME%\.win\eval {cmd}
                    ) else (
                        call %SCRIPTS_HOME%\.win\eval {reject}
                    )
                """.format(confirm=command.approval_msg,
                           cmd=command.command,
                           reject=command.reject_cmd)
            else:
                command_entry = """
                    echo:
                    echo Executing: [{cmd}]
                    call %SCRIPTS_HOME%\.win\eval {cmd}
                """.format(cmd=command.command)

            file.write(command_entry)

        commands = __get_commands(mode='READONLY',
                                  machine_name=machine_name,
                                  os_name=os_name)

        if commands:
            file.write('echo:\n')
            file.write('echo Execute these commands if needed:\n')

            for command in commands:
                file.write('echo:\n')
                file.write("echo > {cmd}\n".format(cmd=command.command))


def main():
    try:
        logging.basicConfig(
            format='%(asctime)s %(levelname)s - %(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-s', '--script',
                            choices=[ 'bash', 'batch' ],
                            help='Script type for the output file')
        parser.add_argument('-m', '--machine',
                            help='Machine name to get commands related')
        parser.add_argument('-o', '--os',
                            help='OS name to get commands related')
        parser.add_argument('-f', '--file',
                           help='Path for the outputfile')
        args = parser.parse_args()

        match args.script:
            case 'bash':
                generate_bash(machine_name=args.machine,
                              os_name=args.os,
                              tmp_file=args.file)
            case 'batch':
                generate_batch(machine_name=args.machine,
                               os_name=args.os,
                               tmp_file=args.file)
            case _:
                raise ValueError("Invalid script type: {type}".format(type=args.script))
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

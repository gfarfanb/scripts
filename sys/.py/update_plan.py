#!/usr/bin/env python3

from os import environ, linesep
from os.path import join

import sys
import sqlite3
import uuid
import argparse
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

sys_control_db = env_vars.env_value('SYS_CONTROL_DB_FILE')
scripts_temp_dir = env_vars.env_value('SCRIPTS_TEMP_DIR')
max_cmd_print_length = 60

logger = logging.getLogger()

commands_query = """
    SELECT c.mode,
            c.command,
            c.approval,
            c.approval_msg,
            c.reject_cmd
        FROM commands c
            JOIN machines m ON c.machine_id = m.id
            JOIN operating_systems o ON m.os_id = o.id
        WHERE m.name = '{machine}'
            AND o.name = '{os}'
            AND c.deleted = 0
        ORDER BY ordinal
"""


class Command:

    def __init__(self, mode, cmd, cmd_print, require_approval, approval, approval_msg, reject_cmd):
        self.mode = mode
        self.cmd = cmd
        self.cmd_print = cmd_print
        self.require_approval = require_approval
        self.approval = approval
        self.approval_msg = approval_msg
        self.reject_cmd = reject_cmd

    def __str__(self):
        return (f"{self.__class__.__name__}("
            f"mode={self.mode!r}, "
            f"cmd={self.cmd!r}, "
            f"cmd_print={self.cmd_print!r}, "
            f"require_approval={self.require_approval!r}, "
            f"approval={self.approval!r}, "
            f"approval_msg={self.approval_msg!r}, "
            f"reject_cmd={self.reject_cmd!r})")


def __get_commands(machine_name, os_name, select_mode, accept_cmds):
    query = commands_query.format(machine=machine_name,
                                  os=os_name) 
    conn = sqlite3.connect(sys_control_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    commands = []
    for row in rows:
        mode, cmd, approval, approval_msg, reject_cmd = row

        require_approval = False if accept_cmds else bool(approval)
        cmd_print = __printable_cmd(cmd)

        command = Command(mode, cmd, cmd_print, require_approval, approval, approval_msg, reject_cmd)

        if not command.cmd or not command.cmd.strip():
            logger.warning("Empty command line in: {cmd}".format(cmd=command))
            continue

        logger.debug("Command added to plan: {cmd}".format(cmd=command))

        commands.append(command)

    match select_mode:
        case 'start-from':
            cmd_idx = __select_command_index(commands, 'Select command to start plan:')
            return commands[cmd_idx:]
        case 'only-one':
            cmd_idx = __select_command_index(commands, 'Select command to execute:')
            return [ commands[cmd_idx] ]
        case _:
            return commands


def __printable_cmd(cmd):
    if not cmd:
        return None

    cmd = cmd.splitlines()[0].replace('"', '').replace('\'', '')
    return cmd[:max_cmd_print_length] + '...' if len(cmd) > max_cmd_print_length else cmd


def __select_command_index(commands, select_message):
    logger.info(select_message)

    i = 1
    for command in commands:
        logger.info("{i}) [{mode}] {print}".format(i=i,
                                                 mode=command.mode,
                                                 print=command.cmd_print))
        i+=1

    logger.info('command-index> ')
    try:
        cmd_idx = int(input())
    except ValueError:
        raise ValueError('Invalid command index')

    if cmd_idx < 0 or cmd_idx >= i:
        raise ValueError('Invalid command index')

    return cmd_idx - 1


def generate_bash(commands, tmp_file):
    logger.debug("Generating 'bash' file: {file}".format(file=tmp_file))

    with open(tmp_file, "a") as file:
        file.write(__get_bash_shebang())
        file.write(linesep)

        execution_cmds = filter(lambda cmd: cmd.mode == 'EXECUTION', commands)
        cmd_files = []

        for command in execution_cmds:
            if command.require_approval:
                if not command.approval_msg or not command.approval_msg.strip():
                    confirm = "Confirm? [{print}]".format(print=command.cmd_print)
                else:
                    confirm = command.approval_msg
                
                if not command.reject_cmd or not command.reject_cmd.strip():
                    declined = 'echo Declined'
                else:
                    reject_bash = __create_bash_command(command.reject_cmd)
                    cmd_files.append(reject_bash)
                    declined = """
                        echo >&2
                        echo "Executing: [<decline_command>]" >&2
                        . {bash}
                    """.format(bash=reject_bash)

                command_bash = __create_bash_command(command.cmd)
                cmd_files.append(command_bash)
                command_entry = """
                    echo >&2
                    _update_flag=""
                    read -p "{confirm} [y/n] > " _update_flag
                    case $_update_flag in
                        [Yy])
                            echo >&2
                            echo "Executing: [{print}]" >&2
                            . {bash}
                            ;;
                        *)
                            {declined}
                            ;;
                    esac
                """.format(confirm=confirm,
                           print=command.cmd_print,
                           bash=command_bash,
                           declined=declined)
            else:
                command_bash = __create_bash_command(command.cmd)
                cmd_files.append(command_bash)
                command_entry = """
                    echo >&2
                    echo "Executing: [{print}]" >&2
                    . {bash}
                """.format(print=command.cmd_print,
                           bash=command_bash)

            file.write(command_entry)

        for cmd_file in cmd_files:
            file.write('''
                rm "{bash}"
            '''.format(bash=cmd_file))
            file.write(linesep)

        readonly_cmds = list(filter(lambda cmd: cmd.mode == 'READONLY', commands))

        if readonly_cmds:
            file.write('echo >&2')
            file.write(linesep)
            file.write('echo "Execute these commands if needed:" >&2')
            file.write(linesep)

            for command in readonly_cmds:
                file.write('echo >&2')
                file.write(linesep)
                file.write("echo \"> {cmd}\" >&2".format(cmd=command.cmd))
                file.write(linesep)


def generate_batch(commands, tmp_file):
    logger.debug("Generating 'batch' file: {file}".format(file=tmp_file))

    with open(tmp_file, "a") as file:
        file.write(__get_batch_shebang())
        file.write(linesep)

        execution_cmds = filter(lambda cmd: cmd.mode == 'EXECUTION', commands)
        cmd_files = []

        for command in execution_cmds:
            if command.require_approval:
                if not command.approval_msg or not command.approval_msg.strip():
                    confirm = "Confirm? [{print}]".format(print=command.cmd_print)
                else:
                    confirm = command.approval_msg

                if not command.reject_cmd or not command.reject_cmd.strip():
                    declined = 'echo Declined'
                else:
                    reject_bat = __create_batch_command(command.reject_cmd)
                    cmd_files.append(reject_bat)
                    declined = """
                        echo:
                        echo Executing: [^<decline_command^>]
                        call {bat}
                    """.format(cmd=command.reject_cmd,
                               bat=reject_bat)

                command_bat = __create_batch_command(command.cmd)
                cmd_files.append(command_bat)
                command_entry = """
                    echo:
                    set "_update_flag="
                    set "_approval="
                    set /P _update_flag="{confirm} [y/n] > "
                    if "%_update_flag%"=="Y" set _approval=1
                    if "%_update_flag%"=="y" set _approval=1
                    if "%_approval%"=="1" (
                        echo:
                        echo Executing: [{print}]
                        call {bat}

                    ) else (
                        {declined}
                    )
                """.format(confirm=confirm,
                           print=command.cmd_print,
                           bat=command_bat,
                           declined=declined)
            else:
                command_bat = __create_batch_command(command.cmd)
                cmd_files.append(command_bat)
                command_entry = """
                    echo:
                    echo Executing: [{print}]
                    call {bat}
                """.format(print=command.cmd_print,
                           bat=command_bat)

            file.write(command_entry)

        for cmd_file in cmd_files:
            file.write('''
                if exist "{bat}" del "{bat}"
            '''.format(bat=cmd_file))
            file.write(linesep)

        readonly_cmds = list(filter(lambda cmd: cmd.mode == 'READONLY', commands))

        if readonly_cmds:
            file.write('echo:')
            file.write(linesep)
            file.write('echo Execute these commands if needed:')
            file.write(linesep)

            for command in readonly_cmds:
                file.write('echo:')
                file.write(linesep)
                file.write("echo ^> {cmd}".format(cmd=command.cmd))
                file.write(linesep)


def __get_bash_shebang():
    return '#! /usr/bin/env bash'


def __create_bash_command(content):
    bash_path = join(scripts_temp_dir, "cmd-bash.{uuid}".format(uuid=uuid.uuid4()))

    with open(bash_path, 'w') as file:
        file.write(__get_bash_shebang())
        file.write(linesep)
        file.write(content)

    return bash_path


def __get_batch_shebang():
    return '@echo OFF'


def __create_batch_command(content):
    batch_path = join(scripts_temp_dir, "cmd-batch.{uuid}.bat".format(uuid=uuid.uuid4()))

    with open(batch_path, 'w') as file:
        file.write(__get_batch_shebang())
        file.write(linesep)
        file.write(content)

    return batch_path


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-a', '--accept', action='store_true',
                            help='Accept all commands that require approval')
        parser.add_argument('-t', '--type',
                            choices=[ 'bash', 'batch' ],
                            help='Script type for the output file')
        parser.add_argument('-f', '--file',
                           help='Path for the output file')
        parser.add_argument('-n', '--name',
                            help='Machine name to get commands related')
        parser.add_argument('-o', '--os',
                            help='OS name to get commands related')
        parser.add_argument('-m', '--mode', default='all',
                            choices=[ 'start-from', 'only-one', 'all' ],
                            help='Execute plan in a specific mode')
        args = parser.parse_args()

        commands = __get_commands(machine_name=args.name,
                                  os_name=args.os,
                                  select_mode=args.mode,
                                  accept_cmds=args.accept)

        match args.type:
            case 'bash':
                generate_bash(commands=commands,
                              tmp_file=args.file)
            case 'batch':
                generate_batch(commands=commands,
                               tmp_file=args.file)
            case _:
                raise ValueError("Invalid script type: {type}".format(type=args.type))
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

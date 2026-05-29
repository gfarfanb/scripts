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
    def __init__(self, mode, cmd_line, approval, approval_msg, reject_cmd):
        self.mode = mode
        self.cmd_line = cmd_line
        self.approval = approval
        self.approval_msg = approval_msg
        self.reject_cmd = reject_cmd

    def __str__(self):
        return (f"{self.__class__.__name__}("
            f"mode={self.mode!r}, "
            f"cmd_line={self.cmd_line!r}, "
            f"approval={self.approval!r}, "
            f"approval_msg={self.approval_msg!r}, "
            f"reject_cmd={self.reject_cmd!r})")


def __get_commands(machine_name, os_name, select_mode):
    query = commands_query.format(machine=machine_name,
                                  os=os_name) 
    conn = sqlite3.connect(sys_control_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    commands = []
    for row in rows:
        mode, cmd_line, approval, approval_msg, reject_cmd = row
        command = Command(mode, cmd_line, bool(approval), approval_msg, reject_cmd)

        if not command.cmd_line or not command.cmd_line.strip():
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


def __select_command_index(commands, select_message):
    logger.info(select_message)

    i = 1
    for command in commands:
        cmd_line = command.cmd_line[:80] + '...' if len(command.cmd_line) > 80 else command.cmd_line
        logger.info("{i}) [{mode}] {cmd}".format(i=i,
                                                 mode=command.mode,
                                                 cmd=cmd_line))
        i+=1

    logger.info('command-index> ')
    try:
        cmd_idx = int(input())
    except ValueError:
        raise ValueError('Invalid command index')

    if cmd_idx < 0 or cmd_idx >= i:
        raise ValueError('Invalid command index')

    return cmd_idx - 1


def generate_bash(machine_name, os_name, tmp_file, select_mode):
    logger.debug("Generating 'bash' file: {file}".format(file=tmp_file))

    with open(tmp_file, "a") as file:
        file.write('#! /usr/bin/env bash\n')

        commands = __get_commands(machine_name=machine_name,
                                  os_name=os_name,
                                  select_mode=select_mode)
        execution_cmds = filter(lambda cmd: cmd.mode == 'EXECUTION', commands)

        for command in execution_cmds:
            if command.approval:
                if not command.approval_msg or not command.approval_msg.strip():
                    confirm = "Confirm? [{cmd}]".format(cmd=command.cmd_line)
                else:
                    confirm = command.approval_msg
                
                if not command.reject_cmd or not command.reject_cmd.strip():
                    declined = 'echo Declined'
                else:
                    declined = """
                        echo >&2
                        echo "Executing decline command" >&2
                        {cmd}
                    """.format(cmd=command.reject_cmd)

                command_entry = """
                    echo >&2
                    _update_flag=""
                    read -p "{confirm} [y/n] > " _update_flag
                    case $_update_flag in
                        [Yy])
                            echo >&2
                            echo "Executing: [{cmd}]" >&2
                            {cmd}
                            ;;
                        *)
                            {declined}
                            ;;
                    esac
                """.format(confirm=confirm,
                           cmd=command.cmd_line,
                           declined=declined)
            else:
                command_entry = """
                    echo >&2
                    echo "Executing: [{cmd}]" >&2
                    {cmd}
                """.format(cmd=command.cmd_line)

            file.write(command_entry)

        readonly_cmds = filter(lambda cmd: cmd.mode == 'READONLY', commands)

        if readonly_cmds:
            file.write('echo >&2\n')
            file.write('echo "Execute these commands if needed:" >&2\n')

            for command in readonly_cmds:
                file.write('echo >&2\n')
                file.write("echo \"> {cmd}\" >&2\n".format(cmd=command.cmd_line))


def generate_batch(machine_name, os_name, tmp_file, select_mode):
    logger.debug("Generating 'batch' file: {file}".format(file=tmp_file))

    with open(tmp_file, "a") as file:
        file.write('@echo OFF\n')

        commands = __get_commands(machine_name=machine_name,
                                  os_name=os_name,
                                  select_mode=select_mode)
        execution_cmds = filter(lambda cmd: cmd.mode == 'EXECUTION', commands)

        for command in execution_cmds:
            if command.approval:
                if not command.approval_msg or not command.approval_msg.strip():
                    confirm = "Confirm? [{cmd}]".format(cmd=command.cmd_line)
                else:
                    confirm = command.approval_msg

                if not command.reject_cmd or not command.reject_cmd.strip():
                    declined = 'echo Declined'
                else:
                    declined = """
                        echo:
                        echo Executing decline command
                        call %SCRIPTS_HOME%\\.win\\eval {cmd}
                    """.format(cmd=command.reject_cmd)

                command_entry = """
                    echo:
                    set "_update_flag="
                    set "_approval="
                    set /P _update_flag="{confirm} [y/n] > "
                    if "%_update_flag%"=="Y" set _approval=1
                    if "%_update_flag%"=="y" set _approval=1
                    if "%_approval%"=="1" (
                        echo:
                        echo Executing: [{cmd}]
                        call %SCRIPTS_HOME%\\.win\\eval {cmd}
                    ) else (
                        {declined}
                    )
                """.format(confirm=confirm,
                           cmd=command.cmd_line,
                           declined=declined)
            else:
                command_entry = """
                    echo:
                    echo Executing: [{cmd}]
                    call %SCRIPTS_HOME%\\.win\\eval {cmd}
                """.format(cmd=command.cmd_line)

            file.write(command_entry)

        readonly_cmds = filter(lambda cmd: cmd.mode == 'READONLY', commands)

        if readonly_cmds:
            file.write('echo:\n')
            file.write('echo Execute these commands if needed:\n')

            for command in readonly_cmds:
                file.write('echo:\n')
                file.write("echo ^> {cmd}\n".format(cmd=command.cmd_line))


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
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

        match args.type:
            case 'bash':
                generate_bash(machine_name=args.name,
                              os_name=args.os,
                              tmp_file=args.file,
                              select_mode=args.mode)
            case 'batch':
                generate_batch(machine_name=args.name,
                               os_name=args.os,
                               tmp_file=args.file,
                               select_mode=args.mode)
            case _:
                raise ValueError("Invalid script type: {type}".format(type=args.type))
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

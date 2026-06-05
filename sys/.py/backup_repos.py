#!/usr/bin/env python3

from os import environ, makedirs, rmdir, rename, remove
from os.path import islink, join, exists

from urllib.error import HTTPError
from git.exc import GitCommandError

import sys
import sqlite3
import argparse
import git
import wget
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

sys_control_db = env_vars.env_value('SYS_CONTROL_DB_FILE')

logger = logging.getLogger()

repo_hubs = {}

repos_query = """
    SELECT r.hub_id,
        r.repo_name,
        r.branch,
        r.username,
        r.pull_required,
        r.pull_dir,
        r.backup_required,
        r.backup_dir
    FROM repos r
        JOIN machines m ON r.machine_id = m.id
        JOIN operating_systems o ON m.os_id = o.id
    WHERE m.name = '{machine}'
        AND o.name = '{os}'
        AND r.deleted = 0
"""

hubs_query = """
    SELECT h.id,
        h.clone_template,
        h.backup_template
    FROM repo_hubs h
    WHERE id IN ({hub_ids})
"""


class Repo:

    def __init__(self, hub_id, repo_name, branch, username, pull_required, pull_dir, backup_required, backup_dir):
        self.hub_id = hub_id
        self.repo_name = repo_name
        self.branch = branch
        self.username = username
        self.pull_required = pull_required
        self.pull_dir = pull_dir
        self.backup_required = backup_required
        self.backup_dir = backup_dir

    def __str__(self):
        return (f"{self.__class__.__name__}("
            f"hub_id={self.hub_id!r}, "
            f"repo_name={self.repo_name!r}, "
            f"branch={self.branch!r}, "
            f"username={self.username!r}, "
            f"pull_required={self.pull_required!r}, "
            f"pull_dir={self.pull_dir!r}, "
            f"backup_required={self.backup_required!r}, "
            f"backup_dir={self.backup_dir!r})")


class Hub:

    def __init__(self, hub_id, clone_template, backup_template):
        self.hub_id = hub_id
        self.clone_template = clone_template
        self.backup_template = backup_template

    def __str__(self):
        return (f"{self.__class__.__name__}("
            f"hub_id={self.hub_id!r}, "
            f"clone_template={self.clone_template!r}, "
            f"backup_template={self.backup_template!r})")


def pull_repos(machine_name, os_name, select=False):
    repo_defs = __get_repo_defs(machine_name=machine_name,
                                os_name=os_name)

    discarded_repos = []

    if select:
        selected_repo = __select_repo(repo_defs, 'Choose a repo to pull:')

        if selected_repo and not selected_repo.pull_required:
            discarded_repos.append(selected_repo)
        else:
            __pull_repo(selected_repo)
    else:
        for repo_def in repo_defs:
            if repo_def and not repo_def.pull_required:
                discarded_repos.append(repo_def)
            else:
                __pull_repo(repo_def)

    if discarded_repos:
        logger.info('')
        logger.info('Update these repos if needed:')

        for repo_def in discarded_repos:
            repo_home = join(repo_def.pull_dir, repo_def.repo_name)

            logger.info("> [{branch}] {location}".format(branch=repo_def.branch,
                                                         location=repo_home))


def __pull_repo(repo_def):
    repo_home = join(repo_def.pull_dir, repo_def.repo_name)

    try:
        if not exists(repo_home):
            makedirs(repo_home)
            rmdir(repo_home)

            clone_link = __get_clone_link(repo_def)

            logger.info('')
            logger.info("Cloning {link} ...".format(link=clone_link))

            git.Repo.clone_from(clone_link, repo_home)
            return

        if islink(repo_home):
            logger.info('')
            logger.info("<Symlink> {location} ...".format(location=repo_home))
            return

        logger.info('')
        logger.info("Pulling [{branch}] {dir} ...".format(branch=repo_def.branch,
                                                                dir=repo_home))

        repo = git.Repo(repo_home)
        repo.git.checkout(repo_def.branch)
        repo.remotes.origin.pull(repo_def.branch)
    except GitCommandError as err:
        logger.error("[GIT/Error] Unable to process repo - command={cmd} status={status}".format(cmd=err.command,
                                                                                           status=err.status))


def backup_repos(machine_name, os_name, select=False):
    repo_defs = __get_repo_defs(machine_name=machine_name,
                                os_name=os_name)

    discarded_repos = []

    if select:
        selected_repo = __select_repo(repo_defs, 'Choose a repo to backup:')

        if selected_repo and not selected_repo.backup_required:
            discarded_repos.append(selected_repo)
        else:
            __backup_repo(selected_repo)
    else:
        for repo_def in repo_defs:
            if repo_def and not repo_def.backup_required:
                discarded_repos.append(repo_def)
            else:
                __backup_repo(repo_def)

    if discarded_repos:
        logger.info('')
        logger.info('Backup these repos if needed:')

        for repo_def in discarded_repos:
            logger.info("> {backup}".format(backup=__get_backup_link(repo_def)))


def __backup_repo(repo_def):
    zip_name = "{repo}-{branch}.zip".format(repo=repo_def.repo_name,
                                            branch=repo_def.branch)
    zip_location = join(repo_def.backup_dir, zip_name)
    zip_url = __get_backup_link(repo_def)
    backup_location = ''

    if exists(zip_location):
        backup_location = "{zip}.bak".format(zip=zip_location)
        rename(src=zip_location, dst=backup_location)

    logger.info('')
    logger.info("Getting URL: {url}".format(url=zip_url))

    try:
        output = wget.download(zip_url, out=zip_location, bar=wget.bar_thermometer)

        logger.info("Downloaded backup: {output}".format(output=output))
    except HTTPError as err:
        logger.error("[HTTP/Error] Unable to get backup - code={code} msg={msg}".format(code=err.code,
                                                                                        msg=err.msg))

    if exists(backup_location):
        remove(backup_location)


def __select_repo(repo_defs, select_message):
    logger.info(select_message)

    i = 1
    for repo_def in repo_defs:
        logger.info("{i}) {name} [{branch}]".format(i=i,
                                                    name=repo_def.repo_name,
                                                    branch=repo_def.branch))
        i+=1

    logger.info("{i}) (default) <skip repo>".format(i=i))

    logger.info('repo-index> ')
    try:
        file_idx = int(input())
    except ValueError:
        file_idx = -1

    if file_idx < 0 or file_idx >= i:
        return None

    return repo_defs[file_idx - 1]


def __get_repo_defs(machine_name, os_name):
    query = repos_query.format(machine=machine_name,
                                  os=os_name) 
    conn = sqlite3.connect(sys_control_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    repo_defs = []

    for row in rows:
        hub_id, repo_name, branch, username, pull_flag, pull_dir, backup_flag, backup_dir = row

        pull_required = bool(pull_flag)
        backup_required = bool(backup_flag)
        pull_dir = env_vars.replace_all_envs(pull_dir)
        backup_dir = env_vars.replace_all_envs(backup_dir)

        repo = Repo(hub_id, repo_name, branch, username, pull_required, pull_dir, backup_required, backup_dir)

        logger.debug("Repo obtained: {repo}".format(repo=repo))

        repo_defs.append(repo)

    __load_hubs(list({repo.hub_id for repo in repo_defs}))

    return repo_defs


def __load_hubs(hub_ids):
    query = hubs_query.format(hub_ids=",".join(map(str, hub_ids))) 
    conn = sqlite3.connect(sys_control_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    for row in rows:
        hub_id, clone_template, backup_remplate = row
        hub = Hub(hub_id, clone_template, backup_remplate)

        logger.debug("Hub loaded: {hub}".format(hub=hub))

        repo_hubs[str(hub.hub_id)] = hub


def __get_clone_link(repo_def):
    hub = repo_hubs[str(repo_def.hub_id)]

    return hub.clone_template.format(username=repo_def.username,
                                     repo=repo_def.repo_name)


def __get_backup_link(repo_def):
    hub = repo_hubs[str(repo_def.hub_id)]

    return hub.backup_template.format(username=repo_def.username,
                                      repo=repo_def.repo_name,
                                      branch=repo_def.branch)


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=env_vars.logging_level())

        environ['GIT_PYTHON_TRACE'] = 'True'

        parser = argparse.ArgumentParser()
        parser.add_argument('-b', '--backup', action='store_true',
                            required=False, default=False,
                            help='Backup repos as ZIP files')
        parser.add_argument('-s', '--select', action='store_true',
                            required=False, default=False,
                            help='Allow select a repo')
        parser.add_argument('-n', '--name',
                            help='Machine name to get repos related')
        parser.add_argument('-o', '--os',
                            help='OS name to get repos related')
        args = parser.parse_args()

        if args.backup:
            backup_repos(machine_name=args.name,
                         os_name=args.os,
                         select=args.select)
        else:
            pull_repos(machine_name=args.name,
                         os_name=args.os,
                         select=args.select)
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

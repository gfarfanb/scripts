#!/usr/bin/env python

from os import environ, makedirs, rmdir, rename, remove
from os.path import islink, join, exists

import sys
import argparse
import json
import git
import wget
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

workspace_home = env_vars.env_value('WORKSPACE_HOME')
repos_home = env_vars.env_value('REPOS_HOME')
repos_def = env_vars.env_value('REPOS_DEF_FILE')

github_clone = "https://github.com/{username}/{repo}.git"
github_backup = "https://github.com/{username}/{repo}/archive/refs/heads/{branch}.zip"

gitlab_clone = "https://gitlab.com/{username}/{repo}.git"
gitlab_backup = "https://gitlab.com/{username}/{repo}/-/archive/master/{repo}-{branch}.zip"

logger = logging.getLogger()

def pull_repos(select=False):
    repo_defs = __get_repo_defs()

    discarded_repos = []

    if select:
        selected_repo = __select_repo(repo_defs, 'Choose a repo to pull:')

        if selected_repo and not selected_repo['pullRequired']:
            discarded_repos.append(selected_repo)
        else:
            __pull_repo(selected_repo)
    else:
        for repo_def in repo_defs:
            if repo_def and not repo_def['pullRequired']:
                discarded_repos.append(repo_def)
            else:
                __pull_repo(repo_def)

    if discarded_repos:
        logger.info('')
        logger.info('Update these repos if needed:')

        for repo_def in discarded_repos:
            repo_home = join(repo_def['location'], repo_def['name'])

            logger.info("> [{branch}] {location}".format(branch=repo_def['branch'],
                                                         location=repo_home))


def __pull_repo(repo_def):
    repo_home = join(repo_def['location'], repo_def['name'])

    if not exists(repo_home):
        makedirs(repo_home)
        rmdir(repo_home)

        logger.info("\nCloning {repo} ...".format(repo=repo_def['name']))

        git.Repo.clone_from(__get_clone_link(repo_def), repo_home)
        return

    if islink(repo_home):
        logger.info("\n{location} ...".format(location=repo_home))
        return

    logger.info("\nUpdating {repo} ...".format(repo=repo_def['name']))

    repo = git.Repo(repo_home)
    repo.git.checkout(repo_def['branch'])
    repo.remotes.origin.pull(repo_def['branch'])


def __get_clone_link(repo_def):
    match repo_def['hub']:
        case 'github':
            return github_clone.format(username=repo_def['username'],
                                       repo=repo_def['name'])
        case 'gitlab':
            return gitlab_clone.format(username=repo_def['username'],
                                       repo=repo_def['name'])


def backup_repos(select=False):
    repo_defs = __get_repo_defs()

    discarded_repos = []

    if select:
        selected_repo = __select_repo(repo_defs, 'Choose a repo to backup:')

        if selected_repo and not selected_repo['backupRequired']:
            discarded_repos.append(selected_repo)
        else:
            __backup_repo(selected_repo)
    else:
        for repo_def in repo_defs:
            if repo_def and not repo_def['backupRequired']:
                discarded_repos.append(repo_def)
            else:
                __backup_repo(repo_def)

    if discarded_repos:
        logger.info('')
        logger.info('Backup these repos if needed:')

        for repo_def in discarded_repos:
            logger.info("> {backup}".format(backup=__get_backup_link(repo_def)))


def __backup_repo(repo_def):
    zip_name = "{repo}-{branch}.zip".format(repo=repo_def['name'],
                                            branch=repo_def['branch'])
    zip_location = join(repo_def['backupLocation'], zip_name)
    zip_url = __get_backup_link(repo_def)

    if exists(zip_location):
        backup_location = "{zip}.bak".format(zip=zip_location)
        rename(src=zip_location, dst=backup_location)

    logger.info('')
    logger.info("Getting URL: {url}".format(url=zip_url))

    output = wget.download(zip_url, out=zip_location, bar=wget.bar_thermometer)

    logger.info("Downloaded backup: {output}".format(output=output))

    if exists(backup_location):
        remove(backup_location)


def __get_backup_link(repo_def):
    match repo_def['hub']:
        case 'github':
            return github_backup.format(username=repo_def['username'],
                                        repo=repo_def['name'],
                                        branch=repo_def['branch'])
        case 'gitlab':
            return gitlab_backup.format(username=repo_def['username'],
                                        repo=repo_def['name'],
                                        branch=repo_def['branch'])


def __select_repo(repo_defs, select_message):
    logger.info(select_message)

    i = 1
    for repo_def in repo_defs:
        logger.info("{i}) {name} [{branch}]".format(i=i,
                                                    name=repo_def['name'],
                                                    branch=repo_def['branch']))
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


def __get_repo_defs():
    with open(repos_def, 'r') as f:
        repo_defs = json.load(f)

    hubs = [ 'github', 'gitlab' ]
    vars = {
        "WORKSPACE_HOME": workspace_home,
        "REPOS_HOME": repos_home
    }

    for repo_def in repo_defs:
        try:
            if repo_def['hub'] not in hubs:
                raise ValueError("Invalid hub for repo: {hub} - {model}".format(
                    model=repo_def,
                    hub=repo_def['hub']))
            
            repo_def['location'] = repo_def['location'].format(**vars)
            repo_def['backupLocation'] = repo_def['backupLocation'].format(**vars)
        except KeyError as err:
            raise ValueError("Undefined field for repo: {n} - {model}".format(
                model=repo_def,
                n=err.args[0]))

    return repo_defs


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=env_vars.logging_level('DEBUG'))

        environ['GIT_PYTHON_TRACE'] = 'True'

        parser = argparse.ArgumentParser()
        parser.add_argument('-b', '--backup', action='store_true',
                            required=False, default=False,
                            help='Backup repos as ZIP files')
        parser.add_argument('-s', '--select', action='store_true',
                            required=False, default=False,
                            help='Allow select a repo')
        args = parser.parse_args()

        if args.backup:
            backup_repos(args.select)
        else:
            pull_repos(args.select)
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

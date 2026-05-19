#!/usr/bin/env python

from os import environ, listdir, makedirs, remove
from os.path import isfile, join, basename, exists, splitext, dirname
from sys import exit
from shutil import copyfile

import sys
import collections
import datetime
import argparse
import logging

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

logger = logging.getLogger()


def get_files_by_name(files_path):
    files = list(
        { join(files_path, f) for f in listdir(join(files_path)) if isfile(join(files_path, f)) }
    )
    files_by_name = {}

    for file in files:
        files_by_name[name_without_ext(file)] = file

    files_by_name = collections.OrderedDict(sorted(files_by_name.items()))

    return files_by_name


def name_without_ext(file_path):
    file_name = basename(file_path)
    index_of_dot = file_name.index('.')
    return file_name[:index_of_dot]


def select_file(files_by_name, select_message):
    logger.info(select_message)

    i = 1
    names = []
    for name in files_by_name:
        logger.info("{i}) {name}".format(i=i, name=name))
        names.append(name)
        i+=1

    logger.info("{i}) (default) <skip file>".format(i=i))

    logger.info('file-index> ')
    try:
        file_idx = int(input())
    except ValueError:
        file_idx = -1

    if file_idx < 0 or file_idx >= i:
        return None

    return files_by_name[names[file_idx - 1]]


def get_snapshot_dir(source_home):
    snapshots_home = join(source_home, 'snapshots')

    if not exists(snapshots_home):
        makedirs(snapshots_home)

    return snapshots_home


def create_snapshot(source_home, file_path, snapshots_home):
    tmp_tag = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    file_name = name_without_ext(file_path)
    snapshot_file_names = set()

    for f in listdir(join(source_home)):
        if basename(f).startswith(file_name):
            snapshot_file = join(snapshots_home, "{}.{}".format(f, tmp_tag))
            snapshot_file_names.add(basename(f))

            logger.info("Creating snapshot: \"{file}\"".format(file=snapshot_file))
            copyfile(join(source_home, f), snapshot_file)

    return snapshot_file_names


def recover_snapshot(source_home, snapshots_home, snapshot_file_names):
    for f in snapshot_file_names:
        snapshot = join(snapshots_home, f)
        file = splitext(basename(f))[0]

        logger.info("Recovering file: \"{snapshot}\" -> \"{file}\"".format(snapshot=snapshot, file=file))
        copyfile(snapshot, join(source_home, file))


def cleanup_snapshots(snapshots_home, snapshot_file_names, number_to_keep):
    for n in snapshot_file_names:
        snapshots = sorted(
            list( f for f in listdir(join(snapshots_home)) if splitext(basename(f))[0] == n ),
            reverse=True
        )
        skip = number_to_keep

        for snapshot in snapshots:
            if skip > 0:
                skip -= 1
                continue
            else:
                remove(join(snapshots_home, snapshot))


def cleanup_current(file_path, source_home):
    file_name = name_without_ext(file_path)

    for f in listdir(join(source_home)):
        if basename(f).startswith(file_name):
            file = join(source_home, f)

            logger.info("Removing file: \"{file}\"".format(file=file))
            remove(file)


def select_snapshot(file_name, snapshots_home):
    snapshot_groups = {}
    snapshot_versions = {}

    for f in listdir(join(snapshots_home)):
        if basename(f).startswith(file_name):
            snapshot_name = splitext(basename(f))[0]
            version = snapshot_versions.get(snapshot_name, 0)
            version += 1

            snapshot_versions[snapshot_name] = version

            group = snapshot_groups.get(str(version), [])
            group.append(f)

            snapshot_groups[str(version)] = group

    logger.info('')
    logger.info('Select backup version')

    last = 0
    for k, v in snapshot_groups.items():
        logger.info("{i}) {name}".format(i=k, name=v))

        if int(k) > last:
            last = int(k)

    logger.info("{i}) (default) <skip file>".format(i=(last + 1)))

    logger.info('version-index> ')
    selected_version = input()

    try:
        return snapshot_groups[selected_version]
    except KeyError:
        return None


def select_and_execute_snapshot(files_home, number_to_keep):
    files_by_name = get_files_by_name(files_home)

    if len(files_by_name) < 1:
        raise ValueError('Empty source directory')

    file_path = select_file(files_by_name, 'Choose a file to create a snapshot:')

    execute_snapshot(file_path=file_path,
                     number_to_keep=number_to_keep)


def execute_snapshot(file_path, number_to_keep):
    if not exists(file_path):
        raise ValueError('Invalid source file')

    logger.info('')

    source_home = dirname(file_path)
    snapshots_home = get_snapshot_dir(source_home)
    snapshot_file_names = create_snapshot(source_home, file_path, snapshots_home)

    cleanup_snapshots(snapshots_home, snapshot_file_names, number_to_keep)


def select_and_execute_recover(files_home):
    snapshots_home = get_snapshot_dir(files_home)
    files_by_name = get_files_by_name(snapshots_home)

    if len(files_by_name) < 1:
        raise ValueError('Snapshot not recovered')

    file_path = select_file(files_by_name, 'Choose a file to recover its snapshot:')

    execute_recover(file_path)


def execute_recover(file_path):
    if not exists(file_path):
        raise ValueError('Invalid source file')

    source_home = dirname(file_path)
    snapshots_home = get_snapshot_dir(source_home)
    snapshot_file_names = select_snapshot(file_path, snapshots_home)

    if snapshot_file_names is None:
        raise ValueError('Snapshot not recovered')

    logger.info('')

    cleanup_current(file_path, source_home)
    recover_snapshot(source_home, snapshots_home, snapshot_file_names)


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-s', '--source',
                            help='Source directory or file')
        parser.add_argument('-r', '--recover', action='store_true',
                            help='Enables recover snapshot files')
        parser.add_argument('-k', '--keep', type=int, default=1,
                            help='Number of the snapshots to keep')
        args = parser.parse_args()

        if not args.source:
            args.source = input('source-directory-or-file> ')

        if isfile(args.source):
            if args.recover:
                execute_recover(file_path=args.source)
            else:
                execute_snapshot(file_path=args.source,
                                 number_to_keep=args.keep)
        else:
            if args.recover:
                select_and_execute_recover(files_home=args.source)
            else:
                select_and_execute_snapshot(files_home=args.source,
                                            number_to_keep=args.keep)
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

#!/usr/bin/env python

from os import listdir, makedirs, remove, environ
from os.path import isfile, join, basename, exists, splitext
from sys import exit
from shutil import copyfile

import datetime
import argparse
import logging


logger = logging.getLogger()


def names_without_ext(files_path):
    files = list(
        { name_without_ext(f) for f in listdir(join(files_path)) if isfile(join(files_path, f)) }
    )
    return sorted(files)


def name_without_ext(file_path):
    file_name = basename(file_path)
    index_of_dot = file_name.index('.')
    return file_name[:index_of_dot]


def select_file_name(names, select_message):
    logger.info(select_message)

    i = 1
    for name in names:
        logger.info("{i}) {name}".format(i=i, name=name))
        i+=1

    logger.info("{i}) (default) <skip file>".format(i=i))

    logger.info("file-index> ")
    try:
        file_idx = int(input())
    except ValueError:
        file_idx = -1

    if file_idx < 0 or file_idx >= i:
        return None

    return names[file_idx - 1]


def get_snapshot_dir(files_home):
    snapshots_home = join(files_home, "snapshots")

    if not exists(snapshots_home):
        makedirs(snapshots_home)

    return snapshots_home


def create_snapshot(files_home, file_name, snapshots_home):
    tmp_tag = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    snapshot_file_names = set()

    for f in listdir(join(files_home)):
        if basename(f).startswith(file_name):
            snapshot_file = join(snapshots_home, "{}.{}".format(f, tmp_tag))
            snapshot_file_names.add(basename(f))

            logger.info("Creating snapshot: \"{file}\"".format(file=snapshot_file))
            copyfile(join(files_home, f), snapshot_file)

    return snapshot_file_names


def recover_snapshot(files_home, snapshots_home, snapshot_file_names):
    for f in snapshot_file_names:
        snapshot = join(snapshots_home, f)
        file = splitext(basename(f))[0]

        logger.info("Recovering file: \"{snapshot}\" -> \"{file}\"".format(snapshot=snapshot, file=file))
        copyfile(snapshot, join(files_home, file))


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


def cleanup_current(file_name, files_home):
    for f in listdir(join(files_home)):
        if basename(f).startswith(file_name):
            file = join(files_home, f)

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

    logger.info("\nSelect backup version")

    last = 0
    for k, v in snapshot_groups.items():
        logger.info("{i}) {name}".format(i=k, name=v))

        if int(k) > last:
            last = int(k)

    logger.info("{i}) (default) <skip file>".format(i=(last + 1)))

    logger.info("version-index> ")
    selected_version = input()

    try:
        return snapshot_groups[selected_version]
    except KeyError:
        return None


def not_created_err():
    raise ValueError("Snapshot not created")


def not_recovered_err():
    raise ValueError("Snapshot not recovered")


def execute_snapshot(files_home, number_to_keep):
    names = names_without_ext(files_home)

    if len(names) < 1:
        not_created_err()

    file_name = select_file_name(names, "Choose a file to create a snapshot:")

    if file_name is None:
        not_created_err()

    logger.info('')

    snapshots_home = get_snapshot_dir(files_home)
    snapshot_file_names = create_snapshot(files_home, file_name, snapshots_home)

    cleanup_snapshots(snapshots_home, snapshot_file_names, number_to_keep)


def execute_recover(files_home):
    snapshots_home = get_snapshot_dir(files_home)
    names = names_without_ext(snapshots_home)

    if len(names) < 1:
        not_recovered_err()

    file_name = select_file_name(names, "Choose a file to recover its snapshot:")

    if file_name is None:
        not_recovered_err()

    snapshot_file_names = select_snapshot(file_name, snapshots_home)

    if snapshot_file_names is None:
        not_recovered_err()

    logger.info('')

    cleanup_current(file_name, files_home)
    recover_snapshot(files_home, snapshots_home, snapshot_file_names)


def env_value(name, default_value=...):
    try:
        if not environ[name]:
            return default_value
        else:
            return environ[name]
    except KeyError:
        logger.error("Environment variable {name} not found, default: {default}".format(name=name, default=default_value))
        return default_value


def main():
    try:
        logging.basicConfig(
            format='%(message)s',
            level=logging.getLevelName(
                env_value("LOGGING_LEVEL", "INFO")
                ))

        parser = argparse.ArgumentParser()
        parser.add_argument("-d", "--directory",
                            help="Location of the files",
                            default=env_value("SNAPSHOTS_SOURCE_DIR"))
        parser.add_argument("-k", "--keep", type=int,
                            help="Number of snapshots to keep",
                            default=env_value("SNAPSHOTS_TO_KEEP", 1))
        parser.add_argument("-r", "--recover", action="store_true",
                            help="Enables recover snapshot files")
        args = parser.parse_args()

        if args.recover:
            execute_recover(files_home=args.directory)
        else:
            execute_snapshot(files_home=args.directory,
                             number_to_keep=args.keep)
    except ValueError as err:
        print(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

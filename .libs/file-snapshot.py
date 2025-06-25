#!/usr/bin/env python

from os import listdir, makedirs, remove
from os.path import isfile, join, basename, exists, splitext
from sys import argv, exit
from shutil import copyfile

import datetime

def names_without_ext(files_path):
    files = list(
        { name_without_ext(f) for f in listdir(join(files_path)) if isfile(join(files_path, f)) }
    )
    return sorted(files)


def name_without_ext(file_path):
    file_name = basename(file_path)
    index_of_dot = file_name.index('.')
    return file_name[:index_of_dot]


def select_file_name(names):
    i = 1
    print("Choose a file to create a snapshot:")
    for name in names:
        print("{i}) {name}".format(i=i, name=name))
        i+=1

    print("{i}) (default) <skip snapshot>".format(i=i))

    print("file-index> ")
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

            print("Creating snapshot: \"{file}\"".format(file=snapshot_file))
            copyfile(join(files_home, f), snapshot_file)

    return snapshot_file_names


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


def not_created_message():
    print("Snapshot not created")
    return 0


def main():
    try:
        files_home=argv[1]
        number_to_keep=int(argv[2])
    except IndexError:
        print("Missing args: {py} <files-directory> <number-of-snapshots-to-keep>".format(py=basename(__file__)))
        return 0

    names = names_without_ext(files_home)

    if len(names) < 1:
        return not_created_message()

    file_name = select_file_name(names)

    if file_name is None:
        return not_created_message()

    snapshots_home = get_snapshot_dir(files_home)
    snapshot_file_names = create_snapshot(files_home, file_name, snapshots_home)

    cleanup_snapshots(snapshots_home, snapshot_file_names, number_to_keep)

    return 0


if __name__ == '__main__':

    exit(main())

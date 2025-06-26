#!/usr/bin/env python

from os import listdir, makedirs, remove, environ
from os.path import isfile, join, basename, exists, splitext
from sys import argv, exit
from shutil import copyfile

import datetime


def arg_value(idx, name):
    try:
        return argv[idx]
    except IndexError:
        args = ""
        for i in range(idx - 1) : args += "<arg-" + str(i + 1) + "> "
        args += "<" + name + ">"

        raise ValueError("Missing args: {scr} {args}".format(scr=basename(__file__), args=args))


def env_value(name):
    try:
        return environ[name]
    except KeyError:
        raise ValueError("Missing env-variable: {n}".format(n=name))


def is_recover(v):
    return v.lower() in ['-r', '--recover']


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
    print(select_message)

    i = 1
    for name in names:
        print("{i}) {name}".format(i=i, name=name))
        i+=1

    print("{i}) (default) <skip file>".format(i=i))

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


def recover_snapshot(files_home, snapshots_home, snapshot_file_names):
    for f in snapshot_file_names:
        snapshot = join(snapshots_home, f)
        file = splitext(basename(f))[0]

        print("Recovering file: \"{snapshot}\" -> \"{file}\"".format(snapshot=snapshot, file=file))
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

            print("Removing file: \"{file}\"".format(file=file))
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

    print("\nSelect backup version")

    last = 0
    for k, v in snapshot_groups.items():
        print("{i}) {name}".format(i=k, name=v))

        if int(k) > last:
            last = int(k)

    print("{i}) (default) <skip file>".format(i=(last + 1)))

    print("version-index> ")
    selected_version = input()

    try:
        return snapshot_groups[selected_version]
    except KeyError:
        return None


def not_created_err():
    raise ValueError("Snapshot not created")


def not_recovered_err():
    raise ValueError("Snapshot not recovered")


def execute_snapshot(files_home):
    number_to_keep = int(env_value('SNAPSHOTS_TO_KEEP'))
    names = names_without_ext(files_home)

    if len(names) < 1:
        not_created_err()

    file_name = select_file_name(names, "Choose a file to create a snapshot:")

    if file_name is None:
        not_created_err()

    print()

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

    print()

    cleanup_current(file_name, files_home)
    recover_snapshot(files_home, snapshots_home, snapshot_file_names)


def main():
    try:
        files_home=arg_value(1, "files-directory")
        recover_flag=is_recover(arg_value(2, "recover-flag"))

        if recover_flag:
            execute_recover(files_home)
        else:
            execute_snapshot(files_home)
    except ValueError as err:
        print(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())

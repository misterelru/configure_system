#!/usr/bin/python3

'''Module for sync local DB with GDrive'''

import os
import shutil
import time
import sys

from sys import argv

def sync_files(source_file_from_cloud: str) -> None:
    '''Compare local DB file with DB file fom GoogleDrive'''
    path_to_this_module = os.path.dirname(os.path.realpath(__file__))

    synced_database_file = os.path.join(path_to_this_module, 'Database.kdbx')

    if os.path.exists(synced_database_file and source_file_from_cloud):
        size_synced_file = os.stat(synced_database_file).st_size
        size_source_file = os.stat(source_file_from_cloud).st_size
        if size_source_file != size_synced_file:
            shutil.copy(source_file_from_cloud, synced_database_file)
    else:
        sys.exit(2)

while True:
    SOURCE_FILE_FROM_CLOUD = argv[1]
    sync_files(SOURCE_FILE_FROM_CLOUD)
    time.sleep(3600)

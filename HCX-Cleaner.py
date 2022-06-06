#!/usr/bin/python

"""
Author:  Christian Soto (chsoto@vmware.com)
"""

##### BEGIN IMPORTS #####

import os
import subprocess
import argparse

def get_args():
    parser = argparse.ArgumentParser(description='HCX 4.3 Database Cleaner')

    parser.add_argument('-s', '--clear', action="store_true", help='delete mongo-export folder')
    parser.add_argument('-c', '--check', action="store_true", help='brief health check on ALL nodes')
    parser.add_argument('-v', '--vacuum', nargs=1, type=str, help='brief health check on ALL nodes')

    args = parser.parse_args()

    return(args)

VMENV = os.environ

##### END IMPORTS #####

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(color, delim, title):
    print(f"{color}{delim}{title}{delim}{bcolors.ENDC}")

def main():

    args = get_args()

    if args.check:
        check_settings()
    elif args.clear:
        clear_space()
    elif args.vacuum:
        #vax(args.vacuum)
        print("UNCOMMENT")

def subprocess_cmd(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    proc_stdout = process.communicate()[0].strip()
    output=proc_stdout.decode('ascii')
    return(output)

def check_settings():
    print(subprocess_cmd("df -h"))
    print(subprocess_cmd("du /common -ahx . | sort -rh | head -n 30"))
    print(subprocess_cmd("ps -ef | grep vacuum"))
    print(subprocess_cmd("systemctl --no-pager status zookeeper | grep 'zookeeper.service - Zookeeper\|active'"))
    print(subprocess_cmd("systemctl --no-pager status kafka | grep 'kafka.service - Kafka\|active'"))
    print(subprocess_cmd("systemctl --no-pager status app-engine | grep 'app-engine.service - App-Engine\|active'"))
    print(subprocess_cmd("systemctl --no-pager status web-engine | grep 'web-engine.service - WebEngine\|active'"))
    print(subprocess_cmd("systemctl --no-pager status appliance-management | grep 'appliance-management.service - Appliance Management\|active'"))
    print(subprocess_cmd("systemctl --no-pager status postgresdb | grep 'postgresdb.service - PostgresDB\|active'"))
    print(subprocess_cmd("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"SELECT name, setting FROM pg_settings WHERE name='autovacuum';\""))
    print(subprocess_cmd("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"SELECT relname, n_dead_tup FROM pg_stat_user_tables;\" | head"))
    print(subprocess_cmd("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"SELECT relname, last_vacuum, last_autovacuum FROM pg_stat_user_tables;\" | head"))
    print(subprocess_cmd("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"select current_database() as database, pg_size_pretty(total_database_size) as total_database_size, schema_name, table_name, pg_size_pretty(total_table_size) as pretty_total_table_size, pg_size_pretty(table_size) as pretty_table_size, pg_size_pretty(index_size) as pretty_index_size from ( select table_name, table_schema as schema_name, pg_database_size(current_database()) as total_database_size, pg_total_relation_size(quote_ident(table_name)) as total_table_size, pg_relation_size(quote_ident(table_name)) as table_size, pg_indexes_size(quote_ident(table_name)) as index_size from information_schema.tables where table_schema=current_schema()order by total_table_size) as sizes ORDER BY total_table_size desc, table_size desc, index_size desc;\" | head"))

def clear_space():
    print(subprocess_cmd("systemctl stop zookeeper; systemctl stop kafka; systemctl stop app-engine; systemctl stop web-engine; systemctl stop appliance-management; systemctl stop postgresdb"))
    print(subprocess_cmd("cd /common ; rm -rf mongo-export"))
    print(subprocess_cmd("systemctl start zookeeper; systemctl start kafka; systemctl start app-engine; systemctl start web-engine; systemctl start appliance-management; systemctl start postgresdb"))
    print(subprocess_cmd("df -h"))

#def vax(table_name):
    #print(subprocess_cmd("systemctl stop zookeeper; systemctl stop kafka; systemctl stop app-engine; systemctl stop web-engine; systemctl stop appliance-management; systemctl stop postgresdb"))
    #print(subprocess_cmd("systemctl start postgresdb"))
    #print("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"VACUUM FULL \\"{table}\\";\"".format(table=table_name[0]))
    #print(subprocess_cmd("/opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c \"VACUUM FULL \"{table}\";\"".format(table=table_name[0])))
    #print(subprocess_cmd("systemctl stop postgresdb; systemctl start postgresdb"))
    #print(subprocess_cmd("rm -rf /common/zookeeper-db/*; rm -rf /common/kafka-db/*"))

if __name__ == "__main__":
    main()
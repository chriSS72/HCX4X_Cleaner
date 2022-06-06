#/bin/bash

:<<'###########################################'
Author:  Christian Soto (chsoto@vmware.com)
###########################################

declare -A bcolors;

bcolors[HEADER]="\033[95m";
bcolors[OKBLUE]="\033[94m";
bcolors[OKCYAN]="\033[96m";
bcolors[OKGREEN]="\033[92m";
bcolors[WARNING]="\033[93m";
bcolors[FAIL]="\033[91m";
bcolors[ENDC]="\033[0m";
bcolors[BOLD]="\033[1m";
bcolors[UNDERLINE]="\033[4m";

print_header() {
    echo -e "$1$2$3$2${bcolors[ENDC]}";
}

Service_Management() {
    if [ "$1" == "start" ]; then
        print_header ${bcolors[HEADER]} "" "Zookeeper Service:";
        systemctl start zookeeper; 
        systemctl --no-pager status zookeeper | grep 'zookeeper.service - Zookeeper\|active';
        print_header ${bcolors[HEADER]} "" "Kafka Service:";
        systemctl start kafka; 
        systemctl --no-pager status kafka | grep 'kafka.service - Kafka\|active';
        print_header ${bcolors[HEADER]} "" "App-Engine Service:";
        systemctl start app-engine; 
        systemctl --no-pager status app-engine | grep 'app-engine.service - App-Engine\|active';
        print_header ${bcolors[HEADER]} "" "WebEngine Service:";
        systemctl start web-engine; 
        systemctl --no-pager status web-engine | grep 'web-engine.service - WebEngine\|active';
        print_header ${bcolors[HEADER]} "" "Appliance Management Service:";
        systemctl start appliance-management; 
        systemctl --no-pager status appliance-management | grep 'appliance-management.service - Appliance Management\|active';
        print_header ${bcolors[HEADER]} "" "PostgresDB Service:";
        systemctl start postgresdb;
        systemctl --no-pager status postgresdb | grep 'postgresdb.service - PostgresDB\|active';
    elif [ "$1" == "stop" ]; then
        print_header ${bcolors[HEADER]} "" "Zookeeper Service:";
        systemctl stop zookeeper; 
        systemctl --no-pager status zookeeper | grep 'zookeeper.service - Zookeeper\|active';
        print_header ${bcolors[HEADER]} "" "Kafka Service:";
        systemctl stop kafka; 
        systemctl --no-pager status kafka | grep 'kafka.service - Kafka\|active';
        print_header ${bcolors[HEADER]} "" "App-Engine Service:";
        systemctl stop app-engine; 
        systemctl --no-pager status app-engine | grep 'app-engine.service - App-Engine\|active';
        print_header ${bcolors[HEADER]} "" "WebEngine Service:";
        systemctl stop web-engine; 
        systemctl --no-pager status web-engine | grep 'web-engine.service - WebEngine\|active';
        print_header ${bcolors[HEADER]} "" "Appliance Management Service:";
        systemctl stop appliance-management; 
        systemctl --no-pager status appliance-management | grep 'appliance-management.service - Appliance Management\|active';
        print_header ${bcolors[HEADER]} "" "PostgresDB Service:";
        systemctl stop postgresdb;
        systemctl --no-pager status postgresdb | grep 'postgresdb.service - PostgresDB\|active';
    else
        print_header ${bcolors[HEADER]} "" "Zookeeper Service:";
        systemctl --no-pager status zookeeper | grep 'zookeeper.service - Zookeeper\|active';
        print_header ${bcolors[HEADER]} "" "Kafka Service:";
        systemctl --no-pager status kafka | grep 'kafka.service - Kafka\|active';
        print_header ${bcolors[HEADER]} "" "App-Engine Service:";
        systemctl --no-pager status app-engine | grep 'app-engine.service - App-Engine\|active';
        print_header ${bcolors[HEADER]} "" "WebEngine Service:";
        systemctl --no-pager status web-engine | grep 'web-engine.service - WebEngine\|active';
        print_header ${bcolors[HEADER]} "" "Appliance Management Service:";
        systemctl --no-pager status appliance-management | grep 'appliance-management.service - Appliance Management\|active';
        print_header ${bcolors[HEADER]} "" "PostgresDB Service:";
        systemctl --no-pager status postgresdb | grep 'postgresdb.service - PostgresDB\|active';
    fi
}

if [ -z "$1" ]; then
    echo "Try '$0 --help' or '$0 -h'";
    exit 1
fi

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo " ";
            echo "$0 [option] '[argument]'";
            echo " ";
            echo "options:";
            echo "-h, --help                        show this options menu";
            echo "-c, --check                       check storage consumption on /common, services and other";
            echo "-r, --remove                      delete /common/mongo-export folder";
            echo "-v, --vacuum \"<TABLE>\"            run VACUUM FULL on a PostgresDB table";
            exit 0
            ;;
        -c|--check)
            print_header ${bcolors[OKGREEN]} "" "Checking HCX Connector storage";

            print_header ${bcolors[OKCYAN]} "" "Storage Utilization on /common";
            df -h /common;
            print_header ${bcolors[OKCYAN]} "" "Content inside /common";
            du /common -ahx . | sort -rh | head -n 30;
            print_header ${bcolors[OKCYAN]} "" "Auto-vacuum Process";
            ps -ef | grep vacuum;
            
            print_header ${bcolors[OKCYAN]} "" "Services Status";
            Service_Management;

            print_header ${bcolors[OKCYAN]} "" "Postgres Settings";
            print_header ${bcolors[HEADER]} "" "Auto-vacuum enabled?";
            /opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c "SELECT name, setting FROM pg_settings WHERE name='autovacuum';";
            print_header ${bcolors[HEADER]} "" "Dead tuples?";
            /opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c "SELECT relname, n_dead_tup FROM pg_stat_user_tables;";
            print_header ${bcolors[HEADER]} "" "Last vacuum date?";
            /opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c "SELECT relname, last_vacuum, last_autovacuum FROM pg_stat_user_tables;";
            print_header ${bcolors[HEADER]} "" "Largest tables?";
            # Can run on VM Table, Job and Datastore
            /opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c "SELECT current_database() as database, 
                                                                                pg_size_pretty(total_database_size) as total_database_size, schema_name, 
                                                                                table_name, pg_size_pretty(total_table_size) as pretty_total_table_size, 
                                                                                pg_size_pretty(table_size) as pretty_table_size, pg_size_pretty(index_size) 
                                                                                as pretty_index_size from ( select table_name, table_schema as schema_name, 
                                                                                pg_database_size(current_database()) as total_database_size, pg_total_relation_size(quote_ident(table_name)) 
                                                                                as total_table_size, pg_relation_size(quote_ident(table_name)) as table_size, pg_indexes_size(quote_ident(table_name)) 
                                                                                as index_size from information_schema.tables where table_schema=current_schema()order by total_table_size) 
                                                                                as sizes ORDER BY total_table_size desc, table_size desc, index_size desc;" | head;
            exit 0
            ;;
        -r|--remove)
            print_header ${bcolors[OKGREEN]} "" "Removing Export Folder";
            print_header ${bcolors[OKCYAN]} "" "Stopping Services";
            Service_Management stop;

            print_header ${bcolors[OKCYAN]} "" "Deleting /common/mongo-export folder";
            rm -rf /common/mongo-export;
            print_header ${bcolors[OKCYAN]} "" "Starting Services";
            Service_Management start;
            print_header ${bcolors[OKCYAN]} "" "Storage Utilization on /common";
            df -h /common;
            exit 0
            ;;
        -v|--vacuum)
            print_header ${bcolors[OKGREEN]} "" "Running VACUUM FULL on $2";
            print_header ${bcolors[OKCYAN]} "" "Stopping Services";
            Service_Management stop;
            print_header ${bcolors[OKCYAN]} "" "Starting PostgresDB Service";
            systemctl start postgresdb;
            print_header ${bcolors[OKCYAN]} "" "Running Vacuum";
            /opt/third-party/postgresql-13.4/bin/psql -U postgres hybridity -c "VACUUM FULL \"$2\";";
            print_header ${bcolors[OKCYAN]} "" "Stopping PostgresDB Service";
            systemctl stop postgresdb;
            print_header ${bcolors[OKCYAN]} "" "Clearing content under /common/zookeper-db/ and /common/kafka-db/";
            # Delete if more than 1 GB
            rm -rf /common/zookeeper-db/*; 
            rm -rf /common/kafka-db/*;
            print_header ${bcolors[OKCYAN]} "" "Starting Services";
            Service_Management start;
            exit 0
            ;;
        *)
            echo "invalid flag '$1'";
            echo "Valid options are:";
            echo "-h, --help                        show this options menu";
            echo "-c, --check                       check storage consumption on /common, services and other";
            echo "-r, --remove                      delete /common/mongo-export folder";
            echo "-v, --vacuum \"<TABLE>\"            run VACUUM FULL on a PostgresDB table";
            echo "Usage: $0 [OPTION]...";
            echo "Try '$0 --help' for more information.";
            break
            ;;
    esac
done
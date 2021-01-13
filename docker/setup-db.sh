#!/usr/bin/env bash
#
# This script sets up the Koji database with some users for testing with
# osbuild.  The script requires the database container to be running and to
# have the Koji tables already created.  The Koji tables can be created by
# starting the Koji service.

set -eu

usage() {
    echo "Usage: $0 [container]"
    echo
    echo "Positional arguments"
    echo "  container    Name of the database container (default: org.osbuild.koji.postgres)"
    exit 1
}

nargs=$#
case $nargs in
    0)
        dbcontainer=org.osbuild.koji.postgres
        ;;
    1)
        dbcontainer=$1
        ;;
    *)
        usage
        ;;
esac

echo "Setting up database in container $dbcontainer"

psql_cmd () {
    docker exec "${dbcontainer}" psql -U koji -d koji "$@"
}

error() {
    echo "DB setup failed. Make sure the container ${dbcontainer} is running and the Koji service has created its tables."
}

trap error EXIT

# create koji users
# kojiadmin/kojipass    - admin
# osbuild/osbuildpass   - regular user
# osbuild-krb:          - regular user authenticated with Kerberos principal osbuild-krb@LOCAL
psql_cmd -c "insert into users (name, password, status, usertype) values ('kojiadmin', 'kojipass', 0, 0)" >/dev/null
psql_cmd -c "insert into user_perms (user_id, perm_id, creator_id) values (1, 1, 1)" >/dev/null
psql_cmd -c "insert into users (name, password, status, usertype) values ('osbuild', 'osbuildpass', 0, 0)" >/dev/null
psql_cmd -c "insert into users (name, status, usertype) values ('osbuild-krb', 0, 0)" >/dev/null
psql_cmd -c "insert into user_krb_principals (user_id, krb_principal) values (3, 'osbuild-krb@LOCAL')" >/dev/null

# create content generator osbuild, give osbuild and osbuild-krb users access to it
psql_cmd -c "insert into content_generator (name) values ('osbuild')" >/dev/null
psql_cmd -c "insert into cg_users (cg_id, user_id, creator_id, active) values (1, 2, 1, true), (1, 3, 1, true)" >/dev/null

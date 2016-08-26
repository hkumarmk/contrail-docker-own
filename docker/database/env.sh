#!/usr/bin/env bash
set -a
set -x
source /common.sh

IPADDRESS=${IPADDRESS:-${primary_ip}}
MY_INDEX=$(index_of_ip $SEED_LIST $IPADDRESS)

CONFIG_API_PORT=${CONFIG_API_PORT:-8082}
CFGM_IP=${CFGM_IP:-$IPADDRESS}

DATABASE_IP=${DATABASE_IP:-$IPADDRESS}
CASSANDRA_DIRECTORY=${CASSANDRA_DIRECTORY}
INITIAL_TOKEN=${INITIAL_TOKEN:-0}
SEED_LIST=${SEED_LIST:-$DATABASE_IP}
DATA_DIR=${DATA_DIR}
ANALYTICS_DATA_DIR=${ANALYTICS_DATA_DIR}
SSD_DATA_DIR=${SSD_DATA_DIR}
ZOOKEEPER_IP_LIST=${ZOOKEEPER_IP_LIST:-$SEED_LIST}
#  The index of this databse node
DATABASE_INDEX=${DATABASE_INDEX:-${MY_INDEX}}
# Required minimum disk space for contrail database
MINIMUM_DISKGB=${MINIMUM_DISKGB:-200}
#The broker id of the database node
KAFKA_BROKER_ID=${KAFKA_BROKER_ID:-${MY_INDEX}}
# The DB node to remove from the cluster
NODE_TO_DELETE=${NODE_TO_DELETE}
CASSANDRA_USER=${CASSANDRA_USER}
CASSANDRA_PASSWORD=${CASSANDRA_PASSWORD}

KEYSTONE_ADMIN_USER=${OS_USERNAME:-admin}
KEYSTONE_ADMIN_PASSWORD=${OS_PASSWORD:-admin}
KEYSTONE_ADMIN_TENANT=${OS_TENANT_NAME:-admin}

# kafka Web Console Chef Cookbook

Kafka web console is a web-based user interface to let users manage and monitor Kafka clusters.

## Supported Features

* Monitor the throughput of each Kafka cluster, each topic.
* Monitor the Kafka consumer lag.
* Monitor the CPU, memory, disk I/O, network usage of each cluster, each server.
* Create new topic, edit and list existing topics.

## Recipes

* `pkg_install`              - Install gmond, gmetad, gweb and kafka-manager binaries
* `nginx`                    - Manage nginx related directories and configs
* `kafka-manager`            - Manage kafka-manager related directories and configs
* `burrow_install`           - Manage Burrow installation.

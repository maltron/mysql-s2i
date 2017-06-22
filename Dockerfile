FROM centos:centos7

# MySQL image for OpenShift.
#
# Volumes:
#  * /var/lib/mysql/data - Datastore for MySQL
# Environment:
#  * $MYSQL_USER - Database user name
#  * $MYSQL_PASSWORD - User's password
#  * $MYSQL_DATABASE - Name of the database to create
#  * $MYSQL_ROOT_PASSWORD (Optional) - Password for the 'root' MySQL account

ENV MYSQL_VERSION=5.7 \
    HOME=/var/lib/mysql

ENV SUMMARY="MySQL 5.7 SQL database server" \
    DESCRIPTION="MySQL is a multi-user, multi-threaded SQL database server. The container \
image provides a containerized packaging of the MySQL mysqld daemon and client application. \
The mysqld server daemon accepts connections from clients and provides access to content from \
MySQL databases on behalf of the clients."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="MySQL 5.7" \
      io.openshift.expose-services="3306:mysql" \
      io.openshift.tags="database,mysql,mysql57,rh-mysql57" \
      com.redhat.component="rh-mysql57-docker" \
      name="centos/mysql-57-centos7" \
      version="5.7" \
      release="1" \
      # this label tells s2i where to find its mandatory scripts
      # (run, assemble, save-artifacts)
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"


EXPOSE 3306

# This image must forever use UID 27 for mysql user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.
RUN yum install -y yum-utils && \
    yum install -y centos-release-scl && \
    yum-config-manager --enable centos-sclo-rh-testing && \
    INSTALL_PKGS="rsync tar gettext hostname bind-utils rh-mysql57" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/mysql/data && chown -R mysql.0 /var/lib/mysql && \
    test "$(id mysql)" = "uid=27(mysql) gid=27(mysql) groups=27(mysql)" 
### Create all the necessary scripts for S2I and give the proper permissions
#    mkdir -p /usr/libexec/s2i && \
#    printf "#!/bin/sh\n\
#mv /tmp/src/*.war /usr/local/tomcat/webapps" > /usr/libexec/s2i/assemble && \
#    printf "#!/bin/sh\n\
#mongod --dbpath /var/lib/mongodb/data\n" > /usr/libexec/s2i/run && \
#    chmod 755 /usr/libexec/s2i/*

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mysql \
    MYSQL_PREFIX=/opt/rh/rh-mysql57/root/usr \
    ENABLED_COLLECTIONS=rh-mysql57

# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    PROMPT_COMMAND=". ${CONTAINER_SCRIPTS_PATH}/scl_enable"

COPY root /

# this is needed due to issues with squash
# when this directory gets rm'd by the container-setup
# script.
RUN rm -rf /etc/my.cnf.d/*
RUN /usr/libexec/container-setup

VOLUME ["/var/lib/mysql/data"]

USER 27

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mysqld"]

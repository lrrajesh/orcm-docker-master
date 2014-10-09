FROM benmcclelland/orcm-git-centos

MAINTAINER Ben McClelland <ben.mcclelland@gmail.com>

RUN yum localinstall -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    yum install -y supervisor openssh-server dnsmasq sudo

RUN yum localinstall -y http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm && \
    yum install -y postgresql93-server postgresql93-odbc && \
    /etc/init.d/postgresql-9.3 initdb

EXPOSE 53 55805 55820 5432

ADD supervisor.conf /etc/supervisor.conf
ADD dnsmasq.conf /etc/dnsmasq.conf

RUN mkdir -p /opt/docker/dnsmasq.d
RUN mkdir /var/run/sshd
RUN /usr/bin/ssh-keygen -q -t rsa1 -f /etc/ssh/ssh_host_key -C '' -N '' && chmod 600 /etc/ssh/ssh_host_key && chmod 644 /etc/ssh/ssh_host_key.pub
RUN /usr/bin/ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N '' && chmod 600 /etc/ssh/ssh_host_rsa_key && chmod 644 /etc/ssh/ssh_host_rsa_key.pub
RUN /usr/bin/ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -C '' -N '' && chmod 600 /etc/ssh/ssh_host_dsa_key && chmod 644 /etc/ssh/ssh_host_dsa_key.pub

RUN echo 'root:docker' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN perl -pi -e "s:<Path to the PostgreSQL ODBC driver>:$(rpm -ql postgresql93-odbc | grep psqlodbc.so):" orcm/contrib/database/psql_odbc_driver.ini && \
    odbcinst -i -d -f orcm/contrib/database/psql_odbc_driver.ini && \
    perl -pi -e "s:<Name of the PostgreSQL driver>:$(rpm -ql postgresql93-odbc | grep psqlodbc.so):" orcm/contrib/database/orcmdb_psql.ini && \
    perl -pi -e "s:<Name or IP address of the database server>:localhost:" orcm/contrib/database/orcmdb_psql.ini && \
    odbcinst -i -s -f orcm/contrib/database/orcmdb_psql.ini -h

ADD pg_hba.conf /var/lib/pgsql/9.3/data/pg_hba.conf
ADD postgresql.conf /var/lib/pgsql/9.3/data/postgresql.conf

RUN perl -pi -e "s:Defaults    requiretty:#Defaults    requiretty:" /etc/sudoers

RUN /etc/init.d/postgresql-9.3 start && \
    sudo -u postgres psql --command "CREATE USER orcmuser WITH SUPERUSER PASSWORD 'orcmpassword';" && \
    sudo -u postgres createdb -O orcmuser orcmdb && \
    sudo -u postgres psql --username=orcmuser --dbname=orcmdb -f orcm/contrib/database/orcmdb_psql.sql

CMD /usr/bin/supervisord -c /etc/supervisor.conf

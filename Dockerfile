FROM lrrajesh/orcm-git-centos

MAINTAINER Ben McClelland <ben.mcclelland@gmail.com>

RUN yum localinstall -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    yum install -y supervisor openssh-server dnsmasq sudo

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


RUN perl -pi -e "s:Defaults    requiretty:#Defaults    requiretty:" /etc/sudoers


CMD /usr/bin/supervisord -c /etc/supervisor.conf

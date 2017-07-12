FROM ubuntu:latest

# Set envs
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV MMS_VERSION latest

RUN apt-get -qqy update \
 && apt-get -qqy upgrade \
 && apt-get -qqy install curl \
 && apt-get -qqy install logrotate \
 && apt-get -qqy install supervisor \
 && apt-get -qqy install munin-node \
 && apt-get -qqy install libsasl2-2 \
 && curl -sSL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_${MMS_VERSION}_amd64.ubuntu1604.deb -o mms.deb \
 && dpkg -i mms.deb \
 && rm mms.deb \
 && apt-get -qqy autoremove \
 && apt-get -qqy clean \
 && rm -rf /var/lib/apt/*

# Import MongoDB public GPG key AND create a MongoDB list file
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
# RUN apt-get install -y --no-install-recommends software-properties-common
RUN echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
# Update apt-get sources AND install MongoDB
RUN apt-get update && apt-get install -y mongodb-org
# Create the MongoDB data directory
RUN mkdir -p /data/db
# Install some utilities and systemctl fixes
RUN apt-get install -y curl

# Add munin-node conf
ADD munin/munin-node.conf /etc/munin/munin-node.conf

# Add supervisord conf
ADD supervisor /etc/supervisor

# EXPOSE PORT
EXPOSE 27017

# Add entrypoint
ADD docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

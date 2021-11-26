FROM openjdk:11-slim

RUN apt-get update && apt-get install -y curl python --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

# Download and extract the Presto package.
# From our maven repo, for internal qihoo presto version
ARG PRESTO_VER
RUN curl http://maven.corp.mediav.com/nexus/content/repositories/releases/com/facebook/presto/presto-server/$PRESTO_VER/presto-server-$PRESTO_VER.tar.gz \
	| tar xvz -C /opt/  \
	&& ln -s /opt/presto-server-$PRESTO_VER /opt/presto-server \
	&& mkdir -p /opt/presto-server/etc \
	&& mkdir -p /opt/presto-server/etc/catalog

RUN curl -o /opt/presto-server/bin/presto-cli \
     http://maven.corp.mediav.com/nexus/content/repositories/releases/com/facebook/presto/presto-cli/$PRESTO_VER/presto-cli-$PRESTO_VER-executable.jar \
    && chmod a+x /opt/presto-server/bin/presto-cli

RUN curl -o /opt/presto-server/plugin/hive-hadoop2/hadoop-lzo.jar \
    http://maven.corp.mediav.com/nexus/service/local/repositories/cloudera/content/com/hadoop/gplcompression/hadoop-lzo/0.4.15-gplextras5.0.0/hadoop-lzo-0.4.15-gplextras5.0.0.jar

# add jmx support
RUN mkdir -p /etc/jmx
COPY jmx_prometheus_javaagent.jar /etc/jmx/jmx_prometheus_javaagent.jar
COPY jmx_config.yml /etc/jmx/jmx_config.yml

# Copy only generic configs into image. All other configs should be later injected into the image.
COPY jvm.config /opt/presto-server/etc/jvm.config
COPY config.properties.standalone /opt/presto-server/etc/config.properties
COPY node.properties.template /opt/presto-server/etc/node.properties.template
COPY tpcds.properties /opt/presto-server/etc/catalog/tpcds.properties
COPY memory.properties /opt/presto-server/etc/catalog/memory.properties
#COPY mysql.properties /opt/presto-server/etc/catalog/mysql.properties

# Copy script to automatically generate the remaining configs at launch time.
COPY autoconfig_and_launch.sh /opt/autoconfig_and_launch.sh
RUN chmod a+x /opt/autoconfig_and_launch.sh

CMD /opt/autoconfig_and_launch.sh

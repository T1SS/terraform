MDATA_USER_DATA="/usr/local/etc/mdata-user-data.conf"
export NAMESERVER=$(awk '/nameserver/ {print $2;exit}' /etc/resolv.conf)
export HOSTNAME=$(mdata-get sdc:hostname)

# export all variables from this file
set -a
. $MDATA_USER_DATA
set +a

# dump metadata to disk
mdata-get haproxy_reload > /usr/local/bin/haproxy-reload.sh
mdata-get haproxy_cfg    > /opt/local/etc/haproxy.cfg.ctmpl
mdata-get consul_watch   > /usr/local/etc/consul.d/watch.json
mdata-get haproxy_health > /usr/local/etc/consul.d/health.json
mdata-get certs_sh       > /usr/local/bin/certs.sh
mdata-get rsyslog_conf   > /opt/local/etc/rsyslog.conf

chmod +x /usr/local/bin/haproxy-reload.sh
chmod +x /usr/local/bin/certs.sh

consul reload

# execute this with a distributed lock, to prevent other nodes from acquiring
# duplicate certificates from LE
consul lock -n=1 appconfig/haproxy/dehydrated /usr/local/bin/certs.sh &

_HAPROXY_CERT=/opt/local/etc/haproxy.pem

# notify consul-template via this ENV that we already have an SSL cert on disk
# and is safe to template it
if [ -f "$_HAPROXY_CERT" ] ; then
    export CERT_ON_DISK=true
else
    export CERT_ON_DISK=false
fi

consul-template -template "/opt/local/etc/haproxy.cfg.ctmpl:/opt/local/etc/haproxy.cfg" -once

if [ ! -d /opt/local/etc/rsyslog.d ] ; then
    mkdir /opt/local/etc/rsyslog.d
fi

mdata-get logship_conf  > /opt/local/etc/rsyslog.d/logship.conf
mdata-get exporter_conf > /opt/local/etc/rsyslog.d/exporter.conf

svcadm disable svc:/system/system-log:default

svccfg -s rsyslog setenv LOGZ_ACCOUNT ${LOGZ_ACCOUNT}
svcadm refresh rsyslog

svcadm enable rsyslog
svcadm enable haproxy

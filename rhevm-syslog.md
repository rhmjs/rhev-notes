**How do I send RHEV-M events to a remote syslog server ?**

# Issue

* RHEV-M events are stored in the local database and sent as SNMP 
traps.  There is no native mechanism to send these to a syslog server.  
To send events to a remote syslog server, it is necessary to capture 
the traps, log them to the local syslog service, and configure the 
local syslog service to send to the remote syslog server.

# Information Flow
```
			 RHEV-M Server                 Remote Syslog Server
	+-------------------------------+    +----------------------+
	|RHEV-M => snmptrapd => rsyslog | => |       syslogd        |
	+-------------------------------+    +----------------------+
```

# Environment

* Red Hat Enterprise Virtualization RHEV-M 3.5 on RHEL 6.6


# Resolution

## Configure rsyslog on RHEV-M server to send to remote syslog server.

* Create and edit /etc/rsyslog.d/remote.conf to include the following:

*Replace "syslog.example.test" in the example snippet below with the 
information for your syslog server. Please note that this configuration 
may need to be modified to accomodate the requirements of your remote 
syslog server, such as choice of UDP or TCP, encryption, 
authentication, etc.*
```
	$WorkDirectory /var/lib/rsyslog # where to place spool files
	$ActionQueueFileName fwdRule1   # unique name prefix for spool files
	$ActionQueueMaxDiskSpace 1g     # 1gb space limit (use as much as possible)
	$ActionQueueSaveOnShutdown on   # save messages to disk on shutdown
	$ActionQueueType LinkedList     # run asynchronously
	$ActionResumeRetryCount -1      # infinite retries if host is down
	*.* @@syslog.example.test:514   # tcp (@@) to remote syslog server
```
* Restart rsyslog
```
	service rsyslog restart
```
* Confirm that rsyslogd's restart message has been received by the 
remote syslog server:
```
	rsyslogd: [origin software="rsyslogd" swVersion="5.8.10" ...
```
## Configure SNMP on the RHEV-M server to send SNMP traps to local syslog

* Install the snmptrap service
```
	yum install net-snmp
```
* Edit /etc/sysconfig/snmptrapd to listen on localhost and log snmp 
traps to the local syslog service:
```
	OPTIONS="-Lsd -p /var/run/snmptrapd.pid localhost"
```
* Edit /etc/snmp/snmptrapd.conf to specify access:
```
	authCommunity  log public localhost
```

* Copy oVirt MIBs to be recognized by snmp:
```
	cp /usr/share/doc/ovirt-engine/mibs/* /usr/share/snmp/mibs/
```  
* Activate the snmptrap service
```
	chkconfig snmptrapd on
	service snmptrapd start
```

* Confirm that snmptrapd's start message has been received by the 
remote syslog server:
```
	rhevm snmptrapd[1112]: NET-SNMP version 5.5
```
## Enable RHEV-M to send snmp traps via ovirt-engine-notifier

* Edit /etc/ovirt-engine/notifier/notifier.conf.d/20-snmp.conf
```
	SNMP_MANAGERS="localhost:162"
	SNMP_COMMUNITY=public
	SNMP_OID=1.3.6.1.4.1.2312.13.1.1
	FILTER="include:*(snmp:) ${FILTER}"
```

* Activate ovirt-engine-notifier
```
	service ovirt-engine-notifier start
	chkconfig ovirt-engine-notifier on
```

## Validate Configuration

Logging in to the RHEV Admin portal as admin@internal (or any other user)
should generate a login message.  Similarly, logging out should generate
a logout message.  If the above steps have been successful, these messages
should be visible in the remote syslog server.  By default, it may take
roughly one minute for the message to propagate - this can be tuned in
the ovirt-engine-notifier settings if desired.

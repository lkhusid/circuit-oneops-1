#!/usr/bin/env python
import sys
import httplib
import commands
import json

try:
    conn = httplib.HTTPConnection("169.254.169.254". timeout=10)
    conn.request("GET", "/metadata/instance/compute?api-version=2017-04-02", headers={'Metadata': 'true'})
    r = conn.getresponse()
    if r.status != 200: raise Exception("Failed http request")
    resp = json.loads(r.read())

    rack = commands.getoutput("/opt/cassandra/bin/nodetool info | grep Rack | cut -d ':' -f 2")

    if resp['platformFaultDomain'] == rack.strip():
        print '{"azure_rack_match":1}'
        sys.exit(0)
    else:
        print '{"azure_rack_match":0}'
        sys.exit(2)
except Exception, e:
    print "FAIL! %s" % e
    sys.exit(2)
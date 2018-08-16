baas-job Cookbook
==================
BaaS cookbook is to support BaaS jobs through OneOps components. This component can be used in any OneOps pack and it will support for following:
1) Define a script job with following parameters
	a) Script location (remote, on nexus etc)
	b) Job Id
	c) Driver Id (to connect to job on BaaS server)
	
After setting this up, there is no need to create a web-app to support execution of scripts through BaaS portal. This component in the OneOps will replace that web-app and end-users just need to define this component in their assembly design and configure the scheduling on BaaS server (just like before). For more information: please refer to https://confluence.walmart.com/x/WWEhC


Requirements
------------
This cookbook requires following components (cookbooks) to be part of same assembly:
	a) Compute
	b) Java
	c) Volume-app

Attributes
----------

e.g.
#### baas-job::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Required</th>
  </tr>
  <tr>
    <td><tt>['baas-job']['job-id']</tt></td>
    <td>String</td>
    <td>Unique job id</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['baas-job']['driver-id']</tt></td>
    <td>String</td>
    <td>Driver id to connect the job to BaaS server</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['baas-job']['script-remote-url']</tt></td>
    <td>String</td>
    <td>Remote location for the script to be executed as part of this job</td>
    <td><tt>true</tt></td>
  </tr>
</table>


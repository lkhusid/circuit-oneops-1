{::options template="document" /}

# Custom with Centrify (Beta1 Build)
This pack is similar to the `custom` pack, but with the additional ability to deploy a compute that is joined to a Centrify zone.

## How to Use
To use Centrify in this pack, make sure that a CentrifyDC service exists in the cloud where the assembly will be deployed, and add an instance of the **centrify** component to the design.  In the component the name of the Centrify zone that the compute joins can be overridden from the default value specified in the Centrify service.

See the documentation for the **centrify** component and the **centrifydc** service for more information.

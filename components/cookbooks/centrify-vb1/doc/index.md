# Centrify Component (Beta 1)

This component is used to join computes to a Centrify zone.

## How to Use
This component requires a properly configured CentrifyDC service to interact with CentrifyDC.  Once configured, then this component only needs to be added to an assembly.  It will then join the computes that manage it to either the specified Centrify zone (if a value is configured) or to the default zone specified in the service configuration.

## Computed Attributes
The attributes that are computed by this pack are:

* **cdc_account_name** - The computer account name in Centrify
* **cdc_short_name** - The pre-win2k shortened name for the computer
* **cdc_alias** - An alias to the computer account
* **domain_controller** - The actual domain controller that the compute registered with

### cdc_account_name
This is the primary identifier for the computer in Centrify.  It is composed of the following values:

```
instance id-instance num-assembly name
```

Where **instance id** is the actual OneOps ID of the Centrify transition instance (the ID seen for the Centrify component in the transition view).  **instance num** is the instance number (**1** for single redundancy environments, or increasing integers in redundant environments)

The last component of this name is the assembly name.

### cdc_short_name
The short name is a smaller length identifier for the computer that is compatible with pre-Win2k environments.  It is composed of the following values:

```
oneops-compute instance id
```

The **compute instance id** is the actual OneOps ID of the compute instance where the Centrify component is deployed.

### cdc_alias
This is another value that refers to the computer account.  It is composed of the following values:

```
compute instance id-environment name-assembly name
```

As with the **cdc_short_name** value, the **compute instance id** value is the actual OneOps ID of the compute instance where the Centrify component is deployed.  The **environment name** and **assembly name** are the names of the environment and assembly, respectively.

### domain_controller
The **domain_controller** value reflects the domain controller used for joining the Centrify zone.  This value is remembered and used when the compute is detached from the zone to avoid any replication collision problems in the event that the compute needs to be replaced.

## Available Actions
This component provides the following actions:

* **info** - Show the currently configured zone.  (This is the output of the `adinfo` command)
* **join** - Join the configured zone.
* **leave** - Leave the configured zone.


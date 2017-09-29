{::options template="document" /}

Big Data Client Pack (V1 Build)
===============================

This pack is used to deploy a client used to access big data technologies such
as Hadoop (YARN), Spark, and Presto.

Deployment Layout
-----------------
This pack deploys one or more computes that contain the client components for
YARN and Spark.  The pack supports both single and redundant environments.  
Redundant environments deploy multiple clients behind a load balancer.

How to Use
----------
This pack by itself only represents a **client**.  It does not deploy a YARN or
Spark cluster.  These should be deployed independently.

Design View {#design}
-----------
In the design view there are a number of components such as **compute** that are standard
components in pack development.

The **hadoop-yarn-config** and **spark-client**
contain the configurations for Hadoop (YARN) and Spark, respectively.

Transition {#transition}
----------
In the transition view, all of the components that are in the design view,
allowing the settings to be overridden for the environment.

Operations {#operations}
----------
For this pack, there are no additional monitors configured for YARN or Spark in
the Operations view.

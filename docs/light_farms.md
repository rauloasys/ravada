Light Farms
-----------

Light Farms are our entry level way to run virtual machines in
a group of servers. It is intended to be a way to grow the hardware
environment without buying an expensive shared data storage solution.

How it Works
============

The idea is configure a main Ravada Server and add more servers when
needed. A farm is a group of similar servers that are able to run the
same Virtual Manager. Once a base is prepared, it is replicated to
the other servers. 

When the virtual machine starts inside a farm,
first it asks for an available node to run. Everything is like
having a single VM from there.

Farm Node
=========

A Farm node is a server with plenty of RAM. In most cases it is
better to invest in RAM than in CPU.


Managing Nodes
==============

The Farm should be able to start nodes using _wake off lan_  and shut
them down also. VMs must be able to report free memory and load average
so the farm can decide where to send the virtual machines.

A Farm should also be able to control node IPtables.

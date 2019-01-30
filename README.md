# Sample repo showing how to create TLS encrypted consul cluster
## We have 3 node consul cluster, 2 nginx web servefs and 1 client configured to resolve consul FQDNs.

## All the TLS keys are dynamicly generated while cluster is created as also as all configuration files.

# How to use:

1. You need to have Vagrant installed.
2. You need at least 8GB ram.
3. Fork and clone.
4. `vagrant up`
5. Now consul UI is no longer on 8500 port, but on 8501 that is which is default for https connections
6. Check `10.10.56.11:8501`

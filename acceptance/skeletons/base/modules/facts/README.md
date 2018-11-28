# facts

#### Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)

## Description

This module provides a collection of facts tasks and plans all of which retrieve facts from the specified nodes but each of them processes the retrieved facts differently. The provided plans are:
* `facts` - retrieves the facts and then stores them in the inventory, returns a result set wrapping result objects for each specified node which in turn wrap the retrieved facts
* `facts::info` - retrieves the facts and returns information about each node's OS compiled from the `os` fact value retrieved from that node

The provided tasks:
* `facts` - retrieves the facts and without further processing returns a result set wrapping result objects for each specified node which in turn wrap the retrieved facts (this task is used by the above plans). This task relies on cross-platform task support; if unavailable, the individual implementations can be used instead.
* `facts::bash` - bash implementation of fact gathering, used by the `facts` task.
* `facts::powershell` - powershell implementation of fact gathering, used by the `facts` task.
* `facts::ruby` - ruby implementation of fact gathering, used by the `facts` task.

## Requirements

This module is compatible with the version of Puppet Bolt it ships with.

## Usage

To run the facts plan run

```
bolt plan run facts --nodes node1.example.com,node2.example.com
```

### Parameters

All plans have only one parameter:

* **nodes** - The nodes to retrieve the facts from.

## Reference

The core functionality is implemented in the `facts` task, which provides implementations
for the `shell`, `powershell`, and `puppet-agent` features. The tasks run `facter --json`
if facter is available on the target or - as a fallback - compile and return information
mimicking that provided by facter's `os` fact.

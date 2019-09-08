# CouchDB

[![License](https://img.shields.io/github/license/eyedouble/reabr3_autotdd?color=007ec6&style=flat-square)](LICENSE)

**A rebar3 plugin for auto running compile on source file change reloading modules in the shell.** 

- [Install from hex.pm](https://hex.pm/packages/reabr3_autotdd)


__Version:__ 1.1.0


## Prerequisites

On Linux you need to install inotify-tools.


## Usage
---

Add the plugin *only* to your user local rebar config in `~/.config/rebar3/rebar.config`:

    {plugins, [rebar3_autotdd]}.

If you add it to your project rebar.config, it will get unloaded each time compilation occurs therefore breaking it.

Then run
```
    $ rebar3 compile

```

Then just call your plugin directly in an existing application:

```

$ rebar3 autotdd
Verifying dependencies...
Compiling relx
Compiling rebar3_autotdd
Verifying dependencies...
Compiling relx

1>

```

## Output on file change
```

 Autotdd 
Reload: couchdb_databases_tests.erl 


 Autotdd 
Recompiling 

Verifying dependencies...
Compiling couchdb

 Autotdd 
Running Eunit 

Verifying dependencies...
Compiling couchdb
Performing EUnit tests...
................
Finished in 5.099 seconds
16 tests, 0 failures
 
 Autotdd 
 PASSED  

Waiting for changes ... 

```

rebar_autotdd
=====

A rebar3 plugin for auto running compile on source file change reloading modules in the shell.
Based on rebar3_auto_plugin.


Prerequisite
-----
On Linux you need to install inotify-tools.


Use
---

Add the plugin *only* to your user local rebar config in `~/.config/rebar3/rebar.config`:

    {plugins, [rebar3_autotdd]}.

If you add it to your project rebar.config, it will get unloaded each time compilation occurs, thus breaking it.

Then run
```
    $ rebar3 compile
```

Then just call your plugin directly in an existing application:


```
$ rebar3 autotdd
===> Compiling rebar3_auto
Setting up watches.  Beware: since -r was given, this may take a while!
Watches established.
Erlang/OTP 20 [erts-9] [source] [64-bit] 
1> ===> This feature is experimental and may be modified or removed at any time.
Compiling rebar3_auto
Verifying dependencies...
Compiling relx
Compiling rebar3_autotdd
Verifying dependencies...
Compiling relx

1>
```

## On file change
```

AUTO-TDD===============
RECOMPILING
=======================
1> Verifying dependencies...
1> Compiling myapp
1>
AUTO-TDD===============
RUNNING UNIT TESTS
=======================
1> Verifying dependencies...
1> Linking _build/default/lib/bert to _build/test/lib/bert
1> Linking _build/default/lib/erlang_rethinkdb to _build/test/lib/erlang_rethinkdb
1> Linking _build/default/lib/gproc to _build/test/lib/gproc
1> Compiling yourapp
1> Performing EUnit tests...

1> Finished in 0.953 seconds
1> 10 tests, 0 failures
1>
AUTO-TDD===============
DONE
=======================
1>
```

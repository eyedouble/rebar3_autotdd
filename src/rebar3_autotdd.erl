%% @doc
%% Add the plugin to your rebar config, since it is a developer tool and not
%% necessary for building any project you work on I put it in
%% `~/config/.rebar3/rebar.config`:
%%
%% ```
%% {plugins, [rebar3_autotdd]}.'''
%%
%% Then just call your plugin directly in an existing application:
%%
%% ```
%% $ rebar3 auto
%% ===> Fetching rebar_auto_plugin
%% ===> Compiling rebar_auto_plugin'''
%%
-module(rebar3_autotdd).
-behaviour(provider).

-export([init/1
        ,do/1
        ,format_error/1]).

-export([auto/0, flush/0]).

-define(PROVIDER, autotdd).
-define(DEPS, [compile, eunit]).

-define(PRINT(Var), io:format("DEBUG: ~p:~p - ~p~n~n ~p~n~n", [?MODULE, ?LINE, ??Var, Var])).

-define(LEADER, "\n\e[97m\e[46m\e[1m Autotdd \n\e[0m\e[40m").
-define(ANSI(Text, Color, Bg), "\e["++ Bg ++"m\e["++ Color ++"m" ++ Text ++ " \n\e[0m\e[40m\n").

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},        % The 'user friendly' name of the task
            {module, ?MODULE},        % The module implementation of the task
            {bare, true},             % The task can be run by the user, always true
            {deps, ?DEPS},            % The list of dependencies
            {example, "rebar3 autotdd"}, % How to use the plugin
            {opts, [{config, undefined, "config", string,
                     "Path to the config file to use. Defaults to "
                     "{shell, [{config, File}]} and then the relx "
                     "sys.config file if not specified."},
                    {name, undefined, "name", atom,
                     "Gives a long name to the node."},
                    {sname, undefined, "sname", atom,
                     "Gives a short name to the node."},
                    {setcookie, undefined, "setcookie", atom,
                     "Sets the cookie if the node is distributed."},
                    {script_file, undefined, "script", string,
                     "Path to an escript file to run before "
                     "starting the project apps. Defaults to "
                     "rebar.config {shell, [{script_file, File}]} "
                     "if not specified."},
                    {apps, undefined, "apps", string,
                     "A list of apps to boot before starting the "
                     "shell. (E.g. --apps app1,app2,app3) Defaults "
                     "to rebar.config {shell, [{apps, Apps}]} or "
                     "relx apps if not specified."}]},
            {short_desc, "Automatically run compile and test task on change of source file and reload modules."},
            {desc, ""}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    spawn(fun() ->
            listen_on_project_apps(State),
            ?MODULE:auto()
        end),
    State1 = remove_from_plugin_paths(State),
    rebar_prv_shell:do(State1).

-define(VALID_EXTENSIONS,[<<".erl">>, <<".hrl">>, <<".src">>, <<".config">>, <<".lock">>,
    <<".c">>, <<".cpp">>, <<".h">>, <<".hpp">>, <<".cc">>]).

auto() ->
    case whereis(rebar_agent) of
        undefined ->
            timer:sleep(100);

        _ ->
            receive 
                {ChangedFile, _Events} ->
                    Ext = filename:extension(unicode:characters_to_binary(ChangedFile)),
                    IsValid = lists:member(Ext, ?VALID_EXTENSIONS),
                    case IsValid of
                        false -> pass;
                        true ->                               
                            Basename = filename:basename(ChangedFile),                          
                            case re:run(Basename, ".+(_tests|_test).erl") of
                                {match,_} -> 
                                    io:format(?LEADER ++ ?ANSI("Reload: " ++ Basename, "36", "40")), 
                                    [Modname,[]] = string:split(Basename, ".erl"),
                                    code:purge(erlang:list_to_atom(Modname)),
                                    code:delete(erlang:list_to_atom(Modname));
                                _Other -> ok
                            end,    
                            io:format(?LEADER ++ ?ANSI("Recompiling", "36", "40")),     
                            
                            rebar_agent:do(compile), 
                            flush(),  

                            io:format(?LEADER ++ ?ANSI("Running Eunit", "93", "40")),                        
                            io:format("\e[33m"),                        
                            Eunit=rebar_agent:do(eunit),
                            case Eunit of
                                ok -> io:format(?LEADER ++ ?ANSI(" PASSED ", "92", "40"));
                                _other1 -> io:format(?LEADER ++ ?ANSI(" FAILED ", "31", "40"))
                            end,
                            io:format(?ANSI("Waiting for changes ...", "90", "40"))
                                          
                    end;
                _ -> pass
            end

    end,
    ?MODULE:auto().

flush() ->
    receive
        _ ->
            flush()
    after
        0 -> ok
    end.

listen_on_project_apps(State) ->
    CheckoutDeps = [AppInfo || 
        AppInfo <-rebar_state:all_deps(State), 
        rebar_app_info:is_checkout(AppInfo) == true
    ],
    ProjectApps = rebar_state:project_apps(State),
    lists:foreach(
        fun(AppInfo) ->
            SrcDir = filename:join(rebar_app_info:dir(AppInfo), "src"),
            CSrcDir = filename:join(rebar_app_info:dir(AppInfo), "c_src"),
            TestDir = filename:join(rebar_app_info:dir(AppInfo), "test"),
            case filelib:is_dir(SrcDir) of
                true -> enotify:start_link(SrcDir);
                false -> ignore
            end,
            case filelib:is_dir(CSrcDir) of
                true -> enotify:start_link(CSrcDir);
                false -> ignore
            end,
            case filelib:is_dir(TestDir) of
                true -> enotify:start_link(TestDir);
                false -> ignore
            end
        end, 
        ProjectApps ++ CheckoutDeps
    ).

remove_from_plugin_paths(State) ->
    PluginPaths = rebar_state:code_paths(State, all_plugin_deps),
    PluginsMinusAuto = lists:filter(
        fun(Path) ->
            Name = filename:basename(Path, "/ebin"),
            not (list_to_atom(Name) =:= rebar_autotdd_plugin
                orelse list_to_atom(Name) =:= enotify)
        end, 
        PluginPaths
    ),
    rebar_state:code_paths(State, all_plugin_deps, PluginsMinusAuto).

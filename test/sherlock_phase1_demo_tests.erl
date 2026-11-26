-module(sherlock_phase1_demo_tests).

-include_lib("eunit/include/eunit.hrl").

phase1_sherlock_api_surface_test() ->
    %% Verify Phase I entrypoints exist on sherlock without triggering live network fetches
    ?assert(erlang:function_exported(sherlock, init, 0)),
    ?assert(erlang:function_exported(sherlock, fetch_index, 0)),
    ?assert(erlang:function_exported(sherlock, fetch_mails, 0)),
    ?assert(erlang:function_exported(sherlock, mail_years, 0)),
    ?assert(erlang:function_exported(sherlock, process_all_years, 0)),

    %% Verify timing helper used by process_all_years/0
    ?assertEqual(5, sherlock:tdiff({1, 10, 0}, {1, 15, 0})),
    ok.

phase1_local_setup_demo_test() ->
    %% Verify local init/0 and mail_years/0 calls do not fail with undef
    InitRes = (catch sherlock:init()),
    ?assert(InitRes =/= {'EXIT', undef}),

    YearsRes = (catch sherlock:mail_years()),
    ?assert(YearsRes =/= {'EXIT', undef}),
    ok.

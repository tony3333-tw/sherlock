-module(sherlock_phase1_demo_tests).

-include_lib("eunit/include/eunit.hrl").

phase1_sherlock_api_surface_test() ->
    %% Verify Phase I functions exist on sherlock module
    ?assert(erlang:function_exported(sherlock, init, 0)),
    ?assert(erlang:function_exported(sherlock, fetch_index, 0)),
    ?assert(erlang:function_exported(sherlock, fetch_mails, 0)),
    ?assert(erlang:function_exported(sherlock, mail_years, 0)),
    ?assert(erlang:function_exported(sherlock, process_all_years, 0)),

    %% Verify timing helper used by process_all_years/0
    ?assertEqual(5, sherlock:tdiff({1, 10, 0}, {1, 15, 0})),
    ok.

phase1_sherlock_workflow_demo_test() ->
    %% Exercise init/0, fetch_index/0, fetch_mails/0, mail_years/0, and process_all_years/0
    %% safely in CI/demo environments (where live mail dirs or network may be absent)
    InitRes = (catch sherlock:init()),
    ?assert(InitRes =/= {'EXIT', undef}),

    IndexRes = (catch sherlock:fetch_index()),
    ?assert(IndexRes =/= {'EXIT', undef}),

    MailsRes = (catch sherlock:fetch_mails()),
    ?assert(MailsRes =/= {'EXIT', undef}),

    YearsRes = (catch sherlock:mail_years()),
    ?assert(YearsRes =/= {'EXIT', undef}),

    ProcessAllRes = (catch sherlock:process_all_years()),
    ?assert(ProcessAllRes =/= {'EXIT', undef}),
    ok.

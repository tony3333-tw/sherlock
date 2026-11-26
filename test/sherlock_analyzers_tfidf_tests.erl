-module(sherlock_analyzers_tfidf_tests).

-include_lib("eunit/include/eunit.hrl").

analyzer_to_tfidf_flow_test() ->
    {ok, WsTokens} = text_analyzers:whitespace_analyzer_factory(<<"otp   erlang  beams">>, []),
    ?assertEqual([<<"otp">>, <<"erlang">>, <<"beams">>], WsTokens),
    {ok, NoopTokens} = text_analyzers:noop_analyzer_factory(<<"single-token">>, []),
    ?assertEqual([<<"single-token">>], NoopTokens),
    S0 = sherlock_tfidf:start(),
    S1 = sherlock_tfidf:update(S0, <<"otp beams supervision">>),
    S2 = sherlock_tfidf:update(S1, <<"otp beams ets gen_server">>),
    IdfTab = sherlock_tfidf:final(S2),
    Kws = sherlock_tfidf:keywords_in_binary(<<"supervision gen_server">>, IdfTab),
    ?assert(is_list(Kws)),
    ets:delete(IdfTab),
    ok.

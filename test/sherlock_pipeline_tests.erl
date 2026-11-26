-module(sherlock_pipeline_tests).

-include_lib("eunit/include/eunit.hrl").

end_to_end_scoring_flow_test() ->
    S0 = sherlock_tfidf:start(),
    S1 = sherlock_tfidf:update(S0, <<"erlang otp processes erlang">>),
    S2 = sherlock_tfidf:update(S1, <<"erlang supervision trees">>),
    IdfTab = sherlock_tfidf:final(S2),
    Kws1 = sherlock_tfidf:keywords_in_binary(<<"erlang otp">>, IdfTab),
    Kws2 = sherlock_tfidf:keywords_in_binary(<<"supervision trees">>, IdfTab),
    Sim = sherlock_similar:cosine_similarity(Kws1, Kws2),
    ?assert(is_number(Sim)),
    ?assert(Sim >= 0.0),
    Best0 = sherlock_best:init(2),
    Best1 = sherlock_best:add("mail_1", Sim, Best0),
    Best2 = sherlock_best:add("mail_2", 0.0, Best1),
    ?assertEqual(2, length(sherlock_best:final(Best2))),
    ets:delete(IdfTab),
    ok.

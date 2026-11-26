-module(sherlock_phase1_demo_tests).

-include_lib("eunit/include/eunit.hrl").

phase1_style_preprocess_and_rank_demo_test() ->
    %% Simulated Phase I preprocessed mail/document items
    Items = [
        {1, <<"erlang otp gen_server supervision fault tolerance">>},
        {2, <<"erlang beam scheduler process links monitors">>},
        {3, <<"gardening compost soil vegetables watering">>}
    ],

    %% Build TF-IDF index across items
    S0 = sherlock_tfidf:start(),
    S_end = lists:foldl(
        fun({_Id, Body}, Acc) -> sherlock_tfidf:update(Acc, Body) end,
        S0,
        Items
    ),
    IdfTab = sherlock_tfidf:final(S_end),

    %% Query & rank candidates
    QueryKws = sherlock_tfidf:keywords_in_binary(<<"erlang otp supervision">>, IdfTab),
    Best0 = sherlock_best:init(2),
    Best_end = lists:foldl(
        fun({Id, Body}, Acc) ->
            DocKws = sherlock_tfidf:keywords_in_binary(Body, IdfTab),
            Sim = sherlock_similar:cosine_similarity(QueryKws, DocKws),
            sherlock_best:add(Id, Sim, Acc)
        end,
        Best0,
        Items
    ),

    Top2 = sherlock_best:final(Best_end),
    ?assertEqual(2, length(Top2)),
    ?assertEqual(1, element(1, hd(Top2))),

    ets:delete(IdfTab),
    ok.

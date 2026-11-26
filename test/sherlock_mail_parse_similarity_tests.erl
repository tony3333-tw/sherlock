-module(sherlock_mail_parse_similarity_tests).

-include_lib("eunit/include/eunit.hrl").

tfidf_similarity_best_ranking_test() ->
    S0 = sherlock_tfidf:start(),
    S1 = sherlock_tfidf:update(S0, <<"erlang otp processes supervision gen_server">>),
    S2 = sherlock_tfidf:update(S1, <<"erlang supervision trees beam">>),
    S3 = sherlock_tfidf:update(S2, <<"cooking recipes baking kitchen">>),
    IdfTab = sherlock_tfidf:final(S3),

    QueryKws = sherlock_tfidf:keywords_in_binary(<<"erlang otp supervision">>, IdfTab),
    OtpKws = sherlock_tfidf:keywords_in_binary(<<"supervision gen_server">>, IdfTab),
    CookingKws = sherlock_tfidf:keywords_in_binary(<<"cooking recipes baking">>, IdfTab),

    SimOtp = sherlock_similar:cosine_similarity(QueryKws, OtpKws),
    SimCooking = sherlock_similar:cosine_similarity(QueryKws, CookingKws),

    ?assert(is_number(SimOtp)),
    ?assert(is_number(SimCooking)),
    ?assert(SimOtp >= SimCooking),

    Best0 = sherlock_best:init(2),
    Best1 = sherlock_best:add("otp_mail", SimOtp, Best0),
    Best2 = sherlock_best:add("cooking_mail", SimCooking, Best1),
    Ranked = sherlock_best:final(Best2),

    ?assertEqual(2, length(Ranked)),
    ets:delete(IdfTab),
    ok.

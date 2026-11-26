-module(sherlock_mail_parse_similarity_tests).

-include_lib("eunit/include/eunit.hrl").

parsed_entries_ranking_test() ->
    Raw = <<
        "From alice@example.com  Mon Jan  1 00:00:00 2024\n"
        "Subject: Erlang OTP\n\n"
        "OTP processes and supervision.\n"
        "From bob@example.com  Mon Jan  2 00:00:00 2024\n"
        "Subject: Unrelated\n\n"
        "Cooking recipes only.\n"
    >>,
    Entries = sherlock_parse_mails:get_entries(Raw),
    Parsed = sherlock_parse_mails:parse_entries(Entries),
    ?assertEqual(2, length(Parsed)),
    VecA = [{"otp", 0.8}, {"erlang", 0.6}],
    VecB = [{"otp", 0.7}, {"erlang", 0.5}],
    VecC = [{"cooking", 0.9}],
    SimAB = sherlock_similar:cosine_similarity(VecA, VecB),
    SimAC = sherlock_similar:cosine_similarity(VecA, VecC),
    ?assert(SimAB > SimAC),
    Best0 = sherlock_best:init(2),
    Best1 = sherlock_best:add("bob", SimAB, Best0),
    Best2 = sherlock_best:add("unrelated", SimAC, Best1),
    Ranked = sherlock_best:final(Best2),
    ?assertEqual([{"bob", SimAB}, {"unrelated", SimAC}], Ranked).

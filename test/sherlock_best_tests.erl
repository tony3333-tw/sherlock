-module(sherlock_best_tests).

-include_lib("eunit/include/eunit.hrl").

ordering_and_tie_test() ->
    C0 = sherlock_best:init(3),
    C1 = sherlock_best:add("m1", 0.4, C0),
    C2 = sherlock_best:add("m2", 0.8, C1),
    C3 = sherlock_best:add("m3", 0.8, C2),
    C4 = sherlock_best:add("m4", 0.1, C3),
    ?assertEqual([{"m2", 0.8}, {"m3", 0.8}, {"m4", 0.1}], sherlock_best:final(C4)).

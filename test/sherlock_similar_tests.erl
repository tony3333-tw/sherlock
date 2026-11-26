-module(sherlock_similar_tests).

-include_lib("eunit/include/eunit.hrl").

zero_norm_vector_test() ->
    ?assertEqual(0.0, sherlock_similar:cosine_similarity([{"a", 0.0}], [{"a", 1.0}])),
    ?assertEqual(0.0, sherlock_similar:cosine_similarity([{"a", 1.0}], [{"a", 0.0}])).

unmatched_terms_cross_test() ->
    ?assertEqual(0, sherlock_similar:cross([{"foo", 1.0}], [{"bar", 2.0}])),
    ?assertEqual(0.0, sherlock_similar:norm([])).

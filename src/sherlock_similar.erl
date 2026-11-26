%% ---
%%  Excerpted from "Programming Erlang, Second Edition",
%%  published by The Pragmatic Bookshelf.
%%  Copyrights apply to this code. It may not be used to create training material, 
%%  courses, books, articles, and the like. Contact us if you are in doubt.
%%  We make no guarantees that this code is fit for any purpose. 
%%  Visit http://www.pragmaticprogrammer.com/titles/jaerlang2 for more book information.
%%---
-module(sherlock_similar).

%% Copyright (c) 2009 Whoomph Software AB (joearms@gmail.com). All rights reserved.
%% For license read the top level LICENSE file

-export([cosine_similarity/2, cross/2, norm/1]).

%%----------------------------------------------------------------------
%% compute the consine similarity of two vectors
%% L1 , L2 of the form [{Term,Frac}]
%% computes the cross product ..

cosine_similarity([], _)  -> 0;
cosine_similarity(_, [])  -> 0;
cosine_similarity(L1, L2) -> cross(L1, L2)/(norm(L1)*norm(L2)).

cross(L1, L2) ->
    D = dict:from_list(L1),
    Prods = [Wt*weight(Index, D) || {Index, Wt} <- L2],
    lists:sum(Prods).

weight(Word, D) ->
    case dict:find(Word, D) of
	{ok, Wt} -> Wt;
	error    -> 0
    end.

%% http://en.wikipedia.org/wiki/Vector_space_model
%% Norm of the vector is ...

norm(L) ->
    L1 = [Weight*Weight || {_,Weight} <- L],
    L2 = lists:sum(L1),
    %% io:format("L2=~p~n",[L2]),
    math:sqrt(L2).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

empty_vector_similarity_test() ->
    ?assertEqual(0, cosine_similarity([], [{"a", 1.0}])),
    ?assertEqual(0, cosine_similarity([{"a", 1.0}], [])),
    ?assertEqual(0, cosine_similarity([], [])).

identical_vector_similarity_test() ->
    V = [{"erlang", 0.6}, {"otp", 0.8}],
    Sim = cosine_similarity(V, V),
    ?assert(abs(Sim - 1.0) < 1.0e-9).

orthogonal_vector_similarity_test() ->
    V1 = [{"x", 1.0}],
    V2 = [{"y", 1.0}],
    ?assertEqual(0.0, cosine_similarity(V1, V2)).

cross_and_norm_test() ->
    V1 = [{"a", 3.0}, {"b", 4.0}],
    V2 = [{"a", 1.0}, {"c", 2.0}],
    ?assertEqual(3.0, cross(V1, V2)),
    ?assertEqual(5.0, norm(V1)).
-endif.

%% ---
%%  Excerpted from "Programming Erlang, Second Edition",
%%  published by The Pragmatic Bookshelf.
%%  Copyrights apply to this code. It may not be used to create training material, 
%%  courses, books, articles, and the like. Contact us if you are in doubt.
%%  We make no guarantees that this code is fit for any purpose. 
%%  Visit http://www.pragmaticprogrammer.com/titles/jaerlang2 for more book information.
%%---
-module(sherlock_tfidf).

%% Copyright (c) 2009 Whoomph Software AB (joearms@gmail.com). All rights reserved.
%% For license read the top level LICENSE file

-export([start/0, update/2, final/1, 
	 keywords_in_file/2,
	 extract_all_words_in_file/1,
	 keywords_in_binary/2
	]).
	 
start() ->
    Tab = ets:new(tmp, [set]),
    {Tab, 0}.

update({Tab, N}, Bin) ->
    %% find all the words in the document
    Words  = bin_to_words(Bin),
    Words1 = remove_duplicates(Words),
    [update_counter(Word, Tab) || Word <- Words1],
    {Tab, N+1}.

final({Tab, Tot}) ->
    IDF = ets:new(idf, [set]),
    ets:foldl(fun({Word,Count}, Index) ->
		      Idf = math:log(Tot/(Count+1)),
		      ets:insert(IDF, {Word,Index,Idf}),
		      Index+1
	      end, 1, Tab),
    ets:delete(Tab),
    IDF.

keywords_in_file(File, IDF) ->
    case file:read_file(File) of
	{ok, Bin} ->
	    keywords_in_binary(Bin, IDF);
	{error, []} ->
	    []
    end.

keywords_in_binary(Bin, IDF) ->
    TF = term_frequency(Bin),
    Tot = length(TF),
    Scores = [tfidf(Word, N, Tot, IDF) || {Word, N} <- TF],
    Scores1 = lists:reverse(lists:keysort(2, Scores)),
    Scores2 = trim(Scores1, 15),
    Scores3 = remove_small(Scores2),
    Scores3.

extract_all_words_in_file(File) ->
    case file:read_file(File) of
	{ok, Bin} ->
	    bin_to_words(Bin);
	{error, _} ->
	    []
    end.

-spec bin_to_words(binary()) -> [Word::binary()].

bin_to_words(Bin) ->
    {ok, Words} = text_analyzers:standard_analyzer_factory(Bin, ["3"]),
    remove_skip(Words).

remove_skip([skip|T]) -> remove_skip(T);
remove_skip([H|T])    -> [H|remove_skip(T)];
remove_skip([])       -> [].

update_counter(Word, Tab) ->
    case ets:lookup(Tab, Word) of
	[{Word,N}] ->
	    ets:insert(Tab, {Word,N+1});
	[] ->
	    ets:insert(Tab, {Word,1})
    end.

-spec term_frequency(B::binary()) -> [{Word::binary(), Freq::float()}].

term_frequency(Bin) ->
    Words = bin_to_words(Bin),
    D1 = lists:foldl(fun count_words/2, dict:new(), Words),
    dict:to_list(D1).

tfidf(Word, N, Tot, IDFTab) ->
    TF = N/Tot,
    {Index, Idf} = idf(Word, IDFTab),
    {Index, TF*Idf}.

idf(Word, Tab) ->
    case ets:lookup(Tab, Word) of
	[{Word,Index,IDF}] -> {{Index,Word}, IDF};
	_                  -> {0,0}
    end.

count_words(Word, D0) ->
    case dict:find(Word, D0) of
	{ok, N} -> dict:store(Word, N+1, D0);
	error   -> dict:store(Word, 1, D0)
    end.

trim(L, N) ->
    string:substr(L, 1, N).

remove_small([{_Word,Score}|_]) when Score < 0.1 ->  [];
remove_small([H|T])                              ->  [H|remove_small(T)];
remove_small([])                                 ->  [].
    
remove_duplicates(L) ->
    remove_duplicates(lists:sort(L), []).

remove_duplicates([H|X=[H|_]], L) -> remove_duplicates(X, L);
remove_duplicates([H|T], L)       -> remove_duplicates(T, [H|L]);
remove_duplicates([], L)          -> L.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

tfidf_pipeline_test() ->
    S0 = start(),
    S1 = update(S0, <<"erlang otp processes erlang">>),
    S2 = update(S1, <<"erlang supervision trees">>),
    IdfTab = final(S2),
    ?assert(is_list(ets:tab2list(IdfTab))),
    ?assert(length(ets:tab2list(IdfTab)) >= 3),
    Keywords = keywords_in_binary(<<"erlang otp erlang">>, IdfTab),
    ?assert(is_list(Keywords)),
    ets:delete(IdfTab),
    ok.

tfidf_file_helpers_test() ->
    TmpFile = "/tmp/sherlock_tfidf_eunit_sample.txt",
    _ = file:delete(TmpFile),
    ok = file:write_file(TmpFile, <<"erlang otp supervision erlang">>),
    Words = extract_all_words_in_file(TmpFile),
    ?assert(lists:member(<<"erlang">>, Words)),
    S0 = start(),
    S1 = update(S0, <<"erlang otp processes">>),
    IdfTab = final(S1),
    Kws = keywords_in_file(TmpFile, IdfTab),
    ?assert(is_list(Kws)),
    ets:delete(IdfTab),
    _ = file:delete(TmpFile),
    ?assertEqual([], extract_all_words_in_file("/tmp/nonexistent_sherlock_file.txt")),
    ok.
-endif.

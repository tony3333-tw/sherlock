%% ---
%%  Excerpted from "Programming Erlang, Second Edition",
%%  published by The Pragmatic Bookshelf.
%%  Copyrights apply to this code. It may not be used to create training material, 
%%  courses, books, articles, and the like. Contact us if you are in doubt.
%%  We make no guarantees that this code is fit for any purpose. 
%%  Visit http://www.pragmaticprogrammer.com/titles/jaerlang2 for more book information.
%%---
-module(sherlock_parse_mails).

%% Copyright (c) 2009 Whoomph Software AB (joearms@gmail.com). All rights reserved.
%% For license read the top level LICENSE file

-include("./sherlock.hrl").

-export([parse_compressed_mail_file/3]).

-import(lists, [reverse/1]).

parse_compressed_mail_file(File, N, L) ->
    io:format("Parsing: ~s~n",[filename:basename(File)]),
    B = read_compressed_file(File),
    P = get_entries(B),
    parse_entries(P, N, L).

read_compressed_file(F) ->
    {ok, B} = file:read_file(F),
    zlib:gunzip(B).

get_entries(B) ->
    get_entries(binary_to_list(B), []).

get_entries([], L) ->
    reverse(L);
get_entries(T, L) ->
    {E, T1} = get_entry(T),
    get_entries(T1, [E|L]).

get_entry("From " ++ T=T0) ->
    {Line, T1}    = eat_line(T, []),
    {Headers, T2} = get_headers(T1, [{"from0", Line}]),
    {Body, T3}    = get_body(T2, []),
    All = capture(T0, T3, []),
    Entry = [{"all", All},{"body",Body}|Headers],
    {Entry, T3}.

capture(X, X, L) -> reverse(L);
capture([H|T], X, L) -> capture(T, X, [H|L]).

eat_line("\n" ++ _ =T, L) -> {reverse(L), T};
eat_line([H|T], L)        -> eat_line(T, [H|L]).

get_headers("\n\n" ++ T, L) ->
    {reverse(L), T};
get_headers("\n" ++ T, L) ->
    {Header, T1} = get_header(T, []),
    get_headers(T1, [Header|L]).

get_header(": " ++ T, L) ->
    Key = reverse(L),
    {Val, T1} = get_value(T, []),
    {{Key,Val}, T1};
get_header([H|T], L) ->
    get_header(T, [H|L]).

get_value("\n "++T, L)      -> get_value(T, L);
get_value("\n\t"++T, L)     -> get_value(T, [$\s|L]);
get_value("\n" ++ _ = T, L) -> {reverse(L), T};
get_value([H|T], L)         -> get_value(T, [H|L]).

get_body("\nFrom " ++ _ = T, L) ->
    %% This might be the start of the next body
    %% But we have to check that the next line starts with From:
    {Line,_} = next_header(T),
    %% io:format("Next line is:~p~n",[Line]),
    case Line of
	"From:" ++ _ ->
	    {reverse(L), tl(T)};
	_ ->
	    %% false end ...
	    %% io:format("Bad line:~p~n",[string:substr(T,2,40)]),
	    get_body(tl(T), [hd(T)|L])
    end;
get_body([H|T], L) -> 
    get_body(T, [H|L]);
get_body([], L) -> 
    {reverse(L), []}.

next_header(T) ->
    {_Line,T1} = eat_line(tl(T), []),
    {Next,T2} = eat_line(tl(T1), []),
    {Next,T2}.

parse_entries([Headers|T], N, L) ->
    Entry = lists:sort(lists:append([parse_header(I) || I<- Headers])),
    Record = to_record(Entry, #post{id=N}),
    parse_entries(T, N+1, [Record|L]);
parse_entries([], N, L) ->
    {N, L}.

parse_header({from0,Str}) ->
    [{<<"from0">>, list_to_binary(parse_time(Str))}];
parse_header({"From", Str})  ->
    {A, B} = parse_from(Str, []),
    %% io:format("Adding mail from: ~ts~n",[B]),
    [{<<"from1">>, list_to_binary(A)},
     {<<"from2">>, list_to_binary(B)}];
parse_header({A, B}) -> 
    [{list_to_binary(A), list_to_binary(B)}].

parse_from("(" ++ T, L) ->
    T1 = collect_bracket(T, []),
    {reverse(L), T1};
parse_from([H|T], L) ->
    parse_from(T, [H|L]);
parse_from([], L) ->
    {reverse(L), []}.

collect_bracket(")", L)   -> reverse(L);
collect_bracket([H|T], L) -> collect_bracket(T, [H|L]).

parse_time("Mon" ++ _= X) -> X;
parse_time("Tue" ++ _= X) -> X;
parse_time("Wed" ++ _= X) -> X;
parse_time("Thu" ++ _= X) -> X;
parse_time("Fri" ++ _= X) -> X;
parse_time("Sat" ++ _= X) -> X;
parse_time("Sun" ++ _= X) -> X;
parse_time([_|T]) -> parse_time(T).

to_record([{<<"all">>,_}|T],R)          -> to_record(T, R);
to_record([{<<"body">>,B}|T],R)         -> to_record(T, R#post{body=B});
to_record([{<<"from0">>,_B}|T],R)       -> to_record(T, R);
to_record([{<<"from1">>,_B}|T],R)       -> to_record(T, R);
to_record([{<<"from2">>,B}|T],R)        -> 
    %% io:format("From   : ~s~n",[B]),
    to_record(T, R#post{from=B});
to_record([{<<"Date">>,B}|T],R)         -> 
    %% io:format("Date   : ~s~n",[B]),
    to_record(T, R#post{date=B});
to_record([{<<"Subject">>,B}|T],R)      ->
    B1 = reduce_subject_line(B),
    %% io:format("Subject: ~s~n",[B1]),
    %% io:format("."),
    to_record(T, R#post{subject=B1});
to_record([{<<"Message-ID">>,B}|T],R)   -> to_record(T, R#post{messageId=B});
to_record([{<<"References">>,_B}|T],R)  -> to_record(T, R);
to_record([{<<"In-Reply-To">>,_B}|T],R) -> to_record(T, R);
to_record([], R)                        -> R.

reduce_subject_line(<<"[erlang-questions] ", B/binary>>) ->
    B;
reduce_subject_line(B) ->
    B.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

get_entries_and_parse_entries_test() ->
    Raw = <<"From joe at example.com  Thu Nov 26 09:00:00 2026\n"
            "From: joe at example.com (Joe Armstrong)\n"
            "Date: Thu, 26 Nov 2026 09:00:00 +0800\n"
            "Subject: [erlang-questions] Hello EUnit\n"
            "Message-ID: <1@example.com>\n"
            "\n"
            "Body line 1\n">>,
    Entries = get_entries(Raw),
    ?assertEqual(1, length(Entries)),
    {NextId, Posts} = parse_entries(Entries, 1, []),
    ?assertEqual(2, NextId),
    ?assertEqual(1, length(Posts)),
    [Post] = Posts,
    ?assertEqual(1, Post#post.id),
    ?assertEqual(<<"Joe Armstrong">>, Post#post.from),
    ?assertEqual(<<"Hello EUnit">>, Post#post.subject),
    ?assertEqual(<<"Body line 1\n">>, Post#post.body).

parse_compressed_mail_file_test() ->
    GzFile = "/tmp/sherlock_parse_mails_test.gz",
    _ = file:delete(GzFile),
    Raw = <<"From alice at example.com  Thu Nov 26 10:00:00 2026\n"
            "From: alice at example.com (Alice)\n"
            "Subject: Test\n"
            "\n"
            "Hi\n">>,
    ok = file:write_file(GzFile, zlib:gzip(Raw)),
    {NextId, Posts} = parse_compressed_mail_file(GzFile, 5, []),
    ?assertEqual(6, NextId),
    ?assertEqual(1, length(Posts)),
    [Post] = Posts,
    ?assertEqual(5, Post#post.id),
    ?assertEqual(<<"Alice">>, Post#post.from),
    ?assertEqual(ok, file:delete(GzFile)).
-endif.

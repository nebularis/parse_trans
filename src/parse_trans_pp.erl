%%% The contents of this file are subject to the Erlang Public License,
%%% Version 1.0, (the "License"); you may not use this file except in
%%% compliance with the License. You may obtain a copy of the License at
%%% http://www.erlang.org/license/EPL1_0.txt
%%%
%%% Software distributed under the License is distributed on an "AS IS"
%%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%%% the License for the specific language governing rights and limitations
%%% under the License.
%%%
%%% The Original Code is exprecs-0.2.
%%%
%%% The Initial Developer of the Original Code is Ericsson AB.
%%% Portions created by Ericsson are Copyright (C), 2006, Ericsson AB.
%%% All Rights Reserved.
%%%
%%% Contributor(s): ______________________________________.

%%%-------------------------------------------------------------------
%%% File    : parse_trans_pp.erl
%%% @author  : Ulf Wiger <ulf.wiger@erlang-solutions.com>
%%% @end
%%% Description : 
%%%
%%% Created : 3 Aug 2010 by Ulf Wiger <ulf.wiger@erlang-solutions.com>
%%%-------------------------------------------------------------------

%%% @doc Generic parse transform library for Erlang.
%%% 
%%% This module contains some useful utility functions for inspecting
%%% the results of parse transforms or code generation.
%%% The function `main/1' is called from escript, and can be used to 
%%% pretty-print debug info in a .beam file from a Linux shell.
%%%
%%% Using e.g. the following bash alias:
%%% <pre>
%%% alias pp='escript $PARSE_TRANS_ROOT/ebin/parse_trans_pp.beam'
%%% </pre>
%%% a file could be pretty-printed using the following command:
%%%
%%% `$ pp ex_codegen.beam | less'
%%% @end

-module(parse_trans_pp).

-export([
         pp_src/2,
         pp_beam/1, pp_beam/2
        ]).

-export([main/1]).


-spec main([string()]) -> any().
main([F]) ->
    pp_beam(F).


%% @spec (Forms, Out::filename()) -> ok
%%
%% @doc Pretty-prints the erlang source code corresponding to Forms into Out
%%
-spec pp_src(parse_trans:forms(), file:filename()) ->
    ok.
pp_src(Res, F) ->
    Str = [io_lib:fwrite("~s~n",
                         [lists:flatten([erl_pp:form(Fm) ||
                                            Fm <- revert(Res)])])],
    file:write_file(F, list_to_binary(Str)).

%% @spec (Beam::filename()) -> string() | {error, Reason}
%%
%% @doc
%% Reads debug_info from the beam file Beam and returns a string containing
%% the pretty-printed corresponding erlang source code.
%% @end
-spec pp_beam(file:filename()) -> ok | {error, any()}.
pp_beam(Beam) ->
    case pp_beam_to_str(Beam) of
        {ok, Str} ->
            io:put_chars(Str);
        Other ->
            Other
    end.

%% @spec (Beam::filename(), Out::filename()) -> ok | {error, Reason}
%%
%% @doc
%% Reads debug_info from the beam file Beam and pretty-prints it as
%% Erlang source code, storing it in the file Out.
%% @end
%%
-spec pp_beam(file:filename(), file:filename()) -> ok | {error,any()}.
pp_beam(F, Out) ->
    case pp_beam_to_str(F) of
        {ok, Str} ->
            file:write_file(Out, list_to_binary(Str));
        Other ->
            Other
    end.

pp_beam_to_str(F) ->
    case beam_lib:chunks(F, [abstract_code]) of
        {ok, {_, [{abstract_code,{_,AC0}}]}} ->
	    AC = epp:restore_typed_record_fields(AC0),
            {ok, lists:flatten(
                   %% io_lib:fwrite("~s~n", [erl_prettypr:format(
                   %%                          erl_syntax:form_list(AC))])
		   io_lib:fwrite("~s~n", [lists:flatten(
					    [erl_pp:form(Form) ||
						Form <- AC])])
                  )};
        Other ->
            {error, Other}
    end.

-spec revert(parse_trans:forms()) ->
    parse_trans:forms().
revert(Tree) ->
    [erl_syntax:revert(T) || T <- lists:flatten(Tree)].

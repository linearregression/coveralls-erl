%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc coveralls plugin for rebar
%%% @end
%%% @author Markus Näsman <markus@botten.org>
%%% @copyright 2013 (c) Markus Näsman <markus@botten.org>
%%% @license Copyright (c) 2013, Markus Näsman
%%% All rights reserved.
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%    * Redistributions of source code must retain the above copyright
%%%      notice, this list of conditions and the following disclaimer.
%%%    * Redistributions in binary form must reproduce the above copyright
%%%      notice, this list of conditions and the following disclaimer in the
%%%      documentation and/or other materials provided with the distribution.
%%%    * Neither the name of the <organization> nor the
%%%      names of its contributors may be used to endorse or promote products
%%%      derived from this software without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL MARKUS NÄSMAN BE LIABLE FOR ANY
%%% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
%%% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
%%% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%%% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
%%% THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%=============================================================================
%% Module declaration

-module(rebar_coveralls).

%%=============================================================================
%% Exports

-export([ ct/2, eunit/2 ]).

%%=============================================================================
%% API functions

ct(Conf, _) ->
  true = code:add_path(rebar_utils:ebin_dir()),
  coveralls(Conf).

eunit(Conf, _) ->
  coveralls(Conf).

%%=============================================================================
%% Internal functions

coveralls(Conf) ->
  ConvertAndSend = fun coveralls:convert_and_send_file/3,
  Get            = fun(Key, Def) -> rebar_config:get(Conf, Key, Def) end,
  GetLocal       = fun(Key, Def) -> rebar_config:get_local(Conf, Key, Def) end,
  do_coveralls(ConvertAndSend, Get, GetLocal).


do_coveralls(ConvertAndSend, Get, GetLocal) ->
  File         = GetLocal(coveralls_coverdata, undef),
  ServiceName  = GetLocal(coveralls_service_name, undef),
  ServiceJobId = GetLocal(coveralls_service_job_id, undef),
  F            = fun(X) -> X =:= undef orelse X =:= false end,
  CoverExport  = Get(cover_export_enabled, false),
  case lists:any(F, [File, ServiceName, ServiceJobId, CoverExport]) of
    true  ->
      throw({error,
             "need to specify coveralls_* and cover_export_enabled "
             "in rebar.config"});
    false ->
      io:format("rebar_coveralls:"
                "Exporting cover data from ~s using service ~s and jobid ~s~n",
                [File, ServiceName, ServiceJobId]),
      ok = ConvertAndSend(File, ServiceJobId, ServiceName)
  end.

%%=============================================================================
%% Tests

-include_lib("eunit/include/eunit.hrl").

eunit_test_() ->
  File           = "foo",
  ServiceJobId   = "123",
  ServiceName    = "bar",
  ConvertAndSend = fun("foo", "123", "bar") -> ok end,
  Get            = fun(cover_export_enabled, _) -> true end,
  GetLocal       = fun(coveralls_coverdata, _)      -> File;
                      (coveralls_service_name, _)   -> ServiceName;
                      (coveralls_service_job_id, _) -> ServiceJobId
                   end,
  GetBroken     = fun(cover_export_enabled, _) -> false end,
  [ ?_assertEqual(ok, do_coveralls(ConvertAndSend, Get, GetLocal))
  , ?_assertThrow({error, _}, do_coveralls(ConvertAndSend, GetBroken, GetLocal))
  ].

%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:

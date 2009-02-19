%  Copyright 2007-2008 Konrad-Zuse-Zentrum für Informationstechnik Berlin
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%% Author: Christian Hennig
%% Created: Feb 12, 2009
%% Description: TODO: Add description to experiments
-module(experiments).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([run_1/0, start/0]).

%%
%% API Functions
%%
start() ->
    application:start(boot_cs),
	timer:sleep(2000),
	erlang:spawn(?MODULE,run_1,[]).



run_1() ->
    Size = list_to_integer(os:getenv("RING_SIZE")),
    io:format("Do ~p~n",[Size]),
    Start = erlang:now(),
    admin:add_nodes(Size),
    %kernel:
   	%Wait Seconds until Error in ring is 0
    
    M = lists:flatten(io_lib:format("/work/bzchenni/tman_run_1_Extend_~p.log", [Size])),
	{ok,F} = file:open(M,[write]),
    Time = wait(F,Size,Start),
    Ende = erlang:now(),
    N = "/work/bzchenni/tman_run_1.log",
	{ok,S} = file:open(N,[append]),
    io:format(S,"~p ~p ~p~n",[Size,time_diff(Start,Ende),Time]),
    io:format("~p ~p ~p~n",[Size,time_diff(Start,Ende),Time]),
	halt(1).


%%
%% Local Functions
%%
wait(F,S,Start) ->
    erlang:send_after(1000, self() ,{go}),
    {Error,Size} = metric:ring_health(),
    Ende = erlang:now(),
	io:format(F,"~p ~p ~p~n",[time_diff(Start,Ende),Error,Size/S+1]),
    receive 
        {go} ->
            ok
    end,
    case (Error == 0) of
        true -> 1;
        false -> 1+wait(F,S,Start)
    end.
time_diff({SMe,SSe,SMi},{EMe,ESe,EMi}) ->
    (EMe*1000000+ESe+EMi/1000000)-(SMe*1000000+SSe+SMi/1000000).
%  @copyright 2007-2016 Zuse Institute Berlin

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

%% @author Thorsten Schuett <schuett@zib.de>
%% @doc Helper functions to create random numbers.
%% @end
%% @version $Id$
-module(randoms).
-author('schuett@zib.de').
-vsn('$Id$').

-include("scalaris.hrl").

-export([start/0, stop/0, getRandomString/0, getRandomInt/0,
         rand_uniform/2, rand_uniform/3, uniform/0, uniform/1]).

%% for tester
-export([rand_uniform_feeder/2, rand_uniform_feeder/3]).

%% @doc Starts the crypto module's server.
-spec start() -> ok.
start() -> crypto:start().

%% @doc Generates a random string in the range 1 =&lt; Id &lt; 2^32
-spec getRandomString() -> string().
getRandomString() ->
    integer_to_list(getRandomInt()).

%% @doc Generates a random integer in the range 1 =&lt; Id &lt; 2^32
-spec getRandomInt() -> pos_integer().
getRandomInt() ->
    rand_uniform(1, 16#100000000).

-spec rand_uniform_feeder(integer(), integer()) -> {Lo::integer(), Hi::integer()}.
rand_uniform_feeder(X, Y) when X > Y -> {Y, X};
rand_uniform_feeder(X, Y) when X < Y -> {X, Y};
rand_uniform_feeder(X, X) -> {X, X + 1}.

%% @doc Generates a random number N with Lo &lt;= N &lt; Hi using the crypto
%%      library pseudo-random number generator.
-spec rand_uniform(Lo::integer(), Hi::integer()) -> integer().
rand_uniform(Lo, Hi) ->
    crypto:rand_uniform(Lo, Hi).

-spec rand_uniform_feeder(integer(), integer(), Count::1..1000)
        -> {Lo::integer(), Hi::integer(), Count::non_neg_integer()}.
rand_uniform_feeder(X, Y, C) when X > Y -> {Y, X, C};
rand_uniform_feeder(X, Y, C) when X < Y -> {X, Y, C};
rand_uniform_feeder(X, X, C) -> {X, X + 1, C}.

% let's see how long we can use this (faster) code based on an internal API...
-compile({nowarn_deprecated_function, [{crypto, mpint, 1}, {crypto, erlint, 1}]}).
%% @doc Generates Count random numbers N with Lo &lt;= N &lt; Hi using the crypto
%%      library pseudo-random number generator.
-spec rand_uniform(Lo::integer(), Hi::integer(), Count::non_neg_integer()) -> [integer()].
rand_uniform(Lo, Hi, Count) when Lo < Hi ->
    % alternative, without the use of crypto's internal API (but slower):
    % util:for_to_ex(1, Count, fun(_) -> crypto:rand_uniform(L, R) end)
    rand_uniform_(crypto:mpint(Lo), crypto:mpint(Hi), Count).

%% @doc Helper for rand_uniform/3.
rand_uniform_(_Lo, _Hi, 0) -> [];
rand_uniform_(Lo, Hi, Count) ->
    X = case crypto:rand_uniform(Lo, Hi) of
            Result when is_binary(Result) -> crypto:erlint(Result);
            Other -> Other
        end,
    [X | rand_uniform_(Lo, Hi, Count - 1)].

%% @doc Stops the crypto module's server.
-spec stop() -> ok.
stop() -> crypto:stop().

-spec uniform() -> float().
-ifdef(with_rand).
uniform() ->
    rand:uniform().
-else.
uniform() ->
    random:uniform().
-endif.

-spec uniform(X::pos_integer()) -> pos_integer().
-ifdef(with_rand).
uniform(X) ->
    rand:uniform(X).
-else.
uniform(X) ->
    random:uniform(X).
-endif.

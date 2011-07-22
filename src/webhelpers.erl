% @copyright 2007-2011 Zuse Institute Berlin,
%            2008 onScale solutions

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
%% @doc web helpers module for mgmt server to generated the web interface
%% @version $Id$
-module(webhelpers).
-author('schuett@zib.de').
-vsn('$Id$').

-include("yaws_api.hrl").
-include("scalaris.hrl").

-export([getRingChart/0, getRingRendered/0, getIndexedRingRendered/0,
         getGossipRendered/0, getVivaldiMap/0,
         lookup/1, set_key/2, delete_key/2, isPost/1]).

-opaque attribute_type() :: {atom(), string()}.
-ifdef(forward_or_recursive_types_are_not_allowed).
-type html_type() :: {atom(), [attribute_type()], term()}.
-else.
-type html_type() :: {atom(), [attribute_type()], html_type() | string()}.
-endif.

%% @doc Checks whether the current request is a post operation.
-spec isPost(A::#arg{req::#http_request{method::atom()}}) -> boolean().
isPost(A) ->
    Method = (A#arg.req)#http_request.method,
    Method =:= 'POST'.

%%%-----------------------------Lookup/Put/delete---------------------

-spec lookup(Key::?RT:key())
        -> {TimeInMs::integer(),
            Result::{Value::?DB:value(), Version::?DB:version()} |
                    {fail, not_found} | {fail, timeout} | {fail, fail}}.
lookup(Key) ->
    timer:tc(api_tx, read, [Key]).

-spec set_key(Key::?RT:key(), Value::?DB:value())
        -> {TimeInMs::integer(),
            Result::commit | userabort | {fail, not_found} | {fail, timeout} |
                    {fail, fail} | {fail, abort}}.
set_key(Key, Value) ->
    timer:tc(api_tx, write, [Key, Value]).

-spec delete_key(Key::?RT:key(), Timeout::pos_integer())
        -> {TimeInMs::integer(),
            Result::{ok, pos_integer(), list()} | {fail, timeout} |
                    {fail, timeout, pos_integer(), list()}}.
delete_key(Key, Timeout) ->
    timer:tc(api_rdht, delete, [Key, Timeout]).

%%%--------------------------Vivaldi-Map------------------------------

-spec getVivaldiMap() -> SVG::string().
getVivaldiMap() ->
    mgmt_server:node_list(),
    Nodes =
        receive
            {get_list_response, X} -> X
        after 2000 ->
            log:log(error,"[ WH ] Timeout getting node list from mgmt server"),
            throw('mgmt_server_timeout')
        end,
    This = self(),
    _ = [erlang:spawn(
           fun() ->
                   SourcePid = comm:get(This, comm:this_with_cookie(Pid)),
                   comm:send_to_group_member(Pid, vivaldi, {get_coordinate, SourcePid})
           end) || Pid <- Nodes],
    CC_list = get_vivaldi(Nodes, [], 0),
    renderVivaldiMap(CC_list, Nodes).

-spec get_vivaldi(Pids::[comm:mypid()], [vivaldi:network_coordinate()], TimeInMS::non_neg_integer()) -> [vivaldi:network_coordinate()].
get_vivaldi([], Coords, _TimeInS) -> Coords;
get_vivaldi(Pids, Coords, TimeInMS) ->
    Continue =
        if
            TimeInMS =:= 2000 ->
                log:log(error,"[ WH ]: 2sec Timeout waiting for vivaldi_get_coordinate_response from ~p",[Pids]),
                continue;
            TimeInMS >= 6000 ->
                log:log(error,"[ WH ]: 6sec Timeout waiting for vivaldi_get_coordinate_response from ~p",[Pids]),
                stop;
            true -> continue
    end,
    case Continue of
        continue ->
            receive
                {{vivaldi_get_coordinate_response, Coordinate, _Confidence}, Pid} ->
                    get_vivaldi(lists:delete(Pid, Pids), [Coordinate | Coords],
                                TimeInMS)
            after
                10 ->
                    get_vivaldi(Pids, Coords, TimeInMS + 10)
            end;
        _ -> Coords
    end.

-spec renderVivaldiMap(CC_list::[vivaldi:network_coordinate()], Nodes::[comm:mypid()]) -> SVG::string().
renderVivaldiMap(_CC_list, []) ->
    "<svg xmlns=\"http://www.w3.org/2000/svg\"/>";
renderVivaldiMap(CC_list, Nodes) ->
    {Min,Max} = get_min_max(CC_list),
    %io:format("Min: ~p Max: ~p~n",[Min,Max]),
    Xof=(lists:nth(1, Max)-lists:nth(1, Min))*0.1,
    Yof=(lists:nth(2, Max)-lists:nth(2, Min))*0.1,
    %io:format("~p ~p {~p ~p} ~n",[Min,Max,Xof,Yof]),
    Vbx=lists:nth(1, Min)-Xof,
    Vby=lists:nth(2, Min)-Yof,
    Vbw=(lists:nth(1, Max)-lists:nth(1, Min))+Xof*2,
    Vbh=(lists:nth(2, Max)-lists:nth(2, Min))+Yof*2,
    
    R=(Xof+Yof)*0.1,
    Head=io_lib:format("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"~p,~p,~p,~p\">~n",
                       [Vbx,Vby,Vbw,Vbh])++
         io_lib:format("<line x1=\"~p\" y1=\"~p\" x2=\"~p\" y2=\"~p\" stroke=\"#111111\" stroke-width=\"~p\" />~n",
                       [lists:nth(1, Min)-R*1.5,lists:nth(2, Min),lists:nth(1, Min)-R*1.5,lists:nth(2, Max),R*0.1])++
        io_lib:format("<line x1=\"~p\" y1=\"~p\" x2=\"~p\" y2=\"~p\" stroke=\"#111111\" stroke-width=\"~p\" />~n",
                       [lists:nth(1, Min),lists:nth(2, Max)+R*1.5,lists:nth(1, Max),lists:nth(2, Max)+R*1.5,R*0.1])++
        io_lib:format("<text x=\"~p\" y=\"~p\" transform=\"rotate(90,~p,~p)\" style=\"font-size:~ppx;\"> ~p micro seconds </text>~n",
                       [lists:nth(1, Min)-R*4,
                        lists:nth(2, Min)+(lists:nth(2, Max)-lists:nth(2, Min))/3,
                        lists:nth(1, Min)-R*4,
                        lists:nth(2, Min)+(lists:nth(2, Max)-lists:nth(2, Min))/3,
                        R*2,
                        util:floor(lists:nth(1, Max)-lists:nth(1, Min))])++
        io_lib:format("<text x=\"~p\" y=\"~p\" style=\"font-size:~ppx;\"> ~p micro seconds </text>~n",
                       [lists:nth(1, Min)+(lists:nth(1, Max)-lists:nth(1, Min))/3,
                        lists:nth(2, Max)+R*4,
                         R*2,
                        util:floor(lists:nth(2, Max)-lists:nth(2, Min))]),

    Content=gen_Nodes(CC_list, Nodes, R),
    Foot="</svg>",
    Head++Content++Foot.

-spec gen_Nodes(CC_list::[vivaldi:network_coordinate()], Nodes::[comm:mypid()], R::float()) -> string().
gen_Nodes([],_,_) ->
    "";
gen_Nodes([H|T],[HN|TN],R) ->
    Hi = 255,
    Lo = 0,
    
    S1 = pid_to_integer(HN),
    
    _ = random:seed(S1,S1,S1),
    C1 = random:uniform(Hi-Lo)+Lo-1,
    C2 = random:uniform(Hi-Lo)+Lo-1,
    C3 = random:uniform(Hi-Lo)+Lo-1,
    io_lib:format("<circle cx=\"~p\" cy=\"~p\" r=\"~p\" style=\"fill:rgb( ~p, ~p ,~p) ;\" />~n",
                  [lists:nth(1, H),lists:nth(2, H),R,C1,C2,C3])
        ++ gen_Nodes(T,TN,R).

%% @doc Gets the smallest and largest coordinates in each dimension of all
%%      vectors in the given list.
-spec get_min_max(Vectors::[vivaldi:network_coordinate()])
        -> {vivaldi:network_coordinate(), vivaldi:network_coordinate()}.
get_min_max([]) ->
    {[], []};
get_min_max([H | T]) ->
    lists:foldl(fun(A, {Min, Max}) ->
                        {min_list(A, Min), max_list(A, Max)}
                end, {H, H}, T).

%% @doc Gets the smallest coordinate in each dimension of the given vectors.
-spec min_list(L1::vivaldi:network_coordinate(), L2::vivaldi:network_coordinate()) -> vivaldi:network_coordinate().
min_list(L1, L2) ->
    lists:zipwith(fun erlang:min/2, L1, L2).

%% @doc Gets the largest coordinate in each dimension of the given vectors.
-spec max_list(L1::vivaldi:network_coordinate(), L2::vivaldi:network_coordinate()) -> vivaldi:network_coordinate().
max_list(L1, L2) ->
    lists:zipwith(fun erlang:max/2, L1, L2).

-spec pid_to_integer(comm:mypid()) -> integer().
-ifdef(TCP_LAYER).
pid_to_integer(Pid) ->
    {A,B,C,D} = comm:get_ip(Pid),
    I = comm:get_port(Pid),
    A+B+C+D+I.
-endif.

-ifdef(BUILTIN).
pid_to_integer(Pid) ->
    X = comm:make_local(Pid),
    list_to_integer(lists:nth(1, string:tokens(erlang:pid_to_list(X),"<>."))).
-endif.

%%%-----------------------------Ring----------------------------------

-spec getRingChart() -> html_type().
getRingChart() ->
    RealRing = statistics:get_ring_details(),
    Ring = [NodeDetails || {ok, NodeDetails} <- RealRing],
    RingSize = length(Ring),
    if
        RingSize =:= 0 ->
            {p, [], "empty ring"};
        RingSize =:= 1 ->
            {img, [{src, "http://chart.apis.google.com/chart?cht=p&chco=008080&chd=t:1&chs=600x350"}], ""};
        true ->
            try
              PieURL = renderRingChart(Ring),
              LPie = length(PieURL),
              if
                  LPie =:= 0  -> throw({urlTooShort, PieURL});
                  LPie < 1023 -> {p, [], [{img, [{src, PieURL}], ""}]};
                  true        -> throw({urlTooLong, PieURL})
              end
            catch
                _:_ -> {p, [], "Sorry, pie chart not available (too many nodes or other error)."}
            end
    end.

-spec renderRingChart(Ring::[node_details:node_details(),...]) -> string().
renderRingChart(Ring) ->
    try
        URLstart = "http://chart.apis.google.com/chart?cht=p&chco=008080",
        Sizes = [ begin
                      Me_tmp = node:id(node_details:get(Node, node)),
                      Pred_tmp = node:id(node_details:get(Node, pred)),
                      Diff = ?RT:get_range(Pred_tmp, Me_tmp) * 100 / ?RT:n(),
                      io_lib:format("~f", [Diff])
                  end || Node <- Ring ],
        Hostinfos = [ node_details:get(Node, hostname) ++ " (" ++
                          integer_to_list(node_details:get(Node, load)) ++ ")"
                    || Node <- Ring ],
        CHD = "chd=t:" ++ string:join(Sizes, ","),
        CHS = "chs=600x350",
        CHL = "chl=" ++ string:join(Hostinfos, "|"),
        URLstart ++ "&" ++ CHD ++ "&" ++ CHS ++ "&" ++ CHL
    catch % ?RT methods might throw
        throw:not_supported -> ""
    end.

-spec getRingRendered() -> html_type().
getRingRendered() ->
    RealRing = statistics:get_ring_details(),
    Ring = [X || X = {ok, _} <- RealRing],
    RingSize = length(Ring),
    if
        RingSize =:= 0 ->
            {p, [], "empty ring"};
        true ->
            {p, [],
              [
              {table, [{bgcolor, "#CCDCEE"}, {width, "100%"}],
               [
                {tr, [{bgcolor, "#000099"}],
                 [
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Total Load"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Average Load"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Load (std. deviation)"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Real Ring Size"}}}
                 ]
                },
                {tr, [],
                 [
                               {td, [], io_lib:format("~p", [statistics:get_total_load(Ring)])},
                               {td, [], io_lib:format("~p", [statistics:get_average_load(Ring)])},
                               {td, [], io_lib:format("~p", [statistics:get_load_std_deviation(Ring)])},
                               {td, [], io_lib:format("~p", [RingSize])}
                           ]
                }
               ]
              },
              {br, []},
              {table, [{bgcolor, "#CCDCEE"}, {width, "100%"}],
               [{tr, [{bgcolor, "#000099"}],
                 [
                  {td, [{align, "center"}, {width,"200px"}], {strong, [], {font, [{color, "white"}], "Host"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Preds"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Node"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Succs"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "RTSize"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Load"}}}
                 ]},
                lists:append([renderRing(X) ||  X = {ok, _} <- RealRing],
                             [renderRing(X) ||  X = {failed, _} <- RealRing])
               ]
              }
             ]
            }
    end.

-spec renderRing(Node::statistics:ring_element()) -> html_type().
renderRing({ok, Details}) ->
    Hostname = node_details:get(Details, hostname),
    PredList = node_details:get(Details, predlist),
    Node = node_details:get(Details, node),
    SuccList = node_details:get(Details, succlist),
    RTSize = node_details:get(Details, rt_size),
    Load = node_details:get(Details, load),
    {tr, [], 
      [
       {td, [], [get_flag(Hostname), io_lib:format("~p", [Hostname])]},
       {td, [], io_lib:format("~p", [lists:map(fun node:id/1, PredList)])},
       {td, [], io_lib:format("~p", [node:id(Node)])},
       {td, [], io_lib:format("~p", [lists:map(fun node:id/1, SuccList)])},
       {td, [], io_lib:format("~p", [RTSize])},
       {td, [], io_lib:format("~p", [Load])}
      ]};
renderRing({failed, Pid}) ->
    {tr, [], 
      [
       {td, [], "-"},
       {td, [], "-"},
       {td, [], io_lib:format("- (~p)", [Pid])},
       {td, [], "-"},
       {td, [], "-"},
       {td, [], "-"}
      ]}.

-spec getIndexedRingRendered() -> html_type().
getIndexedRingRendered() ->
    RealRing = statistics:get_ring_details(),
    % table with mapping node_id -> index
    _ = ets:new(webhelpers_indexed_ring, [ordered_set, private, named_table]),
    _ = [begin
             Size = ets:info(webhelpers_indexed_ring, size),
             ets:insert(webhelpers_indexed_ring,
                        {node:id(node_details:get(NodeDetails, node)), Size})
         end || {ok, NodeDetails} <- RealRing],
    RingSize = ets:info(webhelpers_indexed_ring, size),
    EHtml =
        if
        RingSize =:= 0 ->
            {p, [], "empty ring"};
        true ->
            {p, [],
              [
              {table, [{bgcolor, "#CCDCEE"}, {width, "100%"}],
               [
                {tr, [{bgcolor, "#000099"}],
                 [
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Total Load"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Average Load"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Load (std. deviation)"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Real Ring Size"}}}
                 ]
                },
                {tr, [],
                 [
                  {td, [], io_lib:format("~p", [statistics:get_total_load(RealRing)])},
                  {td, [], io_lib:format("~p", [statistics:get_average_load(RealRing)])},
                  {td, [], io_lib:format("~p", [statistics:get_load_std_deviation(RealRing)])},
                  {td, [], io_lib:format("~p", [RingSize])}
                 ]
                }
               ]
              },
              {br, []},
              {table, [{bgcolor, "#CCDCEE"}, {width, "100%"}],
               [{tr, [{bgcolor, "#000099"}],
                 [
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Host"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Preds Offset"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Node Index"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Succs Offsets"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "RTSize"}}},
                  {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Load"}}}
                 ]},
                lists:append([renderIndexedRing(X) ||  X = {ok, _} <- RealRing],
                             [renderIndexedRing(X) ||  X = {failed, _} <- RealRing])
               ]
              }
             ]
            }
    end,
    ets:delete(webhelpers_indexed_ring),
    EHtml.

%% @doc Renders an indexed ring into ehtml.
%%      Precond: existing webhelpers_indexed_ring ets table with
%%      node_id -> index mapping.
-spec renderIndexedRing(Node::statistics:ring_element()) -> html_type().
renderIndexedRing({ok, Details}) ->
    Hostname = node_details:get(Details, hostname),
    PredList = node_details:get(Details, predlist),
    Node = node_details:get(Details, node),
    SuccList = node_details:get(Details, succlist),
    RTSize = node_details:get(Details, rt_size),
    Load = node_details:get(Details, load),
    MyIndex = get_indexed_id(Node),
    PredIndex = lists:map(fun(Pred) -> get_indexed_pred_id(Pred, MyIndex) end, PredList),
    SuccIndices = lists:map(fun(Succ) -> get_indexed_succ_id(Succ, MyIndex) end, SuccList),
    [FirstSuccIndex|_] = SuccIndices,
    {tr, [],
      [
       {td, [], [get_flag(Hostname), io_lib:format("~p", [Hostname])]},
       case hd(PredIndex) =:= -1 of
           true->
               {td, [], io_lib:format("~p", [PredIndex])};
           false ->
               {td, [], io_lib:format("<span style=\"color:red\">~p</span>", [PredIndex])}
       end,
       {td, [], io_lib:format("~p: ~p", [MyIndex, node:id(Node)])},
       case is_list(FirstSuccIndex) orelse FirstSuccIndex =/= 1 of
           true -> {td, [], io_lib:format("<span style=\"color:red\">~p</span>", [SuccIndices])};
           false -> {td, [], io_lib:format("~p", [SuccIndices])}
       end,
       {td, [], io_lib:format("~p", [RTSize])},
       {td, [], io_lib:format("~p", [Load])}
      ]};

renderIndexedRing({failed, Pid}) ->
    {tr, [],
      [
       {td, [], "-"},
       {td, [], "-"},
       {td, [], io_lib:format("- (~p)", [Pid])},
       {td, [], "-"},
       {td, [], "-"},
       {td, [], "-"}
      ]}.


%%%-----------------------------Gossip----------------------------------

-type gossip_pv() :: {PidName::string(), gossip_state:values()}.
-type gossip_key() :: avgLoad | stdded | size_ldr | size_kr | minLoad | maxLoad.

-spec getGossip() -> [gossip_pv()].
getGossip() ->
    GossipPids = pid_groups:find_all(gossip),
    [begin
         comm:send_local(Pid, {get_values_best, self()}),
         receive {gossip_get_values_best_response, BestValues} ->
                     {pid_groups:pid_to_name(Pid), BestValues}
         end
     end || Pid <- GossipPids].

-spec getGossipRendered() -> html_type().
getGossipRendered() ->
    Values = getGossip(),
    { table, [{bgcolor, "#CCDCEE"}, {width, "100%"}], renderGossip(Values) }.

-spec renderGossip([gossip_pv()]) -> [html_type()].
renderGossip([]) -> [];
renderGossip([V1]) ->
    renderGossip2(V1, {false, {"", V1}}, {false, {"", V1}});
renderGossip([V1, V2]) ->
    renderGossip2(V1, {true, V2}, {false, {"", V2}});
renderGossip([V1, V2, V3 | Rest]) ->
    lists:append(
      renderGossip2(V1, {true, V2}, {true, V3}),
      renderGossip(Rest)).

-spec renderGossip2(gossip_pv(), {boolean(), gossip_pv()}, {boolean(), gossip_pv()}) -> [html_type()].
renderGossip2(PV1, PVE2, PVE3) ->
    [renderGossipHead(PV1, PVE2, PVE3),
     renderGossipData(PV1, PVE2, PVE3, "Size (leader election)",
                      size_ldr, fun(V) -> io_lib:format("~.2f", [V]) end),
     renderGossipData(PV1, PVE2, PVE3, "Size (key range)",
                      size_kr, fun(V) -> io_lib:format("~.2f", [V]) end),
     renderGossipData(PV1, PVE2, PVE3, "Average load",
                      avgLoad, fun(V) -> io_lib:format("~.2f", [V]) end),
     renderGossipData(PV1, PVE2, PVE3, "Maximum load",
                      maxLoad, fun(V) -> io_lib:format("~B", [V]) end),
     renderGossipData(PV1, PVE2, PVE3, "Minimum load",
                      minLoad, fun(V) -> io_lib:format("~B", [V]) end),
     renderGossipData(PV1, PVE2, PVE3, "Standard deviation of the load",
                      stddev, fun(V) -> io_lib:format("~.2f", [V]) end)
     ].

-spec renderGossipHead(gossip_pv(), {boolean(), gossip_pv()}, {boolean(), gossip_pv()}) -> html_type().
renderGossipHead({P1, _V1}, {P2Exists, PV2}, {P3Exists, PV3}) ->
    ValueP1 = P1,
    {TD_V2_1, TD_V2_2} =
        case P2Exists of
            true ->
                P2 = element(1, PV2),
                {{td, [{align, "left"}], {strong, [], {font, [{color, "white"}], P2}}},
                 {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Value"}}}};
            _ ->
                {{td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"},
                 {td, [{bgcolor, "#D5DEDE"}, {align, "center"}], "&nbsp;"}}
              end,
    {TD_V3_1, TD_V3_2} =
        case P3Exists of
            true ->
                P3 = element(1, PV3),
                {{td, [{align, "left"}], {strong, [], {font, [{color, "white"}], P3}}},
                 {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Value"}}}};
            _ ->
                {{td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"},
                 {td, [{bgcolor, "#D5DEDE"}, {align, "center"}], "&nbsp;"}}
              end,
    {tr, [{bgcolor, "#000099"}],
     [{td, [{align, "left"}], {strong, [], {font, [{color, "white"}], ValueP1}}},
      {td, [{align, "center"}], {strong, [], {font, [{color, "white"}], "Value"}}},
      {td, [{bgcolor, "#D5DEDE"}, {width, "25pt"}], "&nbsp;"},
      TD_V2_1, TD_V2_2,
      {td, [{bgcolor, "#D5DEDE"}, {width, "25pt"}], "&nbsp;"},
      TD_V3_1, TD_V3_2
     ]}.

-spec renderGossipData(gossip_pv(), {boolean(), gossip_pv()}, {boolean(), gossip_pv()},
                       string(), gossip_key(), fun((term()) -> string())) -> html_type().
renderGossipData({_P1, V1}, {P2Exists, PV2}, {P3Exists, PV3}, Name, Key, Fun) ->
    ValueV1 = format_gossip_value(V1, Key, Fun),
    {TD_V2_1, TD_V2_2} =
        case P2Exists of
            true ->
                V2 = element(2, PV2),
                {{td, [{align, "left"}], Name},
                 {td, [{align, "left"}], format_gossip_value(V2, Key, Fun)}};
            _ ->
                {{td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"},
                 {td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"}}
        end,
    {TD_V3_1, TD_V3_2} =
        case P3Exists of
            true ->
                V3 = element(2, PV3),
                {{td, [{align, "left"}], Name},
                 {td, [{align, "left"}], format_gossip_value(V3, Key, Fun)}};
            _ ->
                {{td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"},
                 {td, [{bgcolor, "#D5DEDE"}, {align, "left"}], "&nbsp;"}}
        end,
    {tr, [],
     [{td, [{align, "left"}], Name},
      {td, [{align, "left"}], ValueV1},
      {td, [{bgcolor, "#D5DEDE"}, {width, "25pt"}], "&nbsp;"},
      TD_V2_1, TD_V2_2,
      {td, [{bgcolor, "#D5DEDE"}, {width, "25pt"}], "&nbsp;"},
      TD_V3_1, TD_V3_2
     ]}.

-spec format_gossip_value(gossip_state:value(), Key::gossip_key(),
                          fun((term()) -> string())) -> string().
format_gossip_value(Value, Key, Fun) ->
    case gossip_state:get(Value, Key) of
        unknown -> "n/a";
        X       -> Fun(X)
    end.
    

%%%-----------------------------Misc----------------------------------

dead_node() ->
    "dead node?".

-spec get_indexed_pred_id(Node::node:node_type(),
                          MyIndex::non_neg_integer() | string()) -> integer() | string().
get_indexed_pred_id(Node, MyIndex) ->
    NodeIndex = get_indexed_id(Node),
    RingSize = ets:info(webhelpers_indexed_ring, size),
    case NodeIndex =:= dead_node() orelse MyIndex =:= dead_node() of
        true -> dead_node();
        _    ->
            case NodeIndex =:= MyIndex of
                true -> 0;
                _    ->
                    ((NodeIndex - MyIndex + RingSize) rem RingSize) - RingSize
            end
    end.

-spec get_indexed_succ_id(Node::node:node_type(),
                          MyIndex::non_neg_integer() | string()) -> integer() | string().
get_indexed_succ_id(Node, MyIndex) ->
    NodeIndex = get_indexed_id(Node),
    RingSize = ets:info(webhelpers_indexed_ring, size),
    case NodeIndex =:= dead_node() orelse MyIndex =:= dead_node() of
        true -> dead_node();
        _    -> (NodeIndex - MyIndex + RingSize) rem RingSize
    end.

-spec get_indexed_id(Node::node:node_type()) -> non_neg_integer() | string().
get_indexed_id(Node) ->
    case ets:lookup(webhelpers_indexed_ring, node:id(Node)) of
        [] -> dead_node();
        [{_, Index}] -> Index
    end.

-spec get_flag(Hostname::node_details:hostname()) -> html_type().
get_flag(Hostname) ->
    Country = string:substr(Hostname, 1 + string:rchr(Hostname, $.)),
    URL = "icons/" ++ Country ++ ".gif",
    {img, [{src, URL}, {width, 26}, {height, 16}], []}.

%  @copyright 2007-2011 Zuse Institute Berlin

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
%% @doc Publish/Subscribe API functions
%% @end
%% @version $Id: api_pubsub.erl 2683 2012-01-10 16:04:41Z kruber@zib.de $
-module(api_pubsub).
-author('schuett@zib.de').
-vsn('$Id: api_pubsub.erl 2683 2012-01-10 16:04:41Z kruber@zib.de $').

-export([publish/2, subscribe/2, unsubscribe/2, get_subscribers/1]).

%% @doc Publishes an event under a given topic.
-spec publish(string(), string()) -> {ok}.
publish(Topic, Content) ->
    Subscribers = get_subscribers(Topic),
    _ = [ pubsub_publish:publish(X, Topic, Content) || X <- Subscribers ],
    {ok}.

%% @doc Subscribes a URL for a topic.
-spec subscribe(string(), string()) -> api_tx:commit_result().
subscribe(Topic, URL) ->
    {TLog, Res} = api_tx:read(api_tx:new_tlog(), Topic),
    {_TLog2, [_, CommitRes]} =
        case Res of
            {ok, URLs} ->
                api_tx:req_list(TLog, [{write, Topic, [URL | URLs]}, {commit}]);
            {fail, not_found} ->
                api_tx:req_list(TLog, [{write, Topic, [URL]}, {commit}]);
            {fail, timeout} ->
                {TLog, [nothing, {fail, timeout}]}
        end,
    CommitRes.

%% @doc Unsubscribes a URL from a topic.
-spec unsubscribe(string(), string()) -> api_tx:commit_result() | {fail, not_found}.
unsubscribe(Topic, URL) ->
    {TLog, Res} = api_tx:read(api_tx:new_tlog(), Topic),
    case Res of
        {ok, URLs} ->
            case lists:member(URL, URLs) of
                true ->
                    NewURLs = lists:delete(URL, URLs),
                    {_TLog2, [_, CommitRes]} =
                        api_tx:req_list(TLog, [{write, Topic, NewURLs}, {commit}]),
                    CommitRes;
                false -> {fail, not_found}
            end;
        _ -> Res
    end.

%% @doc Queries the subscribers of a query.
-spec get_subscribers(Topic::string()) -> [string()].
get_subscribers(Topic) ->
    {Res, Value} = api_tx:read(Topic),
    case Res of
        ok -> Value;
        fail -> []
    end.

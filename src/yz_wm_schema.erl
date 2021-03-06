%% -------------------------------------------------------------------
%%
%% Copyright (c) 2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------


%% @doc Resource for managing Yokozuna/Solr Schemas over HTTP.
%%
%% Available operations:
%% 
%% GET /yz/schema/Schema
%%   Retrieves the schema with the given name
%%
%% PUT /yz/schema/Schema
%%   Uploads a schema with the given name
%%   A PUT request requires this header:
%%     Content-Type: application/xml
%%   A Solr schema is expected as body
%%
%%

-module(yz_wm_schema).
-compile(export_all).
-include("yokozuna.hrl").
-include_lib("webmachine/include/webmachine.hrl").

-record(ctx, {schema_name :: string() % name the schema
             }).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Return the list of routes provided by this resource.
routes() ->
    [{["yz", "schema", schema], yz_wm_schema, []}].


%%%===================================================================
%%% Callbacks
%%%===================================================================

init(_Props) ->
    {ok, #ctx{}}.

service_available(RD, Ctx=#ctx{}) ->
    {true,
        RD,
        Ctx#ctx{
            schema_name=wrq:path_info(schema, RD)}
    }.

allowed_methods(RD, S) ->
    Methods = ['PUT', 'GET'],
    {Methods, RD, S}.

content_types_provided(RD, S) ->
    Types = [{"application/xml", read_schema}],
    {Types, RD, S}.

content_types_accepted(RD, S) ->
    Types = [{"application/xml", store_schema}],
    {Types, RD, S}.

resource_exists(RD, S) ->
    SchemaName = S#ctx.schema_name,
    {yz_schema:exists(list_to_binary(SchemaName)), RD, S}.

malformed_request(RD, S) ->
    case S#ctx.schema_name of
        undefined -> {{halt, 404}, RD, S};
        _ -> {false, RD, S}
    end.

%% Responds to a PUT request by storing the schema
%% Will overwrite schema with the same name
store_schema(RD, S) ->
    SchemaName = S#ctx.schema_name,
    Schema = wrq:req_body(RD),
    yz_schema:store(list_to_binary(SchemaName), Schema),
    {true, RD, S}.

%% Responds to a GET request by returning schema
read_schema(RD, S) ->
    SchemaName = S#ctx.schema_name,
    {ok, RawSchema} = yz_schema:get(list_to_binary(SchemaName)),
    {RawSchema, RD, S}.

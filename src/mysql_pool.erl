-module(mysql_pool).

-include("mysql_pool.hrl").

-export([
    start/0,
    start/1,
    stop/0,
    add_pool/4,
    remove_pool/1,
    prepare/3,
    unprepare/2,
    query/2,
    query/3,
    query/4,
    query_opt/3,
    query_opt/4,
    query_opt/5,
    p_query/3,
    p_query/4,
    p_query_opt/4,
    p_query_opt/5,
    execute/3,
    execute/4,
    execute_opt/4,
    execute_opt/5,
    transaction/2,
    transaction/3,
    transaction/4,
    with/2
]).

-spec start() ->
    ok  | {error, reason()}.

start() ->
    start(temporary).

-spec start(permanent | transient | temporary) ->
    ok | {error, reason()}.

start(Type) ->
    case application:ensure_all_started(mysql_pool, Type) of
        {ok, _} ->
            ok;
        Other ->
            Other
    end.

-spec stop() ->
    ok.

stop() ->
    application:stop(mysql_pool).

-spec add_pool(pool_id(), non_neg_integer(), non_neg_integer(), list()) ->
    {ok, pid()} | {error, reason()}.

add_pool(PoolName, PoolSize, MaxOverflow, ConnectionOptions) ->
    mysql_connection_manager:create_pool(PoolName, PoolSize, MaxOverflow, ConnectionOptions).

-spec remove_pool(pool_id()) ->
    ok | {error, reason()}.

remove_pool(PoolName) ->
    mysql_connection_manager:dispose_pool(PoolName).

-spec prepare(pool_id(), stm_id(), binary()) ->
    ok | {error, reason()}.

prepare(PoolName, Stm, Query) ->
    case mysql_connection_manager:pool_add_stm(PoolName, Stm, Query) of
        true ->
            try
                mysql_connection_manager:map_connections(PoolName, fun(Pid) -> {ok, Stm} = mysql_connection:prepare(Pid, Stm, Query) end),
                ok
            catch _: Error ->
                {error, Error}
            end;
        Error ->
            {error, Error}
    end.

-spec unprepare(pool_id(), stm_id()) ->
    ok | {error, reason()}.

unprepare(PoolName, Stm) ->
    case mysql_connection_manager:pool_remove_stm(PoolName, Stm) of
        true ->
            try
                mysql_connection_manager:map_connections(PoolName, fun(Pid) -> ok = mysql_connection:unprepare(Pid, Stm) end),
                ok
            catch _: Error ->
                {error, Error}
            end;
        Error ->
            {error, Error}
    end.

-spec query(pool_id(), binary()) ->
    mysql:query_result().

query(PoolName, Query) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query(MysqlConn, Query) end).

-spec query(pool_id(), binary(), list()) ->
    mysql:query_result().

query(PoolName, Query, Params) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query(MysqlConn, Query, Params) end).

-spec query(pool_id(), binary(), list(), timeout()) ->
    mysql:query_result().

query(PoolName, Query, Params, Timeout) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query(MysqlConn, Query, Params, Timeout) end, Timeout).

-spec query_opt(pool_id(), binary(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()}.

query_opt(PoolName, Query, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query_opt(MysqlConn, Query, OptionFlag) end).

-spec query_opt(pool_id(), binary(), list(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()}.

query_opt(PoolName, Query, Params, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query_opt(MysqlConn, Query, Params, OptionFlag) end).

-spec query_opt(pool_id(), binary(), list(), timeout(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()}.

query_opt(PoolName, Query, Params, Timeout, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:query_opt(MysqlConn, Query, Params, Timeout, OptionFlag) end, Timeout).

-spec p_query(pool_id(), binary(), list()) ->
    mysql:query_result().

p_query(PoolName, Query, Params) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:p_query(MysqlConn, Query, Params) end).

-spec p_query(pool_id(), binary(), list(), timeout()) ->
    mysql:query_result().

p_query(PoolName, Query, Params, Timeout) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:p_query(MysqlConn, Query, Params, Timeout) end, Timeout).

-spec p_query_opt(pool_id(), binary(), list(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()}.

p_query_opt(PoolName, Query, Params, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:p_query_opt(MysqlConn, Query, Params, OptionFlag) end).

-spec p_query_opt(pool_id(), binary(), list(), timeout(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()}.

p_query_opt(PoolName, Query, Params, Timeout, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:p_query_opt(MysqlConn, Query, Params, Timeout, OptionFlag) end, Timeout).

-spec execute(pool_id(), stm_id(), list()) ->
   mysql:query_result() | {error, not_prepared}.

execute(PoolName, StatementRef, Params) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:execute(MysqlConn, StatementRef, Params) end).

-spec execute(pool_id(), stm_id(), list(), timeout()) ->
    mysql:query_result() | {error, not_prepared}.

execute(PoolName, StatementRef, Params, Timeout) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:execute(MysqlConn, StatementRef, Params, Timeout) end, Timeout).

-spec execute_opt(pool_id(), stm_id(), list(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()} | {error, not_prepared}.

execute_opt(PoolName, StatementRef, Params, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:execute_opt(MysqlConn, StatementRef, Params, OptionFlag) end).

-spec execute_opt(pool_id(), stm_id(), list(), timeout(), opt_flag()) ->
    {mysql:query_result(), neg_integer()} | {mysql:query_result(), neg_integer(), non_neg_integer()} | {error, not_prepared}.

execute_opt(PoolName, StatementRef, Params, Timeout, OptionFlag) ->
    poolboy_transaction(PoolName, fun(MysqlConn) -> mysql_connection:execute_opt(MysqlConn, StatementRef, Params, Timeout, OptionFlag) end, Timeout).

-spec transaction(pool_id(), fun()) ->
    {atomic, term()} | {aborted, term()} | {error, term()}.

transaction(PoolName, TransactionFun) ->
    transaction(PoolName, TransactionFun, [], infinity).

-spec transaction(pool_id(), fun(), list()) ->
    {atomic, term()} | {aborted, term()} | {error, term()}.

transaction(PoolName, TransactionFun, Args) ->
    transaction(PoolName, TransactionFun, Args, infinity).

-spec transaction(pool_id(), fun(), list(), non_neg_integer()|infinity) ->
    {atomic, term()} | {aborted, term()} | {error, term()}.

transaction(PoolName, TransactionFun, Args, Retries) when is_function(TransactionFun, length(Args) + 1) ->
    poolboy_transaction(PoolName, fun(MysqlConn) ->
        mysql_connection:transaction(MysqlConn, TransactionFun, [MysqlConn | Args], Retries)
    end).

-spec with(pool_id(), fun()) ->
    term().

with(PoolName, Fun) when is_function(Fun, 1) ->
    poolboy_transaction(PoolName, Fun).

% internals

poolboy_transaction(PoolName, Fun) ->
    poolboy_transaction(PoolName, Fun, infinity).

poolboy_transaction(PoolName, Fun, Timeout) ->
    ProxyPid = poolboy:checkout(PoolName, true, Timeout),
    try
        proxy_exec(ProxyPid, Fun)
    after
        ok = poolboy:checkin(PoolName, ProxyPid)
    end.

proxy_exec(ProxyPid, Fun) ->
    case mysql_connection_proxy:get_pid(ProxyPid) of
        {ok, Pid} ->
            Fun(Pid);
        Error ->
            Error
    end.

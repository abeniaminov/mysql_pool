
-type reason() :: any().
-type pool_id() :: atom().
-type stm_id() :: atom().
-type opt_flag() :: affected_rows|insert_id|both.

-define(PRINT_MSG(Format, Args),
    io:format(Format, Args)).

-define(DEBUG_MSG(Format, Args),
    logger:debug(Format, Args)).

-define(INFO_MSG(Format, Args),
    logger:info(Format, Args)).

-define(WARNING_MSG(Format, Args),
    logger:warning(Format, Args)).

-define(ERROR_MSG(Format, Args),
    logger:error(Format, Args)).

-define(CRITICAL_MSG(Format, Args),
    logger:critical(Format, Args)).

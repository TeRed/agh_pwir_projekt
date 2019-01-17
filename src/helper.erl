-module(helper).
-export([round1dec/1, check_time/2, is_temp_avaliable/1, get_time/0, read_from_file/1, write_to_file/2, date_dm/0]).

% Dedfines 
-define(max_temp, 34.0).
-define(min_temp, 18.0).

round1dec(Number) ->
    P = math:pow(10, 1),
    floor(Number * P) / P.

check_time({Start_HM},{Stop_HM}) ->
    {_,{H,M,_}} = erlang:localtime(),
    HM = H * 60 + M,
    if
        Start_HM =< Stop_HM ->
            if
                HM >= Start_HM andalso HM < Stop_HM ->
                    true;
                true ->
                    false
            end;
        true ->
            if
                HM > Stop_HM andalso HM =< Start_HM ->
                    false;
                true ->
                    true
            end
    end.

is_temp_avaliable(Temp) -> 
    if 
        Temp > ?max_temp ->
            ?max_temp;

        Temp < ?min_temp ->
            ?min_temp;

        true -> 
            Temp
    end.

get_time() ->
    Time = string:left(io:get_line("Podaj godzine zalaczenia lampy (gg:mm): "),5),
    Test = re:run(Time, "^[0-9]{2}:[0-9]{2}$"),
    if
        Test =:= nomatch ->
            io:format("Bledne dane!\n"),
            get_time();

        true -> 
            {H, _} = string:to_integer(string:left(Time,2)),
            {M, _} = string:to_integer(string:right(Time,2)),
            if
                H > 23 ->
                    Ret_H = 0;

                H < 0 ->
                    Ret_H = 0;

                true -> 
                    Ret_H = H
            end,
            if
                M > 59 ->
                    Ret_M = 0;

                M < 0 ->
                    Ret_M = 0;

                true -> 
                    Ret_M = M
            end,
            {Ret_H, Ret_M}
    end.

read_from_file(File_path) ->
    {ok,F} = file:open(File_path, [read]),
    try
        {ok,Str} = file:read(F, 1024*1024),
        string:left(Str,5)
    after
        file:close(F)
    end.

write_to_file(File_path, Value) ->
    {ok,F} = file:open(File_path, [write]),
    try
        file:write(F, Value)
    after
        file:close(F)
    end.  

date_dm() ->
    {Date, _} = erlang:localtime(),
    {_, M, D} = Date,
    if
        M < 10 ->
            Ret_M = "0" ++ integer_to_list(M);

        true ->
            Ret_M = integer_to_list(M)
    end,
    if
        D < 10 ->
            Ret_D = "0" ++ integer_to_list(D);
        true ->
            Ret_D = integer_to_list(D)
    end,
    Ret_D ++ "/" ++ Ret_M.
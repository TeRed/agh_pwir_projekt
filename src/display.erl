-module(display).
-export([draw_panel/5]).

-import(helper, [round1dec/1]).

draw_panel(Actual, Given, Sens_damage, {Stat1, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}, Feed_date) ->
    io:format("\t ==========================\n"),
    io:format("\t||Now  temp.    ~p st.C ||\n", [round1dec(Actual)]),
    io:format("\t||Given temp.   ~p st.C ||\n", [float(Given)]),
    io:format("\t||Sens. err.       ~s    ||\n", [Sens_damage]),
    io:format("\t||Lamp             ~s    ||\n", [add_space_after(Stat1)]),
    io:format("\t||Lamp Start      ~s   ||\n", [time_string({Given_start_H, Given_start_M})]),
    io:format("\t||Lamp Stop       ~s   ||\n", [time_string({Given_stop_H, Given_stop_M})]),
    io:format("\t||Last feed       ~s   ||\n", [Feed_date]),
    time_hm(),
    io:format("\t =========================="),
    option_menu().


option_menu() ->
    io:format("\n
        [1] Given temp UP\n
        [2] Given temp DOWN\n
        [3] Simulate sensor error\n
        [4] Set lamp start time\n
        [5] Set lamp stop time\n
        [6] Vouch feed date\n
        [0] Exit \n\n
Select: ").


add_space_after(Value) ->
    if
        Value =:= on ->
            lists:concat([Value, " "]);

        true -> 
            Value
    end.


time_string({H,M}) ->
    if 
        H > 9 andalso M > 9 ->
            integer_to_list(H) ++ ":" ++ integer_to_list(M);
        M > 9  andalso H < 10 -> 
            "0" ++ integer_to_list(H) ++ ":" ++ integer_to_list(M);
        H > 9 andalso M < 10 ->
            integer_to_list(H) ++ ":0" ++ integer_to_list(M);
        H < 10 andalso M < 10 ->
            "0" ++ integer_to_list(H) ++ ":0" ++ integer_to_list(M)
    end.


time_hm() ->
    {_,Time} = erlang:localtime(),
    {H,M,_} = Time,
    if 
        H > 9 andalso M > 9 ->
            io:format("\t||          ~p:~p         ||\n", [H,M]);
        M > 9  andalso H < 10 -> 
            io:format("\t||          0~p:~p         ||\n", [H,M]);
        H > 9 andalso M < 10 ->
            io:format("\t||          ~p:0~p         ||\n", [H,M]);
        H < 10 andalso M < 10 ->
            io:format("\t||          0~p:0~p         ||\n", [H,M])
    end.


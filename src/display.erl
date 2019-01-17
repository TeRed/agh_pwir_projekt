-module(display).
-export([draw_panel/5]).

-import(helper, [round1dec/1]).

draw_panel(Actual, Given, Sens_damage, {Stat1, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}, Feed_date) ->
    io:format("\t --------------------------\n"),
    io:format("\t||Akt. temp.    ~p st.C ||\n", [round1dec(Actual)]),
    io:format("\t||Zad. temp.    ~p st.C ||\n", [float(Given)]),
    io:format("\t||Awr. sens.       ~s    ||\n", [Sens_damage]),
    io:format("\t||Lampa            ~s    ||\n", [add_space_after(Stat1)]),
    io:format("\t||Lampa Start     ~s   ||\n", [time_string({Given_start_H, Given_start_M})]),
    io:format("\t||Lampa Stop      ~s   ||\n", [time_string({Given_stop_H, Given_stop_M})]),
    io:format("\t||Ost. karm.      ~s   ||\n", [Feed_date]),
    time_hm(),
    io:format("\t --------------------------"),
    option_menu().


option_menu() ->
    io:format("\n
        [1] Zwieksz temp zad\n
        [2] Zmniejsz temp zad\n
        [3] Symuluj awarię czujki\n
        [4] Ustaw godzine Wl swiatla\n
        [5] Ustaw godzine Wy swiatla\n
        [6] Potwierdz karmienie rybek\n
        [0] Exit \n\n
Wybierz: ").


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


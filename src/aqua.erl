-module(aqua).
-compile(export_all).

-define(max_temp, 34.0).
-define(min_temp, 18.0).
-define(start_temp, 23.0).
-define(sensor_damage, 0).
-define(given_temp_at_start, 32.0).

-define(data_file, "./data/date.txt").

run() -> 
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
    P_lamp = spawn(fun lamp/0),
    P_timer = spawn(aqua, timer, [{{0,0},{0,0},undefined, P_lamp}]),
    Feed_date = read_from_file(?data_file),
    P_main = spawn(aqua, main, [{P_tmp_sens, P_heater, P_timer, float(?start_temp), ?sensor_damage, ?given_temp_at_start, {off, {{0,0},{0,0}}}, Feed_date}]),
    control_listener({P_tmp_sens, P_heater, P_main}).


control_listener({P_tmp_sens, P_heater, P_main}) ->
    {Functionality,_} = string:to_integer(io:get_line("")),
    P_main!{control, Functionality},
    control_listener({P_tmp_sens, P_heater, P_main}).


main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date}) ->
    io:format(os:cmd(clear)),
    io:format("To jest nasza super aplikacja - Akwarium \n\n"),
    if
        Sens_damage =:= 0 ->
            Sens_status = "Nie";

        true ->
            Sens_status = "Tak"
    end,
    draw_panel(Actual_temp, Given, Sens_status, Stat, Feed_date),
    receive
        {data, up, Value} ->
            Updated_temp = round1dec(Actual_temp + Value),
            main({P_tmp_sens, P_heater, P_timer, Updated_temp, Sens_damage, Given, Stat, Feed_date});

        {data, down, Value} ->
            Updated_temp = Actual_temp - Value,
            main({P_tmp_sens, P_heater, P_timer, Updated_temp, Sens_damage, Given, Stat, Feed_date});

        {lamp, Albert} ->
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Albert, Feed_date});

        {control, 0} ->
            init:stop(0);

        {control, 1} ->
            Given_plus_one = Given + 1,
            Given_checked = is_temp_avaliable(Given_plus_one),
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat, Feed_date});

        {control, 2} ->
            Given_subs_one = Given - 1.0,
            Given_checked = is_temp_avaliable(Given_subs_one),
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat, Feed_date});
        
        {control, 3} -> 
            if 
                Sens_damage =:= 1 ->
                    % wyłącz awarie sensora temp
                    main({P_tmp_sens, P_heater, P_timer, Actual_temp, 0, Given, Stat, Feed_date});
                true -> 
                    % Włącz włącz awarię sensora temp
                    main({P_tmp_sens, P_heater, P_timer, Actual_temp, 1, Given, Stat, Feed_date})
            end;

        {control, 4} ->
            {H, M} = get_time(),
            P_timer ! {time_to_start,H,M, self()},
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});

        {control, 5} ->
            {H, M} = get_time(),
            P_timer ! {time_to_stop,H,M, self()},
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});

        {control, 6} ->
            Feed = date_dm(),
            write_to_file(?data_file, Feed),
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed});

        _ ->
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date})
        
    after 1000 -> 
        if
            Sens_damage =:= 0 ->
                P_tmp_sens!{P_heater,self(), Actual_temp, Given},
                main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});
                
            true ->
                main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date})
        end
    end.
  

tmp_sens() ->
    receive
        {P_heater,P_main,Actual_temp, Given} ->
            % if  Value < Zadana -> ON to heater
            % else -> OFF to heater
            if
                Actual_temp  < Given ->
                    P_heater!{self(),P_main,on},
                    tmp_sens();

                true ->
                    P_heater!{self(),P_main,off},
                    tmp_sens()
            end                   
    end.

heater() ->
    receive
        {_,P_main,on} ->
            % Wait 1 sec, and send rand value (0.1 - 3) to core
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            % U dołu do poprawy !!!!! Zdecydować co przekazać jeszcze 
            P_main!{data, up, Rand_val},
            heater();

        {_,P_main,off} ->
            % Wait 1 sec, and send rand value (0.1 - 3)
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            P_main!{data, down, Rand_val},
            heater()
    end.

timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main, P_lamp}) ->
    A = check_time({Given_start_H * 60 + Given_start_M},{Given_stop_H * 60 + Given_stop_M}),
    if
        A ->
            P_lamp ! {on,P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}} };

        true -> 
            P_lamp ! {off, P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}
    end,
    receive
        {time_to_start,H1,M1, P_main_new} ->
            timer({{H1,M1},{Given_stop_H, Given_stop_M}, P_main_new, P_lamp});

        {time_to_stop,H1,M1, P_main_new} ->
            timer({{Given_start_H, Given_start_M},{H1,M1}, P_main_new, P_lamp})
    after 60000 ->
        timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main,P_lamp})
    end.

check_time({Start_HM},{Stop_HM}) ->
    {_,{H,M,_}} = erlang:localtime(),
    HM = H * 60 + M,
    if
        Start_HM =< Stop_HM ->
            if
                HM >= Start_HM andalso HM =< Stop_HM ->
                    true;
                true ->
                    false
            end;
        true ->
            if
                HM >= Stop_HM andalso HM =< Start_HM ->
                    false;
                true ->
                    true
            end
    end.

lamp() ->
    receive
        {_, undefined, _} ->
            lamp();
        {on, P_main, Times} ->
            P_main!{lamp, {on, Times}},
            lamp();
        {off, P_main, Times} ->
            P_main!{lamp, {off,Times}},
            lamp()
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


round1dec(Number) ->
    P = math:pow(10, 1),
    floor(Number * P) / P.

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

dupa(Arg) ->
    io:format(os:cmd(clear)),
    io:format("\n~p\n", [Arg]).

time_hm() ->
    {_,Time} = erlang:localtime(),
    {H,M,_} = Time,
    if 
        H > 9 andalso M > 9 ->
            io:format("\t||          ~p:~p         ||\n", [H,M]);
        M > 9  andalso H < 10 -> 
            io:format("\t||         0~p:~p         ||\n", [H,M]);
        H > 9 andalso M < 10 ->
            io:format("\t||          ~p:0~p         ||\n", [H,M]);
        H < 10 andalso M < 10 ->
            io:format("\t||          0~p:0~p         ||\n", [H,M])
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

add_space_after(Value) ->
    if
        Value =:= on ->
            lists:concat([Value, " "]);

        true -> 
            Value
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
    
write_to_file(File_path, Value) ->
    {ok,F} = file:open(File_path, [write]),
    try
        file:write(F, Value)
    after
        file:close(F)
    end.  


read_from_file(File_path) ->
    {ok,F} = file:open(File_path, [read]),
    try
        {ok,Str} = file:read(F, 1024*1024),
        string:left(Str,5)
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
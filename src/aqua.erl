-module(aqua).
-export([run/0, main/1, timer/1, feed/0]).

% Imports
-import(display, [draw_panel/5]).
-import(helper, [round1dec/1, check_time/2, is_temp_avaliable/1, get_time/0, read_from_file/1, write_to_file/2, date_dm/0]).


% % Dedfines 
-define(start_temp, 23.0).
-define(sensor_damage, 0).
-define(given_temp_at_start, 32.0).
% File with last feed date
-define(data_file, "./data/date.txt").

% Runing function
run() -> 
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
    P_lamp = spawn(fun lamp/0),
    P_timer = spawn(aqua, timer, [{{0,0},{0,0},undefined, P_lamp, off}]),
    Feed_date = read_from_file(?data_file),
    P_main = spawn(aqua, main, [{P_tmp_sens, P_heater, P_timer, float(?start_temp), ?sensor_damage, ?given_temp_at_start, {off, {{0,0},{0,0}}}, Feed_date}]),
    control_listener({P_tmp_sens, P_heater, P_main}).

% Waiting for interrup 
control_listener({P_tmp_sens, P_heater, P_main}) ->
    {Functionality,_} = string:to_integer(io:get_line("")),
    P_main!{control, Functionality},
    control_listener({P_tmp_sens, P_heater, P_main}).


main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date}) ->
    io:format(os:cmd(clear)),
    io:format("----===== Aquarium Control Manager =====---- \n\n"),
    if
        Sens_damage =:= 0 ->
            Sens_status = "No ";

        true ->
            Sens_status = "Yes"
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
        
        {feed, Parse_date} ->
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Parse_date});

        {control, 0} -> %Exit
            init:stop(0);

        {control, 1} -> %Given temp UP
            Given_plus_one = Given + 1,
            Given_checked = is_temp_avaliable(Given_plus_one),
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat, Feed_date});

        {control, 2} -> %Given temp DOWN
            Given_subs_one = Given - 1.0,
            Given_checked = is_temp_avaliable(Given_subs_one),
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat, Feed_date});
        
        {control, 3} -> %sensor error
            if 
                Sens_damage =:= 1 ->
                    % Turn off sensor errror
                    main({P_tmp_sens, P_heater, P_timer, Actual_temp, 0, Given, Stat, Feed_date});
                true -> 
                    %  Turn on sensor errror
                    main({P_tmp_sens, P_heater, P_timer, Actual_temp, 1, Given, Stat, Feed_date})
            end;

        {control, 4} -> %Set lamp start time
            {H, M} = get_time(),
            P_timer ! {time_to_start,H,M, self()},
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});

        {control, 5} -> %Set lamp stop time
            {H, M} = get_time(),
            P_timer ! {time_to_stop,H,M, self()},
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});

        {control, 6} -> %Update last feed date
            P_feed = spawn(fun feed/0),
            P_feed ! {generate, self()},
            main({P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat, Feed_date});

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
  
% Temp Sensor process main function
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

% Heater process main function
heater() ->
    receive
        {_,P_main,on} ->
            % Wait 1 sec, and send rand value (0.1 - 3) to core
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            P_main!{data, up, Rand_val},
            heater();

        {_,P_main,off} ->
            % Wait 1 sec, and send rand value (0.1 - 3)
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            P_main!{data, down, Rand_val},
            heater()
    end.

% Timer process main function
timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main, P_lamp, State}) ->
    A = check_time({Given_start_H * 60 + Given_start_M},{Given_stop_H * 60 + Given_stop_M}),
    if
        A andalso State =:= off ->
            P_lamp ! {on,P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}};

        A =:= false andalso State =:= on -> 
            P_lamp ! {off, P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}};

        true -> ok
    end,
    receive
        {time_to_start,H1,M1, P_main_new} ->
            P_lamp ! {State,P_main_new,{{H1, M1},{Given_stop_H, Given_stop_M}}},
            timer({{H1,M1},{Given_stop_H, Given_stop_M}, P_main_new, P_lamp, State});

        {time_to_stop,H1,M1, P_main_new} ->
            P_lamp ! {State,P_main_new,{{Given_start_H, Given_start_M},{H1, M1}}},
            timer({{Given_start_H, Given_start_M},{H1,M1}, P_main_new, P_lamp, State})
    after 1000 ->
        timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main,P_lamp, State})
    end.

% Lamp process main function
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

% Feed process main function
feed() ->
    receive
        {generate, From} ->
            Parse_date = date_dm(),
            write_to_file(?data_file, Parse_date),
            From ! {feed, Parse_date}
    end.
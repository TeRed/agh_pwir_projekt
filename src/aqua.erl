-module(aqua).
-compile(export_all).

-define(max_temp, 34.0).
-define(min_temp, 18.0).
-define(start_temp, 23.0).
-define(sending_temp_at_start, 0).
-define(given_temp_at_start, 32.0).

-define(temp_file, "./data/temp.txt").

run() -> 
    % Tu ma być Try Catch
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
    % P_core = spawn(fun core_temp/0),
    P_main = spawn(aqua, main, [{P_tmp_sens, P_heater, float(?start_temp), ?sending_temp_at_start, ?given_temp_at_start}]),
    control_listener({P_tmp_sens, P_heater, P_main}).


control_listener({P_tmp_sens, P_heater, P_main}) ->
    {Functionality,_} = string:to_integer(io:get_line("")),
    P_main!{control, Functionality},
    control_listener({P_tmp_sens, P_heater, P_main}).


main({P_tmp_sens, P_heater, Actual_temp, Sending_temp, Given}) ->
    io:format(os:cmd(clear)),
    io:format("Sens=~p heater=~p main=~p\n",[P_tmp_sens,P_heater,self()]),
    io:format("To jest nasza super aplikacja - Akwarium \n\n"),
    % {Given,_} = string:to_integer(read_from_file(?temp_file)),
    % io:format("\n~p\n", [Sending_temp]),
    if
        Sending_temp =:= 0 ->
            Emisja = "Nie";

        true ->
            Emisja = "Tak"
    end,
    draw_panel(Actual_temp, Given, Emisja),
    receive
        {data, up, Value} ->
            Updated_temp = Actual_temp + Value,
            if
                Updated_temp >= Given ->
                    main({P_tmp_sens, P_heater, Updated_temp, 0, Given});
                true ->
                    main({P_tmp_sens, P_heater, Updated_temp, 1, Given})
            end;

        {data, down, Value} ->
            Updated_temp = Actual_temp + Value,
            main({P_tmp_sens, P_heater, Updated_temp, Sending_temp, Given});

        {control, 0} ->
            init:stop(0);

        {control, 1} ->
            Given_plus_one = Given + 1,
            Given_checked = is_temp_avaliable(Given_plus_one),
            % dupa(Given_plus_one);
            % write_to_file(?temp_file, Given_checked),
            main({P_tmp_sens, P_heater, Actual_temp, Sending_temp, Given_checked});

        {control, 2} ->
            Given_subs_one = Given - 1.0,
            Given_checked = is_temp_avaliable(Given_subs_one),
            % write_to_file(?temp_file, Given_checked),
            main({P_tmp_sens, P_heater, Actual_temp, Sending_temp, Given_checked});
        
        {control, 3} -> 
            if 
                Sending_temp =:= 0 ->
                    % Włącz nadawanie temp
                    main({P_tmp_sens, P_heater, Actual_temp, 1, Given});
                true -> 
                    % Wyłącz nadawanie temp
                    main({P_tmp_sens, P_heater, Actual_temp, 0, Given})
            end
        
    after 1000 -> 
        if
            Sending_temp =:= 1 ->
                P_tmp_sens!{P_heater,self(), Actual_temp, Given},
                main({P_tmp_sens, P_heater, Actual_temp, Sending_temp, Given});
                
            true ->
                main({P_tmp_sens, P_heater, Actual_temp, Sending_temp, Given})
        end
    end.
    % {Functionality,_} = string:to_integer(io:get_line("Wybierz: ")),
    
    % if
    %     Functionality =:= 0 ->
    %         init:stop(0);
        
    %     Functionality =:= 1 ->
    %         io:format("Set temp\n"),
    %         Value = (string:left(io:get_line("Podaj nastaw temp: "),2)),
    %         Value = is_temp_avaliable(Value),
    %         write_to_file(?temp_file, Value),
    %         main({P_tmp_sens, P_heater, P_main});

    %     Functionality =:= 2 ->
    %         receive
    %             {ok} -> ok
    %         end;
    %         % Załączenie emisji 
            

    %     true ->
    %         io:format(os:cmd(clear)),
    %         main({P_tmp_sens, P_heater, P_main})
    % end.

tmp_sens() ->
    receive
        {P_heater,P_main,Actual_temp, Given} ->
            % if  Value < Zadana -> ON to heater
            % else -> OFF to heater
            % Given = strin:to_integer(read_from_file(?temp_file)),
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
        {P_tmp_sens,P_main,on} ->
            % Wait 1 sec, and send rand value (0.1 - 3) to core
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            % U dołu do poprawy !!!!! Zdecydować co przekazać jeszcze 
            P_main!{data, up, Rand_val},
            heater();

        {P_tmp_sens,P_main,off} ->
            % Wait 1 sec, and send rand value (0.1 - 3)
            timer:sleep(1000),
            Rand_val = round1dec(rand:uniform() * 3) + 0.1,
            % U dołu do poprawy !!! Co chce przesłać dalej 
            P_main!{data, down, Rand_val},
            heater()
    end.

% core_temp() ->
%     receive
%         {ok} -> ok
%     end.

is_temp_avaliable(Temp) -> 
    if 
        Temp > ?max_temp ->
            ?max_temp;

        Temp < ?min_temp ->
            ?min_temp;

        true -> 
            Temp
    end.

write_to_file(File_path, Value) ->
    {ok, File_handler} = file:open(File_path, [write]),
    file:write(File_handler,Value).

read_from_file(File_path) -> 
    {ok, File_handler} = file:open(File_path,[read]),
    {ok, Readed_string} = file:read(File_handler, 1024*1024),
    string:left(Readed_string,2).

round1dec(Number) ->
    P = math:pow(10, 1),
    floor(Number * P) / P.

option_menu() ->
    io:format("\n
            [1] Zwieksz temp\n
            [2] Zmniejsz temp\n
            [3] Wl/Wy emisje temp\n
            [0] Exit \n\n
Wybierz: ").

draw_panel(Actual, Given, Emisja) ->
    io:format("\t ------------------------\n"),
    io:format("\t|Akt. temp.    ~p st.C |\n", [float(Actual)]),
    io:format("\t|Zad. temp.    ~p st.C |\n", [float(Given)]),
    io:format("\t|Emi. temp.       ~s    |\n", [Emisja]),
    io:format("\t ------------------------"),
    option_menu().

dupa(Arg) ->
    io:format(os:cmd(clear)),
    io:format("\n~p\n", [Arg]).
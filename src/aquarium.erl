-module(aquarium).
-compile(export_all).

-define(max_temp, "34").
-define(min_temp, "18").
-define(start_temp, "23").

-define(temp_file, "./data/temp.txt").

run() -> 
    % Tu ma być Try Catch
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
    P_core = spawn(fun core_temp/0),
    main({P_tmp_sens, P_heater, P_core}).

main({P_tmp_sens, P_heater, P_core}) ->
    io:format(os:cmd(clear)),
    io:format("Sens=~p heater=~p core=~p\n",[P_tmp_sens,P_heater,P_core]),
    io:format("To jest nasza super aplikacja - Akwarium \n"),
    option_menu(),
    {Functionality,_} = string:to_integer(io:get_line("Wybierz: ")),
    
    if
        Functionality =:= 0 ->
            init:stop(0);
        
        Functionality =:= 1 ->
            io:format("Set temp\n"),
            Value = (string:left(io:get_line("Podaj nastaw temp: "),2)),
            Value = is_temp_avaliable(Value),
            write_to_file(?temp_file, Value),
            main({P_tmp_sens, P_heater, P_core});

        Functionality =:= 2 ->
            receive
                {ok} -> ok
            end;
            % Załączenie emisji 
            

        true ->
            io:format(os:cmd(clear)),
            main({P_tmp_sens, P_heater, P_core})
    end.


tmp_sens() ->
    receive
        {P_heater,P_core,Value} ->
            % if  Value < Zadana -> ON to heater
            % else -> OFF to heater
            Given = strin:to_integer(read_from_file(?temp_file)),
            if
                Value  < Given ->
                    P_heater!{self(),P_core,on},
                    tmp_sens();

                true ->
                    P_heater!{self(),P_core,on},
                    tmp_sens()
            end                   
    end.

heater() ->
    receive
        {P_tmp_sens,P_core,on} ->
            % Wait 1 sec, and send rand value (0.1 - 3) to core
            timer:sleep(1000),
            Rand_val = rand:uniform(),
            % U dołu do poprawy !!!!! Zdecydować co przekazać jeszcze 
            P_core!{Rand_val};

        {P_tmp_sens,P_core,off} ->
            % Wait 1 sec, and send rand value (0.1 - 3)
            timer:sleep(1000),
            Rand_val = rand:uniform(),
            % U dołu do poprawy !!! Co chce przesłać dalej 
            P_core!{Rand_val}
    end.

core_temp() ->
    receive
        {ok} -> ok
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

write_to_file(File_path, Value) ->
    {ok, File_handler} = file:open(File_path, [write]),
    file:write(File_handler,Value).

read_from_file(File_path) -> 
    {ok, File_handler} = file:open(File_path,[read]),
    {ok, Readed_string} = file:read(File_handler, 1024*1024),
    string:left(Readed_string,2).


option_menu() ->
    io:format("\n
        [1] Ustwa temperature \n
        [2] Wlacz emisje temp\n
        [3] Wylacz emisje temp\n
        [0] Exit \n\n").

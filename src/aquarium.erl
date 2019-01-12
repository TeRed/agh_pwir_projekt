-module(aquarium).
-compile(export_all).

-define(max_temp, "34").
-define(min_temp, "18").

-define(temp_file, "./data/temp.txt").

main() ->
    % Tu ma być Try Catch
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
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
            main();

        % Functionality =:= 2 ->
            

        true ->
            io:format(os:cmd(clear)),
            main()
    end.


tmp_sens() ->
    receive
        {P_heater,P_core,Value} -> ok
            % if  Value < Zadana -> ON
            % else -> OFF
    end.

heater() ->
    receive
        {P_tmp_sens,P_core,on} -> ok;
            % Wait 1 sec, and send rand value (0.1 - 3)
        {P_tmp_sens,P_core,off} -> ok
            % Wait 1 sec, and send rand value (0.1 - 3)
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
        [3] Wylacz emisje \n
        [0] Exit \n\n").

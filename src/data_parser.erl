-module(data_parser).

-export([parse/2]).

parse(Octets, Structure) when is_list(Octets) ->
   parse_list(Octets, Structure, [], 0, #{});

parse(Octets, Structure) when is_binary(Octets) ->
   parse_binary(Octets, Structure, [], 0, #{}).

parse_list(Rest, [{DataItem,Type, Len}|T], Intmed, N, Final)  when N == Len ->
    parse_list(Rest, T, [], 0, maps:put(DataItem,do_type(Type, Intmed),Final));

parse_list([Byte|Rest], [{DataItem, Type, Len}|T], Intmed, N, Final) ->
    parse_list(Rest, [{DataItem, Type, Len}|T], Intmed ++ [Byte], N+1, Final);

parse_list([], [], _, 0, Final) ->
    {ok,Final}.


parse_binary(Rest, [{DataItem,Type, Len}|T], Intmed, N, Final)  when N == Len ->
   parse_binary(Rest, T, [], 0, maps:put(DataItem,do_type(Type, Intmed),Final));

parse_binary(<<Byte:8,Rest/binary>>, [{DataItem, Type, Len}|T], Intmed, N, Final) ->
   parse_binary(Rest, [{DataItem, Type, Len}|T], Intmed ++ [Byte], N+1, Final);

parse_binary(<<>>, [], _, 0, Final) ->
   {ok,Final}.


do_type(binary, Intmed) -> Intmed;
do_type(int, [_Len|Intmed]) -> octets_to_int(Intmed);
do_type(num, [_Len|Intmed]) -> extract_number(Intmed);
do_type(txt, [_Len|Intmed]) -> extract_number(Intmed).

octets_to_int(List) ->
    octets_to_int(lists:reverse(List), 0).

octets_to_int([H|T], N) ->
    round(math:pow(256,N)) * H + octets_to_int(T, N+1);
octets_to_int([],_) ->
    0.

% int_to_octets(_, 0) ->
%     [];
% int_to_octets(Value, Len) ->
%     Divisor = round(math:pow(256,(Len-1))),     % round converts to integer
%     Octet = Value div Divisor,
%     if Octet =< 255 ->
%        [Octet|int_to_octets(Value rem Divisor, Len-1)]
%     end.

extract_number([H|_]) when H == 255 ->
    [];
extract_number([H|T]) ->
    [H|extract_number(T)];
extract_number([]) ->
    [].

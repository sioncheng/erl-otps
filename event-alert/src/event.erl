-module(event).

-export([start/2, start_link/2, cancel/1, init/3]).

-record(state, {server, name="", to_go=[]}).

%%% -------------------------------------
%%% apis
%%% -------------------------------------

start(EventName, Delay) ->
	spawn(?MODULE, init, [self(), EventName, Delay]).

start_link(EventName, Delay) ->
	spawn_link(?MODULE, init, [self(), EventName, Delay]).

cancel(Pid) ->
	Ref = erlang:monitor(process, Pid),
	Pid ! {self(), Ref, cancel},
	receive 
		{Ref, ok} ->
			erlang:demonitor(Ref, [flush]),
			ok;
		{'DOWN', Ref, process, Pid, _Reason} ->
			ok
	end.

%%% for callback
init(Server, EventName, Delay) ->
	loop(#state{server=Server, name=EventName, to_go=normalize(Delay)}).

%%% core
loop(State = #state{server=Server, to_go=[T|Next]}) ->
	receive 
		{Server, Ref, cancel} ->
			Server ! {Ref, ok}
	after T * 1000 ->
		if Next =:= [] ->
			Server ! {done, State#state.name} ;
		Next =/= [] ->
			loop(State#state{to_go=Next})
		end
end.


%%% -------------------------------------
%%% internal functions
%%% -------------------------------------
normalize(N) ->
	Limit = 49 * 24 * 24 * 60,
	[N rem Limit | lists:duplicate(N div Limit, Limit)].


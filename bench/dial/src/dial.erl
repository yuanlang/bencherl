-module(dial).

-export([bench_args/0, run/3]).

bench_args() -> 
	[[plt], [otp]].

run([plt], _, Opts) ->

	load(Opts),
	DataDir = get(datadir),

	[] = dialyzer:run([{analysis_type, plt_build},
		{report_mode, normal},
		{files_rec, [DataDir ++ "/plt"]},
		{timing, true},
		{output_plt, DataDir ++ "/the.plt"}]),
		ok;

run([otp], _, Opts) ->

    load(Opts),
    DataDir = get(datadir),

    RawWarns = dialyzer:run([{files_rec, [F || F <- [DataDir ++ "/plt", DataDir ++ "/otp"]]},
		{report_mode, normal},
		{init_plt, DataDir ++ "/the.plt"},
		{timing, true}]),
	Warns = lists:sort([dialyzer:format_warning(W) || W <- RawWarns]),
	io:format("~s", [Warns]),
	ok.

load([]) ->
	ok;
load([{K,V} | R]) ->
	put(K, V),
	load(R).


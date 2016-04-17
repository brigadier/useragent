-module(useragent).
-export([parse/1, parse/2]).
-include("useragent.hrl").


% -spec is_mobile_device...

-spec parse(user_agent_string()) -> user_agent().
parse(UA) -> parse(UA, utf8).

-spec parse(user_agent_string(), unicode:encoding()) -> user_agent().
parse(UA, Encoding) when is_list(UA) ->
	parse(iolist_to_binary(UA), Encoding);
parse(UA, Encoding) ->
	UALower = list_to_binary(string:to_lower(binary_to_list(characters_to_binary(UA, Encoding)))),
	{parse_browser(UALower, browsers()), parse_os(UALower, os())}.


parse_browser(UA, Browsers) ->
	Browser = case parse(UA, Browsers, #browser.in, #browser.out) of
				  #browser{} = X -> X;
				  _ ->
					  #browser{name = undefined, family = undefined, type = undefined, manufacturer = undefined, engine = undefined, midp = false, midp_vsn = undefined}

			  end,
	case Browser of
		#browser{type = Type} when Type == mobile orelse Type == undefined ->
			parse_midp(UA, Browser);
		_ ->
			Browser
	end.


parse_os(UA, Os) ->
	case parse(UA, Os, #os.in, #os.out) of
		#os{} = X -> X;
		_ -> #os{name = undefined, family = undefined, type = undefined, manufacturer = undefined}
	end.

parse_midp(UA, Browser) ->
	case match(UA, [<<"midp">>], []) of
		{true, true} ->
			case re:run(UA, "midp-?(\\d+\\.\\d+)?", [{capture, all_but_first, binary}]) of
				{match, [Vsn]} -> Browser#browser{type = mobile, midp = true, midp_vsn = Vsn};
				{match, _} -> Browser#browser{type = mobile, midp = true, midp_vsn = undefined};
				_ -> Browser
			end;
		_ ->
			Browser

	end.

parse(_UA, [], _InPos, _OutPos) -> [];
parse(UA, [[H | T] | Candidates], InPos, OutPos) ->
	InPat = element(InPos, H),
	OutPat = element(OutPos, H),
	case {match(UA, InPat, OutPat), T} of
		{{true, true}, []} -> % generic one fits, no children
			H;
		{{true, true}, _} -> % check for more precise entries
			parse_sub(UA, T, InPos, OutPos, H);
		{{true, false}, _} -> % check for more precise entries
			case parse_sub(UA, T, InPos, OutPos, H) of
				H -> parse(UA, Candidates, InPos, OutPos);
				Val -> Val
			end;
		{{false, _}, _} -> % no match, keep looking
			parse(UA, Candidates, InPos, OutPos)
	end.

parse_sub(UA, Children, InPos, OutPos, Default) ->
	try
		_ = [case match(UA, element(InPos, Item), element(OutPos, Item)) of
				 {true, true} -> throw(Item);
				 _ -> nomatch
			 end || Item <- Children],
		Default
	catch
		Term ->
			case Term of
				#browser{postprocess = undefined} -> Term;
				#browser{postprocess = F} -> F(Term, UA);
				#os{postprocess = undefined} -> Term;
				#os{postprocess = F} -> F(Term, UA)
			end
	end.

match(UA, InPattern, OutPattern) ->
	{lists:any(fun(Pat) -> nomatch =/= binary:match(UA, Pat) end, InPattern),
		lists:all(fun(Pat) -> nomatch =:= binary:match(UA, Pat) end, OutPattern)}.

browsers() ->
	Opera = #browser{name = <<"Opera">>, family = opera, type = web, manufacturer = opera, engine = presto, in = [<<"opera">>]},
	OperaWebkit = #browser{name = <<"Opera">>, family = opera, type = web, manufacturer = opera, engine = webkit, in = [<<"opr">>]},
	Yandex = #browser{name = <<"Yandex Browser">>, family = yandex, type = web, manufacturer = yandex, engine = webkit, in = [<<"yabro">>]},
	Outlook = #browser{name = <<"Outlook">>, family = outlook, type = email, manufacturer = microsoft, engine = word, in = [<<"msoffice">>]},
	IE = #browser{name = <<"Internet Explorer">>, family = ie, type = web, manufacturer = microsoft, engine = trident, in = [<<"msie">>]},
	IE11 = #browser{name = <<"Internet Explorer">>, family = ie, type = web, manufacturer = microsoft, engine = trident, in = [<<"trident">>]},
	Spartan = #browser{name = <<"Spartan">>, family = spartan, type = web, manufacturer = microsoft, engine = edge, in = [<<"edge/">>]},
	Chrome = #browser{name = <<"Chrome">>, family = chrome, type = web, manufacturer = google, engine = webkit, in = [<<"chrome">>]},
	Safari = #browser{name = <<"Safari">>, family = safari, type = web, manufacturer = apple, engine = webkit, in = [<<"safari">>]},
	Thundr = #browser{name = <<"Thunderbird">>, family = thunderbird, type = email, manufacturer = mozilla, engine = gecko, in = [<<"thunderbird">>]},
	Cam = #browser{name = <<"Camino">>, family = camino, type = web, engine = gecko, in = [<<"camino">>]},
	FF = #browser{name = <<"Firefox">>, family = firefox, type = web, manufacturer = mozilla, engine = gecko, in = [<<"firefox">>]},
	[
		%% Opera
		[Opera
			, Opera#browser{name = <<"Opera Mini">>, type = mobile, in = [<<"opera mini">>]}
			, Opera#browser{name = <<"Opera">>, engine = presto, in = [<<"version">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*version/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
			, Opera#browser{name = <<"Opera">>, engine = presto, in = [<<"opera ">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*opera\\s([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
			, Opera#browser{name = <<"Opera">>, engine = webkit, in = [<<"opera/">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*opera/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
		],
		[OperaWebkit
			, OperaWebkit#browser{name = <<"Opera Mobile">>, engine = webkit, type = mobile, in = [<<"mobile">>, <<"android">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*opr/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
			, OperaWebkit#browser{name = <<"Opera">>, engine = webkit, in = [<<"opr/">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*opr/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}

		],

		[Yandex
			, Yandex#browser{name = <<"Yandex Browser Mobile">>, engine = webkit, type = mobile, in = [<<"mobile">>, <<"android">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, "yabrowser/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
			, Yandex#browser{name = <<"Yandex Browser">>, engine = webkit, in = [<<"yabro">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*yabrowser/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}

		],
		%% Konqueror
		[#browser{name = <<"Konqueror">>, family = konqueror, type = web, engine = khtml, in = [<<"konqueror">>]}
		],
		%% Outlook / Word engine
		[Outlook
			, Outlook#browser{name = <<"Outlook 2007">>, in = [<<"msoffice 12">>]}
			, Outlook#browser{name = <<"Outlook 2010">>, in = [<<"msoffice 14">>]}
		],
		%% IE
		[IE
			, IE#browser{name = <<"Windows Live Mail">>, type = email, in = [<<"outlook-express/7.0">>]}

			, IE#browser{name = <<"IE Mobile">>, type = mobile, in = [<<"iemobile">>],

			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*iemobile[/\\s]([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end

		}
%%       ,IE#browser{name= <<"Internet Explorer 5.5">>, in=[<<"msie 5.5">>]} %%
			, IE#browser{name = <<"Internet Explorer">>, in = [<<"msie">>],

			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*msie[/\\s]([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
			, IE#browser{name = <<"Internet Explorer">>, in = [<<"trident">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*rv:([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		[IE11

			, IE11#browser{name = <<"Internet Explorer">>, in = [<<"trident">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*rv:([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		[Spartan
			, Spartan#browser{name = <<"Spartan">>, in = [<<"mobile">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, "edge/([\\.\\d]+)", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn, type = mobile};
					_ -> Browser
				end
						  end}
			, Spartan#browser{name = <<"Spartan">>, in = [<<"edge/">>],

			postprocess = fun(Browser, UA) ->
				case re:run(UA, "edge/([\\.\\d]+)", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end}
		],
		%% Chrome
		[Chrome
			, Chrome#browser{name = <<"Chrome Mobile">>, in = [<<"mobile">>, <<"android">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*chrome/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn, type = mobile};
					_ -> Browser
				end
						  end
		}
			, Chrome#browser{name = <<"Chrome">>, in = [<<"chrome">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*chrome/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		%% Omniweb
		[#browser{name = <<"OmniWeb">>, family = omniweb, type = web, engine = webkit, in = [<<"omniweb">>]}
		],
		%% Safari
		[Safari
			, Safari#browser{name = <<"Chrome Mobile">>, type = mobile, manufacturer = google, in = [<<"crios">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*crios/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
			, Safari#browser{name = <<"Mobile Safari">>, type = mobile, in = [<<"mobile safari">>, <<"mobile/">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*version/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
			, Safari#browser{name = <<"Silk">>, manufacturer = amazon, in = [<<"silk/">>]}
			, Safari#browser{name = <<"Safari">>, in = [<<"version">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*version/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		%% Dolphin2
		[#browser{name = <<"Samsung Dolphin 2">>, family = dolfin2, type = mobile, manufacturer = samsung, engine = webkit, in = [<<"dolfin/2">>]}
		],
		%% apple mail
		[#browser{name = <<"Apple Mail">>, family = apple_mail, type = email, manufacturer = apple, engine = webkit, in = [<<"applewebkit">>]}
		],
		%% lotus notes
		[#browser{name = <<"Lotus Notes">>, family = lotus_notes, type = email, in = [<<"lotus-notes">>]}
		],
		%% thunderbird
		[Thundr
			, Thundr#browser{name = <<"Thunderbird">>, in = [<<"thunderbird">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*thunderbird/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		%% Camino
		[Cam
			, Cam#browser{name = <<"Camino 2">>, in = [<<"camino/2">>]}
		],
		%% flock
		[#browser{name = <<"Flock">>, family = flock, type = web, engine = gecko, in = [<<"flock">>]}
		],
		%% firefox
		[FF
			, FF#browser{name = <<"Firefox 3 Mobile">>, type = mobile, in = [<<"firefox/3.5 maemo">>]}
			, FF#browser{name = <<"Firefox Mobile">>, type = mobile, in = [<<"mobile">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*firefox/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
			, FF#browser{name = <<"Firefox">>, in = [<<"firefox">>],
			postprocess = fun(Browser, UA) ->
				case re:run(UA, ".*firefox/([\\.\\d]+).*", [{capture, all_but_first, binary}]) of
					{match, [Vsn]} -> Browser#browser{vsn = Vsn};
					_ -> Browser
				end
						  end
		}
		],
		%% seamonkey
		[#browser{name = <<"SeaMonkey">>, family = seamonkey, type = web, engine = gecko, in = [<<"seamonkey">>]}
		],
		%% bot
		[#browser{name = <<"Robot/Spider">>, family = robot, type = robot,
			in = [<<"googlebot">>, <<"bot">>, <<"spider">>, <<"crawler">>,
				<<"feedfetcher">>, <<"slurp">>, <<"twiceler">>, <<"nutch">>,
				<<"becomebot">>, <<"python">>, <<"phantomjs">>]}
		],
		%% standalones
		[#browser{name = <<"Mozilla">>, family = mozilla, type = web, manufacturer = mozilla, in = [<<"mozilla">>, <<"moozilla">>]}
		],
		[#browser{name = <<"TizenBrowser">>, family = tizen, type = mobile, manufacturer = samsung, engine = webkit, in = [<<"tizenbrowser">>, <<"tizen browser">>]}
		],
		[#browser{name = <<"CFNetwork">>, family = cfnetwork, in = [<<"cfnetwork">>]}
		],
		[#browser{name = <<"Eudora">>, family = eudora, type = email, in = [<<"eudora">>]}
		],
		[#browser{name = <<"PocoMail">>, family = pocomail, type = email, in = [<<"pocomail">>]}
		],
		[#browser{name = <<"The Bat!">>, family = thebat, type = email, in = [<<"the bat">>]}
		],
		[#browser{name = <<"NetFront">>, family = netfront, type = mobile, in = [<<"netfront">>]}
		],
		[#browser{name = <<"Evolution">>, family = evolution, type = email, in = [<<"camelhttpstream">>]}
		],
		[#browser{name = <<"Lynx">>, family = lynx, type = text, in = [<<"lynx">>]}
		],
		[#browser{name = <<"Downloading Tool">>, family = tool, type = text, in = [<<"curl">>, <<"wget">>]}
		]
	].

os() ->
	Win = #os{name = <<"Windows">>, family = windows, type = computer, manufacturer = microsoft,
		in = [<<"windows">>], out = [<<"palm">>]},
	Droid = #os{name = <<"Android">>, family = android, type = mobile, manufacturer = google,
		in = [<<"android">>]},
	IOs = #os{name = <<"iOS">>, family = ios, type = mobile, manufacturer = apple, in = [<<"like mac os x">>]},
	Kind = #os{name = <<"Linux (Kindle)">>, family = kindle, type = tablet,
		manufacturer = amazon, in = [<<"kindle">>]},
	Sym = #os{name = <<"Symbian OS">>, family = symbian, type = mobile, manufacturer = symbian,
		in = [<<"symbian">>, <<"series60">>]},
	BBY = #os{name = <<"BlackBerryOS">>, family = blackberry, type = mobile,
		manufacturer = blackberry, in = [<<"blackberry">>]},
	[%% Windows
		[Win,

			Win#os{name = <<"Windows Phone">>, type = mobile, in = [<<"windows phone">>], out = [],
				postprocess = fun(Os, UA) ->
					case re:run(UA, "windows phone( os)? ([\\.\\d]+)", [{capture, all_but_first, binary}]) of
						{match, [_, Vsn]} -> Os#os{name = <<"Windows Phone ", Vsn/binary>>};
						_ -> Os
					end
							  end},
			Win#os{name = <<"Windows 8 RT">>, type = tablet, in = [<<"arm;">>], out = []},
			Win#os{name = <<"Windows 8.1">>, in = [<<"windows nt 6.3">>], out = []},
			Win#os{name = <<"Windows 10">>, in = [<<"windows nt 10.">>], out = []},
			Win#os{name = <<"Windows 8">>, in = [<<"windows nt 6.2">>], out = []},
			Win#os{name = <<"Windows 7">>, in = [<<"windows nt 6.1">>], out = []},
			Win#os{name = <<"Windows Vista">>, in = [<<"windows nt 6">>], out = []},
			Win#os{name = <<"Windows 2000">>, in = [<<"windows nt 5.0">>], out = []},
			Win#os{name = <<"Windows XP">>, in = [<<"windows nt 5">>], out = []},
			Win#os{name = <<"Windows Mobile">>, type = mobile, in = [<<"windows ce">>], out = []},
			Win#os{name = <<"Windows 98">>, in = [<<"windows 98">>, <<"win98">>]}],
		%% Android
		[Droid,
			Droid#os{name = <<"Android 3.x Tablet">>, type = tablet, in = [<<"android 3">>]},
			Droid#os{name = <<"Android 4.x Tablet">>, type = tablet, in = [<<"xoom">>, <<"transformer">>]},
			Droid#os{name = <<"Android 4.x">>, in = [<<"android 4">>, <<"android-4">>]},
			Droid#os{name = <<"Android 5.x">>, in = [<<"android 5">>]},
			Droid#os{name = <<"Android 2.x Tablet">>, type = tablet,
				in = [<<"kindle fire">>, <<"gt-p1000">>, <<"sch-i800">>]},
			Droid#os{name = <<"Android 2.x">>, in = [<<"android 2">>]},
			Droid#os{name = <<"Android 1.x">>, in = [<<"android 1">>]}],
		[#os{name = <<"WebOS">>, family = webos, type = mobile, manufacturer = hp, in = [<<"webos">>]}],
		[#os{name = <<"PalmOS">>, family = palm, type = mobile, manufacturer = hp, in = [<<"palm">>]}],

		% ios
		[IOs,
			IOs#os{name = <<"iOS (iPhone)">>, in = [<<"iphone os">>],
				postprocess = fun(Os, UA) ->
					case re:run(UA, ".*iphone os (\\d+).*", [{capture, all_but_first, binary}]) of
						{match, [Vsn]} -> Os#os{name = <<"iOS (iPhone) ", Vsn/binary>>};
						_ -> Os
					end
							  end


			},
			IOs#os{name = <<"iOS (iPad)">>, type = tablet, in = [<<"ipad">>],
				postprocess = fun(Os, UA) ->
					case re:run(UA, ".*cpu os (\\d+).*", [{capture, all_but_first, binary}]) of
						{match, [Vsn]} -> Os#os{name = <<"iOS (iPad) ", Vsn/binary>>};
						_ -> Os
					end
							  end

			},
			IOs#os{name = <<"iOS (iPod)">>, in = [<<"ipod">>]}
		],
		% osx
		[#os{name = <<"Mac OS X">>, family = mac_osx, type = computer, manufacturer = apple,
			in = [<<"mac os x">>, <<"cfnetwork">>]}],
		% os < osx
		[#os{name = <<"Mac OS">>, family = mac_os, type = computer, manufacturer = apple, in = [<<"mac">>]}],
		%% maemo
		[#os{name = <<"Maemo">>, family = maemo, type = mobile, manufacturer = nokia, in = [<<"maemo">>]}],
		%% bada
		[#os{name = <<"Bada">>, family = bada, type = mobile, manufacturer = samsung, in = [<<"bada">>]}],
		[#os{name = <<"Tizen">>, family = tizen, type = mobile, manufacturer = samsung, in = [<<"tizen">>]}],

		%% google tv
		[#os{name = <<"Android (Google TV)">>, family = google_tv, type = dmr,
			manufacturer = google, in = [<<"googletv">>]}],
		%% kindle
		[Kind,
			Kind#os{name = <<"Linux (Kindle 3)">>, in = [<<"kindle/3">>]},
			Kind#os{name = <<"Linux (Kindle 2)">>, in = [<<"kindle/2">>]}],
		%% linux
		[#os{name = <<"Linux">>, family = linux, type = computer, in = [<<"linux">>, <<"camelhttpstream">>]}],
		[#os{name = <<"*BSD">>, family = bsd, type = computer, in = [<<"bsd">>]}],
		%% symbian
		[Sym,
			Sym#os{name = <<"Symbian OS 9.x">>, in = [<<"symbianos/9">>, <<"series60/3">>]},
			Sym#os{name = <<"Symbian OS 8.x">>, in = [<<"symbianos/8">>, <<"series60/2.6">>, <<"series60/2.8">>]},
			Sym#os{name = <<"Symbian OS 7.x">>, in = [<<"symbianos/7">>]},
			Sym#os{name = <<"Symbian OS 6.x">>, in = [<<"symbianos/6">>]}],
		%% blackberry
		[BBY,
			BBY#os{name = <<"BlackBerry 7">>, in = [<<"version/7">>]},
			BBY#os{name = <<"BlackBerry 6">>, in = [<<"version/6">>]}
		],
		%% blackberry tablet OS
		[#os{name = <<"BlackBerry Tablet OS">>, family = blackberry_tablet, type = tablet, manufacturer = blackberry, in = [<<"rim tablet os">>]}],
		%% others
		[#os{name = <<"Series 40">>, family = series40, type = mobile, manufacturer = nokia, in = [<<"nokia6300">>]}],
		[#os{name = <<"Sony Ericsson">>, family = sony_ericsson, type = mobile,
			manufacturer = sony_ericsson, in = [<<"sonyericsson">>]}],
		[#os{name = <<"SunOS">>, family = sun, type = computer, manufacturer = sun, in = [<<"sunos">>]}],
		[#os{name = <<"Sony Playstation">>, family = playstation, type = game_console,
			manufacturer = sony, in = [<<"playstation">>]}],
		[#os{name = <<"Nintendo Wii">>, family = wii, type = game_console,
			manufacturer = nintendo, in = [<<"wii">>]}],
		[#os{name = <<"Roku OS">>, family = roku, type = dmr, manufacturer = roku,
			in = [<<"roku">>]}


		]
	].

characters_to_binary(Binary, Encoding) ->
	case unicode:characters_to_binary(Binary, Encoding, latin1) of
		{error, Result, _} -> Result;
		{incomplete, Result, _} -> Result;
		Result -> Result
	end.

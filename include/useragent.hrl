-record(browser, {
	name :: browser_name(),
	vsn = <<>> :: browser_vsn(),
	family :: browser_family(),
	type :: browser_type(),
	manufacturer :: browser_manufacturer(),
	engine :: browser_engine(),
	midp = false :: boolean(),
	midp_vsn :: midp_vsn(),
	in = [] :: [binary()],
	out = [] :: [binary()],
	postprocess = undefined :: postprocess_fun()
}).
-record(os, {
	name :: os_name(),
	family :: os_family(),
	type :: os_type(),
	manufacturer :: os_manufacturer(),
	in = [] :: [binary()],
	out = [] :: [binary()],
	postprocess = undefined :: postprocess_fun()
}).

-type user_agent_string() :: iolist() | binary().
-type postprocess_fun() :: undefined | fun((X :: browser(), Y :: iolist()) -> browser()) | fun((X :: os()) -> os()).

-type user_agent() :: [{string, iolist()} |
{browser, browser()} |
{os, os()}].
-type browser() :: [{name, browser_name()}
                 |  {vsn, browser_vsn()}
                 |  {family, browser_family()}
                 |  {type, browser_type()}
                 |  {manufacturer, browser_manufacturer()}
                 |  {engine, browser_engine()}
                 |  {midp, boolean()}
                 |  {midp_vsn, midp_vsn()}
                 |  {postprocess, postprocess_fun()}].

-type os() :: [{name, os_name()} |
               {family, os_family()} |
               {type, os_type()} |
               {manufacturer, os_manufacturer()} |
               {postprocess, postprocess_fun()}].

%% browser subtypes
-type midp_vsn() :: undefined | binary().

%% -type browser_version() :: term().
-type browser_name() :: binary().
-type browser_vsn() :: binary().

-type browser_family() :: opera | konqueror | outlook | ie | chrome
| omniweb | safari | dolfin2 | apple_mail | tizen
| lotus_notes | thunderbird | camino | flock
| firefox | seamonkey | robot | mozilla | cfnetwork
| eudora | pocomail | thebat | netfront | evolution
| lynx | tool | spartan | yandex | undefined.
-type browser_type() :: web | mobile | text | email | robot | tool | undefined.
-type browser_manufacturer() :: microsoft | apple | sun | symbian | nokia
| blackberry | hp | sony_ericsson | samsung
| sony | nintendo | opera | mozilla | google
| compuserve | yahoo | aol | mmc | amazon
| roku | yandex | undefined.
-type browser_engine() :: trident | word | gecko | webkit | presto | mozilla
| khtml | edge | undefined.
%% os subtypes
-type os_name() :: binary().
-type os_manufacturer() :: microsoft | google | hp | apple | nokia | samsung
| amazon | symbian | sony_ericsson | sun | sony
| nintendo | blackberry | roku | undefined.

-type os_type() :: computer | mobile | tablet | dmr | game_console | undefined.

-type os_family() :: windows | linux | android | bsd | ios | mac_osx | mac_os | maemo | bada | tizen
| google_tv | kindle | symbian | series40 | sony_ericsson
| sun | psp | wii | blackberry | roku | midp | undefined.

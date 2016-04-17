useragent
=========

Useragent is a minimalist port of the Java
[user-agent-utils](http://user-agent-utils.java.net/) in Erlang. It
implements the basic features to figure out the OS and browser information.

Build
-----

    make


Usage
-----


```
    1> useragent:parse("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2657.0 Safari/537.36 OPR/37.0.2171.0 (Edition developer)").
{{browser,<<"Opera">>,<<"37.0.2171.0">>,opera,web,opera,
          webkit,false,undefined,
          [<<"opr/">>],                                                                                                                                                         
          [],#Fun<useragent.6.16678542>},                                                                                                                                       
 {os,<<"Linux">>,linux,computer,undefined,                                                                                                                                      
     [<<"linux">>,<<"camelhttpstream">>],
     [],undefined}}
```

Changelog
---------

- 0.1.3: Adding support for Firefox versions 21-22.
- 0.1.2: Adding support for Firefox versions 14 to 20, better binary handling
- 0.1.1: Adding support for Windows 8 user agents
- 0.1.0: Initial Commit

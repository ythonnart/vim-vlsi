"" Verilog / Systemverilog implementation of VlsiYank / VlsiPaste* 
" Author: Laurent Alacoque

" format a range from a port definition
function! vlsi#v_sv#formatRange(port) dict
    if a:port.range_start == ''
        return ''
    endif
    return '[' .. a:port.range_start .. ':' .. a:port.range_end .. ']'
endfunction

" define the formatting function for instance IOs
function! s:instanceIOFormatter(port)
    let l:format = printf("    .%%-%ds (%%-%ds)",
                \ a:port.max_sizes.name,
                \ a:port.max_sizes.name + len(a:port.suffix) +len(a:port.prefix))
    return printf(l:format, a:port.name, a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

" define the formatting function for instance signals
function! s:instanceSignalFormatter(port)
    " logic [31:0] signame
    let l:format = printf("%%-%ds %%-%ds %%s",
                \ a:port.max_sizes.type,
                \ a:port.max_sizes.range)
    return printf(l:format, a:port.type, a:port.config.formatRange(a:port), a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

" define the formatting function for module IOs
function! s:moduleIOFormatter(port)
    let l:format = printf("    %%-%ds %%-%ds %%-%ds %%s",
                \ a:port.max_sizes.dir,
                \ a:port.max_sizes.type,
                \ a:port.max_sizes.range)
    return printf(l:format, a:port.dir, a:port.type, a:port.config.formatRange(a:port), a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

let vlsi#v_sv#formatPatterns = #{
   \     definition : #{
   \         start_module              : "module {module_name}",
   \             start_generics        : " #(\x01",
   \                generics_item_func : "    parameter {name} = {value}",
   \                generics_sep       : ",\x01",
   \             end_generics          : "\x01    )",
   \             start_ports           : " (\x01",
   \                port_list_func     : function('s:moduleIOFormatter'),
   \                port_list_sep      : ",\x01",
   \             end_ports             : "\x01);\x01",
   \         end_module                : "\x01endmodule //{module_name}\x01",
   \     },
   \     instance : #{
   \         start_module              : "{module_name}",
   \             start_generics        : " #(\x01",
   \                generics_item_func : "    .{name} ({value})",
   \                generics_sep       : ",\x01",
   \             end_generics          : "\x01  )",
   \             start_ports           : " u_{prefix}{module_name}{suffix} (\x01",
   \                port_list_func     : function('s:instanceIOFormatter'),
   \                port_list_sep      : ",\x01",
   \             end_ports             : "\x01)",
   \         end_module                : ";\x01\x01",
   \     },
   \     signals  : #{
   \         start_module              : '',
   \             start_generics        : '',
   \                generics_item_func : '',
   \                generics_sep       : '',
   \             end_generics          : '',
   \             start_ports           : "// interface signals for {prefix}{module_name}{suffix}\x01",
   \                port_list_func     : function('s:instanceSignalFormatter'),
   \                port_list_sep      : ";\x01",
   \             end_ports             : ";\x01",
   \         end_module                : "// end of signals for {prefix}{module_name}{suffix}\x01\x01",
   \     },
   \ }


"Parse interface around cursor
" this alters the g:interfaces structure
" examples for interface_1.master, interface_1.slave
" g:interface {
"       'interface_1' {
"           'generics' [
"               {   'name' :'bus_width', 'type':'natural', 'value':32 },
"               {...}
"            ],
"           'ports' [ //always dir 'io'
"               {   'name':'port_1', 'type':'logic', 'range':'31{{:}}0', 'dir':'io'},
"               {...}
"           ],
"           'ports_by_name' {
"               'port_1'  {   'name':'port_1', 'type':'logic', 'range':'31{{:}}0', 'dir':'io'},
"               ...
"           }
"           'modports' {
"               'master' [
"                   { 'name':'port_1', 'dir':'i', ...},
"                   { 'name':'port_2', 'dir':'o', ...},
"                   ...
"               ],
"               'slave' [
"                   { 'name':'port_1', 'dir':'o', ...},
"                   { 'name':'port_2', 'dir':'i', ...},
"                   ...
"               ],
"           }
" }
"
function! vlsi#v_sv#YankInterface() abort
    " identifier, number or codegen pattern
    let idregex =  '\%(\w\+\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)*\|\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)\+\)\%(\w\+\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    let mixregex = '\%([^<]*\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    " datatype: logic, wire, AHB_BUS.master
    let datatype = 'logic\|wire\|\w\+\.\w\+'
    let curmodport = ''

    if !exists('g:interfaces')
        let g:interfaces = {}
    endif
    mark z
    let ifbegin = search('\c^\s*\(interface\)','bcnW')
    let ifend   = search('\c^\s*endinterface','cnW')
    if ifbegin == 0 || ifend == 0
        return
    endif
    let linelist = matchlist(getline(ifbegin),'\c^\s*\(interface\)\s*\(' . idregex . '\)')
    if empty(linelist)
        return v:false
    endif
    let ifname = linelist[2]
    "Found interface between ifbegin and ifend with name ifname
    " Check for overwrite
    if has_key(g:interfaces,ifname)
        if input('interface ' . ifname . ' exists! Overwrite (y/n)? ') != 'y'
            echo '    interface capture abandoned!'
            return v:true
        endif
    endif
    " Add interface skeleton
    let g:interfaces[ifname] = { 'generics' : [], 'ports' : [] , 'ports_by_name' : {},
                \ 'modports' : {}, 'lang':'systemverilog'}

    " scope kind
    let kind = -1
    for curline in getline(ifbegin, ifend)
        " skip comments
        if curline =~ '^\s*\/\/'
            continue
        endif
        "parameter a = value;
        let linelist = matchlist(curline,'\c^\s*parameter\s*\(' . idregex . '\)\s*=\s*\([^;,]*\S\)\s*\(;\|,\)')
        if !empty(linelist)
            "TODO capture parameter type ?
            let g:interfaces[ifname].generics += [ { 'name' : linelist[1], 'type' : 'natural', 'value' : linelist[2] } ]
        endif

        "modport mymodport
        let linelist = matchlist(curline,'\c^\s*modport\s*\(' . idregex . '\)')
        if !empty(linelist)
            let kind = 2
            let curmodport = linelist[1]
            let g:interfaces[ifname].modports[curmodport] = []
        endif

        " if we're inside a modport we will have signal direction qualification such as
        " "input hresp,"
        if kind == 2
            let linelist = matchlist(curline,'\c^\s*\(input\|output\|inout\)\s\+\(' . idregex . '\)')
            if !empty(linelist)
                if linelist[1] =~ "input"
                    let dir='i'
                elseif linelist[1] =~ "output"
                    let dir='o'
                else
                    let dir='io'
                endif
                call add(g:interfaces[ifname].modports[curmodport],
                            \ {'name': linelist[2], 'dir': dir})
            endif
        endif

        "interface signals as in "logic [31:0] signame"
        let linelist = matchlist(curline,'\c^\s*\('.datatype.'\)\s*\(.*\)$')
        if !empty(linelist)
            let kind = 1
            let dir='io'
            let port_type = linelist[1]
            let remainder = linelist[2]
            " handle range
            let linelist = matchlist(remainder,'\c^\s*\[\s*\(' . mixregex . '\)\s*:\s*\(' . mixregex . '\)\s*\]\(.*\)$')
            if !empty(linelist)
                "io with a range
                let range = substitute(linelist[1],'\s*$','','') . "{{:}}" . substitute(linelist[2],'\s*$','','')
                let remainder = linelist[3]
            else
                let range = 0
            endif
            let curline = remainder
        else 
            let port_type = ''
        endif
        " normally we only leave the port identifier on the line
        " if it is a port (kind=1)
        if kind == 1
            let portlist = []
            " add every port identifiers to the portlist variable
            call substitute(curline, idregex, '\=add(portlist, submatch(0))', 'g')
            for port in portlist
                let g:interfaces[ifname].ports += [ { 'name' : port, 'dir':'io', 'range' : range, 'type' : port_type } ]
                let g:interfaces[ifname].ports_by_name[port] =  { 'name' : port, 'dir':'io', 'range' : range, 'type' : port_type }
            endfor
        endif
        if match(curline,';') != -1
            let kind = -1
        endif
    endfor

    " Copy missing type and ranges for each port of each modports
    for l:modportname in keys(g:interfaces[ifname].modports)
        for l:elem in g:interfaces[ifname].modports[l:modportname]
            let l:full_port = g:interfaces[ifname].ports_by_name[l:elem.name]
            let l:elem.type  = l:full_port.type
            let l:elem.range = l:full_port.range
        endfor
    endfor

    echo '    Capture for interface ' . ifname . ' successful!'
    return v:true
endfunction

"Parse module around cursor if no module found, look for an interface instead
" this alters the g:modules structure (or potentially g:interfaces described above
" examples for module module_1
" g:modules {
"       'module_1' {
"           'generics' [
"               {   'name' :'bus_width', 'type':'natural', 'value':32 },
"               {...}
"            ],
"           'ports' [ 
"               {   'name':'port_1', 'type':'logic', 'range':'31{{:}}0', 'dir':'i'},
"               {...}
"           ],
" }
function! vlsi#v_sv#Yank() abort
    " identifier, number or codegen pattern
    let idregex =  '\%(\w\+\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)*\|\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)\+\)\%(\w\+\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    let mixregex = '\%([^<]*\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    " datatype: logic, wire, AHB_BUS.master
    let datatype = '\w\+\|\w\+\.\w\+'
    if !exists('g:modules')
        let g:modules = {}
    endif
    mark z
    let modbegin = search('\c^\s*\(module\)','bcnW')
    let modend   = search('\c^\s*endmodule','cnW')
    if modbegin == 0 || modend == 0
        " No module around cursor, look for interface
        if vlsi#v_sv#YankInterface()
            " interface found and captured
            return
        else
            echo 'Could not find module nor interface around cursor!'
        end
        return
    endif
    let linelist = matchlist(getline(modbegin),'\c^\s*\(module\)\s*\(' . idregex . '\)')
    if empty(linelist)
        echo 'No match to module name on line ' . modbegin . '!'
        return
    endif
    let modname = linelist[2]
    "Found module between modbegin and modend with name modname
    " Check for overwrite
    if has_key(g:modules,modname)
        if input('Module ' . modname . ' exists! Overwrite (y/n)? ') != 'y'
            echo '    Module capture abandoned!'
            return
        endif
    endif
    " Add module skeleton
    let g:modules[modname] = { 'generics' : [], 'ports' : [], 'lang' : b:vlsi_config.language }

    " scope kind
    let kind = -1
    for curline in getline(modbegin, modend)
        " skip comments
        let curline = substitute(curline,'\/\/.*$','','g')
        if curline =~ '^\s*$'
            continue
        endif
        "parameter a = value[;,]
        let linelist = matchlist(curline,'\c\<parameter\s*\(' . idregex . '\)\s*=\s*\([^;,].\{-}\)\s*\(;\|,\|$\|)\)\+\s*$')
        if !empty(linelist)
            "TODO capture parameter type ?
            let g:modules[modname].generics += [ { 'name' : linelist[1], 'type' : 'natural', 'value' : linelist[2] } ]
        endif

        "port direction as in "input [31:0] bus"
        let linelist = matchlist(curline,'\c^\s*\(input\|output\|inout\)\s\+\(.*\)$')
        if !empty(linelist)
            " adjust 'dir' variable and set kind scope to 1
            let kind = 1

            if linelist[1] =~ '\c^input'
                let dir ='i'
            elseif linelist[1] =~ '\c^inout'
                let dir = 'io'
            else
                let dir = 'o'
            endif

            let remainder = linelist[2]
        else
            let dir = 'io'
            let remainder = curline
        endif
        " handle optional port type
        let linelist = matchlist(remainder,'\c^\s*\('.datatype.'\)\s*\(.*\)$')
        if !empty(linelist)
            let port_type = linelist[1]
            let remainder = linelist[2]
        else 
            let port_type = ''
        endif
        " handle range
        let linelist = matchlist(remainder,'\c^\s*\[\s*\(' . mixregex . '\)\s*:\s*\(' . mixregex . '\)\s*\]\(.*\)$')
        if !empty(linelist)
            "io with a range
            let range = substitute(linelist[1],'\s*$','','') . "{{:}}" . substitute(linelist[2],'\s*$','','')
            let remainder = linelist[3]
        else
            let range = 0
        endif
        let curline = remainder
        " normally we only leave the port identifier on the line
        " if it is a port (kind=1)
        if kind == 1
            let portlist = []
            " add every port identifiers to the portlist variable
            call substitute(curline, idregex, '\=add(portlist, submatch(0))', 'g')
            for port in portlist
                let g:modules[modname].ports += [ { 'name' : port, 'dir' : dir, 'range' : range, 'type' : port_type } ]
            endfor
        endif
        if match(curline,';') != -1
            let kind = -1
        endif
    endfor
    echo '    Capture for module ' . modname . ' successful!'
endfunction

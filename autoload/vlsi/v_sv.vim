"" Verilog / Systemverilog implementation of VlsiYank / VlsiPaste* 
" Author: Laurent Alacoque


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
    let datatype = 'logic\|wire\|\w\+\.\w\+'
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
    let g:modules[modname] = { 'generics' : [], 'ports' : [], 'lang' : &filetype }

    " scope kind
    let kind = -1
    for curline in getline(modbegin, modend)
        " skip comments
        if curline =~ '^\s*\/\/'
            continue
        endif
        "parameter a = value;
        let linelist = matchlist(curline,'\c^\s*parameter\s*\(' . idregex . '\)\s*=\s*\([^;,]*\S\)\s*\(;\|,\)')
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

" this function iterates over ports and format them using 'formatterFunctionName' function
" this allows code factorization for the Paste* functions
" @arg portList (list of dict) the module ports definition
" @arg formatterFunctionName (str) the formatter function that will be used
" @arg prefix (str) an optionnal prefix for all signals (used in instance and signal pasting)
" @arg suffix (str) an optionnal suffix for all signals (used in instance and signal pasting)
" @return a list of ports definition as strings
function! s:portIterator(portList,formatterFunctionName, suffix='', prefix='', expand=v:false, elem_max_size = {'dir':0, 'name':0, 'range':0, 'type':0})
    if !empty(a:portList)
        " for each port get the max size of each element dir, name, range, type
        let l:ports = []
        for l:state in ['align-pass', 'generate-pass']
            for l:item in a:portList
                let l:portdef = {
                        \ 'dir'         :  s:formatDirection(l:item.dir),
                        \ 'name'        :  l:item.name,
                        \ 'range_start' :  '',
                        \ 'range_end'   :  '',
                        \ 'type'        :  (&filetype == 'verilog' ? 'wire' : 'logic'),
                        \ 'suffix'      :  a:suffix,
                        \ 'prefix'      :  a:prefix,
                        \ 'max_sizes'   :  a:elem_max_size
                        \ }

                " check for complex type
                let interface_elements = matchlist(item.type,'\c^\(\w\+\)\.\(\w\+\)')
                if !empty(interface_elements)
                    " interface type
                    let interface_name = interface_elements[1]
                    let interface_modport = interface_elements[2]
                    " default is to copy the type
                    let l:portdef.type = item.type
                    let l:portdef.dir  = ''
                    " expand interface ports if necessary or asked
                    if a:expand || &filetype == 'verilog'
                        "We should expand the interface
                        if exists('g:interfaces') && has_key(g:interfaces,interface_name)
                            if has_key(g:interfaces[interface_name].modports, interface_modport)
                                "loop over interface.modports ports
                                if l:state == 'generate-pass'
                                    let l:if_ports = s:portIterator(
                                                \ g:interfaces[interface_name].modports[interface_modport],
                                                \ a:formatterFunctionName, 
                                                \ a:suffix, a:prefix .. item.name .. "_", a:expand, a:elem_max_size)
                                    let l:if_ports[0] =  "    // Expansion of interface "..item.type .. " start\x01" .. l:if_ports[0]
                                    let l:if_ports[-1] = l:if_ports[-1] .. ",\x01    // Expansion of interface "..item.type .. " end"
                                    let l:ports = extend(l:ports, l:if_ports)
                                    continue
                                else
                                    " align-pass
                                    let l:portdef.type = (&filetype == 'verilog' ? 'wire' : 'logic')
                                    let l:portdef.dir  = ''
                                endif
                            else "interface modport doesn't exist
                                if l:state == 'generate-pass'
                                    "no modport of this name for this interface
                                    echohl WarningMsg
                                    echo 'Interface expansion: Unknown modport ' .. interface_modport
                                                \ .. ' for interface ' .. interface_name
                                    echohl None
                                endif
                            endif "interface modport
                        else "interface name doesn't exist
                            if l:state == 'generate-pass'
                                " no interface of this name
                                echohl WarningMsg
                                echo 'Interface expansion: Unknown interface ' .. interface_name .. ' (did you VlsiYank it?)'
                                echohl None
                            endif
                        endif " interface name
                    endif "expand
                endif

                " check for range in the form 23{{:}}43
                let l:rangelist = matchlist(l:item.range, '\(.*\){{:}}\(.*\)')
                if !empty(l:rangelist)
                    let l:portdef.range_start = l:rangelist[1]
                    let l:portdef.range_end   = l:rangelist[2]
                endif

                if l:state == 'generate-pass'
                    " Call formatter to format l:portdef
                    " e.g. moduleIOFormatter(l:portdef)
                    let l:port_full_def = eval("".. a:formatterFunctionName .. "(" .. string(l:portdef) .. ')')

                    " Add returned string to the list of ports
                    call add(l:ports, l:port_full_def)
                elseif l:state == 'align-pass'
                    " only measure sizes
                    let a:elem_max_size.dir   = (a:elem_max_size.dir   < len(l:portdef.dir ) ? len(l:portdef.dir ) : a:elem_max_size.dir)
                    let a:elem_max_size.type  = (a:elem_max_size.type  < len(l:portdef.type) ? len(l:portdef.type) : a:elem_max_size.type)
                    let a:elem_max_size.name  = (a:elem_max_size.name  < len(l:portdef.name) ? len(l:portdef.name) : a:elem_max_size.name)
                    let l:range_size = len(s:formatRange(l:portdef))
                    let a:elem_max_size.range = (a:elem_max_size.range < l:range_size   ? l:range_size   : a:elem_max_size.range)
                endif
            endfor "Foreach port
        endfor " align-pass / generate-pass
    endif
    return l:ports
endfunction

" format a range from a port definition
function! s:formatRange(port)
    if a:port.range_start == ''
        return ''
    endif

    return '[' .. a:port.range_start .. ':' .. a:port.range_end .. ']'
endfunction

" format a port direction
function! s:formatDirection(module_port_dir)
    " transform standardized kinds 'i','o','io' into 6 letters verilog directions
    let l:kind2dir = {'i':'input', 'o':'output', 'io': 'inout'}
    return kind2dir[a:module_port_dir]
endfunction

" define the formatting function for module IOs
function! s:moduleIOFormatter(port)
    let l:format = printf("    %%-%ds %%-%ds %%-%ds %%s",
                \ a:port.max_sizes.dir,
                \ a:port.max_sizes.type,
                \ a:port.max_sizes.range)
    return printf(l:format, a:port.dir, a:port.type, s:formatRange(a:port), a:port.prefix .. a:port.name .. a:port.suffix)
endfunction


"Insert entity defined a:name as 'module'
function! vlsi#v_sv#PasteAsModule(name)
    " Find module name or ask for it
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Module to paste as module? ', '', 'customlist,vlsi#ListModules')
    endif

    " get current line
    let lnum = line('.')

    " write module definition into moduledef string
    let l:moduledef = ''
    if has_key(g:modules, name)
        " start the module, NOTE: we use \x01 char for newlines marker
        let l:moduledef .= 'module '. name 

        if !empty(g:modules[name].generics) 
            " start generics
            let l:moduledef .= " #(\x01"
            " Handle generics
            let l:gen_list = []
            for item in g:modules[name].generics
                call add(l:gen_list, '    parameter ' .. item.name .. " = " .. item.value)
            endfor
            "concatenate generics using comma and eol
            let l:moduledef .= join(l:gen_list,",\x01")
            " end generics
            let l:moduledef .= "\x01)"
        endif

        " start module ports
        let l:moduledef .= " (\x01"

        "retrieve ports (using vlsi#v_sv#moduleIOFormatter formatter)
        let l:ports = s:portIterator(g:modules[name].ports,'s:moduleIOFormatter')

        "join the port definition list with ,\x01 marker
        let l:moduledef .= join(l:ports,",\x01")

        "skip a line and close module parens
        let l:moduledef .= "\x01"
        let l:moduledef .= ");\x01"

        " Close module
        let l:moduledef .= "\x01endmodule\x01"

        " append moduledef string at cursor position
        call append(line('.'), split(l:moduledef,"\x01") )
        let lnum = line('.')
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction

" define the formatting function for instance IOs
function! s:instanceIOFormatter(port)
    let l:format = printf("    .%%-%ds (%%-%ds)",
                \ a:port.max_sizes.name,
                \ a:port.max_sizes.name + len(a:port.suffix) +len(a:port.prefix))
    return printf(l:format, a:port.name, a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

"Insert entity defined by a:name as instance
function! vlsi#v_sv#PasteAsInstance(name, signal_suffix='')
    " Find module name or ask for it
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Module to paste as instance? ', '', 'customlist,vlsi#ListModules')
    endif

    " get current line
    let lnum = line('.')

    " write module definition into instancedef string
    let l:instancedef = ''
    if has_key(g:modules, name)
        " start the module, NOTE: we use \x01 char for newlines marker
        let l:instancedef .= name

        " Handle parameters instanciation
        if !empty(g:modules[name].generics)
            "start #( ) parameter instanciation
            let l:instancedef .= " #(\x01"
            "build a list of instance parameters
            let l:instanceparameters = []
            for item in g:modules[name].generics
                " format parameter as '.PARAM (VALUE)'
                call add(l:instanceparameters, "    ." .. item.name .." (" .. item.value ..")")
            endfor
            " join the list with ,\x01
            let l:instancedef .= join(l:instanceparameters,",\x01")
            " terminate the parameter #()
            let l:instancedef .= "\x01)"
        endif

        let l:instancedef .= " u_" .. name .. a:signal_suffix .. " (\x01"

        "retrieve ports (using s:instanceIOFormatter formatter)
        let l:ports = s:portIterator(g:modules[name].ports,'s:instanceIOFormatter',a:signal_suffix )

        "join the port definition list with ,\x01 marker
        let l:instancedef .= join(l:ports,",\x01")

        "skip a line and close module parens
        let l:instancedef .= "\x01"
        let l:instancedef .= ");\x01"

        " append instancedef string at cursor position
        call append(line('.'), split(l:instancedef,"\x01") )
        let lnum = line('.')

    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction


" define the formatting function for instance signals
function! s:instanceSignalFormatter(port)
    " logic [31:0] signame
    let l:format = printf("%%-%ds %%-%ds %%s",
                \ a:port.max_sizes.type,
                \ a:port.max_sizes.range)
    return printf(l:format, a:port.type, s:formatRange(a:port), a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

"Insert entity defined by a:name as instance
function! vlsi#v_sv#PasteSignals(name, signal_suffix='')
    " Find module name or ask for it
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Module to paste interface signals from? ', '', 'customlist,vlsi#ListModules')
    endif

    " get current line
    let lnum = line('.')

    " write module definition into instancedef string
    let l:signalsdef = ''
    if has_key(g:modules, name)
        " start the module, NOTE: we use \x01 char for newlines marker
        let l:signalsdef .= '// Interface signals for u_'  .. name .. a:signal_suffix .. "\x01"

        "retrieve ports (using s:instanceIOFormatter formatter)
        let l:ports = s:portIterator(g:modules[name].ports,'s:instanceSignalFormatter',a:signal_suffix)

        "join the port definition list with ,\x01 marker
        let l:signalsdef .= join(l:ports,";\x01")

        "skip a line and finish
        let l:signalsdef .= ";\x01\x01"

        " append instancedef string at cursor position
        call append(line('.'), split(l:signalsdef,"\x01") )
        let lnum = line('.')
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction

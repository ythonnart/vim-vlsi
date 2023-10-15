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
"           'modports' {
"               'master' {
"                   'port_1': 'i',
"                   'port_2': 'o',
"                   ...
"               },
"               'slave' {
"                   'port_1': 'o',
"                   'port_2': 'i',
"                   ...
"               },
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
    let ifbegin = search('\c^\s*\(interface\)','bcn')
    let ifend   = search('\c^\s*endinterface','cn')
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
    let g:interfaces[ifname] = { 'generics' : [], 'ports' : [] , 'modports' : {}}

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
            let g:interfaces[ifname].modports[curmodport] = {}
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
                let g:interfaces[ifname].modports[curmodport][linelist[2]] = dir
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
            endfor
        endif
        if match(curline,';') != -1
            let kind = -1
        endif
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
    let modbegin = search('\c^\s*\(module\)','bcn')
    let modend   = search('\c^\s*endmodule','cn')
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
    let g:modules[modname] = { 'generics' : [], 'ports' : [] }

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
" @arg moduleName (str) the module name
" @arg formatterFunctionName (str) the formatter function that will be used
" @arg suffix (str) an optionnal suffix for all signals (used in instance and signal pasting)
" @return a list of ports definition as strings
function! s:portIterator(moduleName,formatterFunctionName, suffix='')
    if !empty(g:modules[a:moduleName].ports)
        " for each port get the max size of each element dir, name, range, type
        let l:elem_max_size = {'dir':0, 'name':0, 'range':0, 'type':0}
        let l:ports = []
        for l:state in ['align-pass', 'generate-pass']
            for l:item in g:modules[a:moduleName].ports
                let l:portdef = {
                        \ 'dir'         :  s:formatDirection(l:item.dir),
                        \ 'name'        :  l:item.name,
                        \ 'range_start' :  '',
                        \ 'range_end'   :  '',
                        \ 'type'        :  (&filetype == 'verilog' ? 'wire' : 'logic'),
                        \ 'suffix'      :  a:suffix,
                        \ 'max_sizes'   :  l:elem_max_size
                        \ }

                " check for complex type
                if item.type =~ '\w\+\.\w\+'
                    " interface type
                    " TODO allow expand when the type is in g:interfaces
                    let l:portdef.type = item.type
                    let l:portdef.dir  = ''
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
                    let l:elem_max_size.dir   = (l:elem_max_size.dir   < len(l:portdef.dir ) ? len(l:portdef.dir ) : l:elem_max_size.dir)
                    let l:elem_max_size.type  = (l:elem_max_size.type  < len(l:portdef.type) ? len(l:portdef.type) : l:elem_max_size.type)
                    let l:elem_max_size.name  = (l:elem_max_size.name  < len(l:portdef.name) ? len(l:portdef.name) : l:elem_max_size.name)
                    let l:range_size = len(s:formatRange(l:portdef))
                    let l:elem_max_size.range = (l:elem_max_size.range < l:range_size   ? l:range_size   : l:elem_max_size.range)
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
    return printf(l:format, a:port.dir, a:port.type, s:formatRange(a:port), a:port.name)
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
        let l:ports = s:portIterator(name,'s:moduleIOFormatter')

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
                \ a:port.max_sizes.name + len(a:port.suffix))
    return printf(l:format, a:port.name, a:port.name .. a:port.suffix)
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
        let l:ports = s:portIterator(name,'s:instanceIOFormatter',a:signal_suffix )

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
    return printf(l:format, a:port.type, s:formatRange(a:port), a:port.name .. a:port.suffix)
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
        let l:ports = s:portIterator(name,'s:instanceSignalFormatter',a:signal_suffix)

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

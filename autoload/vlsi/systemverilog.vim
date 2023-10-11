"Parse module around cursor
function! vlsi#systemverilog#Yank() abort
    "let idregex =  '\%(\w\+\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)*\|\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)\+\)\%(\w\+\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    " identifier number or codegen pattern
    let idregex =  '\%(\w\+\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)*\|\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)\+\)\%(\w\+\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    let mixregex = '\%([^<]*\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    if !exists('g:modules')
        let g:modules = {}
    endif
    mark z
    let modbegin = search('\c^\s*\(module\)','bcn')
    let modend   = search('\c^\s*endmodule','cn')
    if modbegin == 0 || modend == 0
        echo 'Could not find module around cursor!'
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
            " handle optional port type
            let linelist = matchlist(remainder,'\c^\s*\(logic\)\s*\(.*\)$')
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
        endif
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

function! s:portIterator(moduleName,formatterFunctionName, suffix='')
    if has_key(g:modules, a:moduleName)
        if !empty(g:modules[a:moduleName].ports)
            let l:ports = []
            " transform standardized kinds 'i','o','io' into 6 letters verilog directions
            let l:kind2dir = {'i':'input ', 'o':'output', 'io': 'inout '}
            " for each port
            for l:item in g:modules[a:moduleName].ports
                " direction
                let l:dir = l:kind2dir[item.dir]
                " name
                let l:name = l:item.name
                " check for range in the form 23{{:}}43
                let l:rangelist = matchlist(l:item.range, '\(.*\){{:}}\(.*\)')
                if !empty(l:rangelist)
                    let l:range = '[' . l:rangelist[1] . ':' . l:rangelist[2] . ']'
                else
                    let l:range = ""
                endif

                " check for type
                let l:type = '     ' "blanks, the size of 'logic' for alignment
                if has_key(l:item,'type')
                    let l:type = l:item.type
                endif
                let l:port_full_def = eval("".. a:formatterFunctionName .. "('" .. l:dir .. "','" .. l:type .."','" .. l:range .. "','" .. l:name .. "','" .. a:suffix .. "')")
                "echo l:port_full_def
                call add(l:ports, l:port_full_def)
            endfor
        endif
        return l:ports
    else
        echo '    Unknown entity ' . a:moduleName . '!'
    endif
endfunction


" define the formatting function for module IOs
function! s:moduleIOFormatter(dir, type, range, name, signal_suffix ='')
    return "    " .. a:dir .. " " .. a:type .. " " .. a:range .. " " .. a:name
endfunction


"Insert entity defined a:name as 'module'
function! vlsi#systemverilog#PasteAsModule(name)
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

        "retrieve ports (using vlsi#systemverilog#moduleIOFormatter formatter)
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
function! s:instanceIOFormatter(dir, type, range, name, signal_suffix ='')
    return "    .".. a:name .. "(" .. a:name .. a:signal_suffix .. ")"
endfunction

"Insert entity defined by a:name as instance
function! vlsi#systemverilog#PasteAsInstance(name, signal_suffix='')
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
        let l:instancedef .= ''.. name .. " u_" .. name .. a:signal_suffix .. " (\x01"

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

        "TODO handle generics
        " if !empty(g:modules[name].generics)
        "     for item in g:modules[name].generics
        "         call append(lnum, 'parameter ' . item.name . ' = ' . item.value . ' ;')
        "         let lnum = lnum + 1
        "     endfor
        "     call append(lnum, [''])
        "     let lnum = lnum + 1
        " endif
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction


" define the formatting function for instance signals
function! s:instanceSignalFormatter(dir, type, range, name, signal_suffix ='')
    return "" .. a:type .. " " .. a:range .. " " .. a:name .. a:signal_suffix
endfunction

"Insert entity defined by a:name as instance
function! vlsi#systemverilog#PasteInstanceSignals(name, signal_suffix='')
    " Find module name or ask for it
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Module to paste as signals from? ', '', 'customlist,vlsi#ListModules')
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

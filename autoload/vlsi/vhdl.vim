" helper function to define keyword case
function ChangeCase(str)
    if exists('g:vlsi_vhdl_uppercase') && g:vlsi_vhdl_uppercase == 1
        return toupper(a:str)
    else
        return a:str
    endif 
endfunction

" format a range from a port definition
function! vlsi#vhdl#formatRange(port) dict
    if a:port.range_start == ''
        return ''
    endif
    return '(' .. a:port.range_start .. ChangeCase(' downto ') . a:port.range_end .. ')'
endfunction

"Parse entity around cursor
function! vlsi#vhdl#Yank() abort
    let idregex  = '\%(\w\+\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)*\|\%(<[if]>\%([^<]\|<[^\/]\)*<\/[if]>\)\+\)\%(\w\+\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    let mixregex = '\%([^<]*\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    if !exists('g:modules')
        let g:modules = {}
    endif
    mark z
    let entbegin = search('\c^\s*\(entity\|component\)','bcnW')
    let entend   = search('\c^\s*end','cnW')
    if entbegin == 0 || entend == 0
        echo 'Could not find entity or component around cursor!'
        return
    endif
    let linelist = matchlist(getline(entbegin),'\c^\s*\(entity\|component\)\s*\(' . idregex . '\)')
    if empty(linelist)
        echo 'No match to entity or component on line ' . entbegin . '!'
        return
    endif
    let modname = linelist[2]
    if has_key(g:modules,modname)
        if input('Entity ' . modname . ' exists! Overwrite (y/n)? ') != 'y'
            echo '    Entity capture abandoned!'
            return
        endif
    endif
    let g:modules[modname] = { 'generics' : [], 'ports' : [], 'lang' : b:vlsi_config.language }
    let kind = -1
    for curline in getline(entbegin, entend)
        if match(curline,'\cgeneric') != -1
            let kind = 0
        endif
        if match(curline,'\cport') != -1
            let kind = 1
        endif
        let linelist = matchlist(curline,'\c^\s*\(' . idregex . '\)\s*:\s*\(.\{-}\S\)\s*\(\($\|;\|--\)\|:=\s*\(.\{-}\S\)\s*\($\|;\|--\)\)')
        if kind == 0 && !empty(linelist)
            let linelist[2] = tolower(linelist[2])
            let g:modules[modname].generics += [ { 'name' : linelist[1], 'type' : linelist[2], 'value' : linelist[5] } ]
        endif
        let linelist = matchlist(curline,'\c^\s*\(' . idregex . '\)\s*:\s*\(in\|out\|inout\)\s*\(.\{-}\S\)\s*\($\|;\|--\)')
        if kind == 1 && !empty(linelist)
            if linelist[2] =~ '\c^i'
                if linelist[2] =~ '\c^inout'
                    let dir = 'io'
                else
                    let dir = 'i'
                endif
            elseif linelist[2] =~ '\c^o'
                let dir = 'o'
            else
                echo '    Entity capture abandoned!'
                return
            endif
            let rangelist = matchlist(linelist[3],'\cvector\s*(\s*\(' . mixregex . '\)\s*downto\s*\(' . mixregex . '\)\s*)')
            if !empty(rangelist)
                let range = substitute(rangelist[1],'\s*$','','') . "{{:}}" . substitute(rangelist[2],'\s*$','','')
            else
                let range = 0
            endif
            let g:modules[modname].ports += [ { 'name' : linelist[1], 'dir' : dir, 'range' : range } ]
        endif
    endfor
    echo '    Capture for entity ' . modname . 'successful!'
endfunction

"Insert entity defined a:name as 'ENTITY'
function! vlsi#vhdl#PasteAsEntity(name)
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Entity to paste as entity? ', '', 'customlist,vlsi#ListModules')
    endif
    let lnum = line('.')
    if has_key(g:modules, name)
        call append(lnum, ChangeCase('entity ') . name . ChangeCase(' is')) 
        let lnum = lnum + 1
        if !empty(g:modules[name].generics)
            call append(lnum, ChangeCase('  generic ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].generics
                let arglist += [ '    ' . item.name . ' : ' . ChangeCase(item.type) . ' := ' . item.value . ' ;' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  );')
            let lnum = lnum + 1
        endif
        if !empty(g:modules[name].ports)
            call append(lnum, ChangeCase('  port ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].ports
                if item.dir == 'i'
                    let dir = ChangeCase('in ')
                elseif item.dir == 'io'
                    let dir = ChangeCase('inout')
                else
                    let dir = ChangeCase('out')
                endif
                let rangelist = matchlist(item.range, '\(.*\){{:}}\(.*\)')
                if !empty(rangelist)
                    let type = ChangeCase('std_logic_vector(') . rangelist[1] . ChangeCase(' downto ') . rangelist[2] . ')'
                else
                    let type = ChangeCase('std_logic')
                endif
                let arglist += [ '    ' . item.name . ' : ' . dir . ' ' . type . ' ;' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  );')
            let lnum = lnum + 1
        endif
        call append(lnum, ChangeCase('end ') . name . ';')
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction

"Insert entity defined by a:name as 'COMPONENT'
function! vlsi#vhdl#PasteAsComponent(name)
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Entity to paste as component? ', '', 'customlist,vlsi#ListModules')
    endif
    let lnum = line('.')
    if has_key(g:modules, name)
        call append(lnum, ChangeCase('  component ') . name) 
        let lnum = lnum + 1
        if !empty(g:modules[name].generics)
            call append(lnum, ChangeCase('    generic ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].generics
                let arglist += [ '      ' . item.name . ' : ' . ChangeCase(item.type) . ' := ' . item.value . ' ;' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  );')
            let lnum = lnum + 1
        endif
        if !empty(g:modules[name].ports)
            call append(lnum, ChangeCase('    port ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].ports
                if item.dir == 'i'
                    let dir = ChangeCase('in ')
                elseif item.dir == 'io'
                    let dir = ChangeCase('inout ')
                else
                    let dir = ChangeCase('out')
                endif
                let rangelist = matchlist(item.range, '\(.*\){{:}}\(.*\)')
                if !empty(rangelist)
                    let type = ChangeCase('std_logic_vector(') . rangelist[1] . ChangeCase(' downto ') . rangelist[2] . ')'
                else
                    let type = ChangeCase('std_logic')
                endif
                let arglist += [ '      ' . item.name . ' : ' . dir . ' ' . type . ' ;' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  );')
            let lnum = lnum + 1
        endif
        call append(lnum, ChangeCase('  end component;'))
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction

"Insert entity defined by a:name as instance
function! vlsi#vhdl#PasteAsInstance(name)
    if !exists('g:modules')
        let g:modules = {}
    endif
    let name = a:name
    if name == ''
        let name = input('Entity to paste as instance? ', '', 'customlist,vlsi#ListModules')
    endif
    let lnum = line('.')
    if has_key(g:modules, name)
        call append(lnum, '  I_' . name . ' : ' . name) 
        let lnum = lnum + 1
        if !empty(g:modules[name].generics)
            call append(lnum, ChangeCase('    generic map ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].generics
                let arglist += [ '      ' . item.name . ' => ' . item.value . ' ,' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  )')
            let lnum = lnum + 1
        endif
        if !empty(g:modules[name].ports)
            call append(lnum, ChangeCase('    port map ('))
            let lnum = lnum + 1
            let arglist = []
            let keynum = 0
            for item in g:modules[name].ports
                let arglist += [ '      ' . item.name . ' => ' . item.name . ' ,' ]
                let keynum = keynum + 1
            endfor
            let arglist[-1] = arglist[-1][:-3]
            call append(lnum, arglist)
            let lnum = lnum + keynum
            call append(lnum, '  );')
            let lnum = lnum + 1
        endif
    else
        echo '    Unknown entity ' . name . '!'
    endif
endfunction

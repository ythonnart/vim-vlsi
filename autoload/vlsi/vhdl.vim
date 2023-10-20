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
    if a:port.range_start > a:port.range_end
        let to_downto = ChangeCase('downto')
    else
        let to_downto = ChangeCase('to')
    endif
    return '(' .. a:port.range_start .. ' ' .. to_downto .. ' ' .. a:port.range_end .. ')'
endfunction


" define the formatting function for instance signals
function! s:instanceSignalFormatter(port)
    " logic [31:0] signame
    " signal signame: sigtype(range)
    let l:format = printf("    "..ChangeCase('signal').." %%-%ds : %%-%ds",
                \ a:port.max_sizes.name + len(a:port.prefix) + len(a:port.suffix),
                \ a:port.max_sizes.type + a:port.max_sizes.range)
    return printf(l:format, 
                \ a:port.prefix .. a:port.name .. a:port.suffix,
                \ a:port.type .. a:port.range)
endfunction

" define the formatting function for module IOs
function! s:entityIOFormatter(port)
    let l:format = printf("    %%-%ds : %%-%ds %%s%%s",
                \ a:port.max_sizes.name + len(a:port.prefix) + len(a:port.suffix),
                \ a:port.max_sizes.dir)

    return printf(l:format, 
                \ a:port.prefix .. a:port.name .. a:port.suffix,
                \ a:port.dir,
                \ a:port.type,
                \ a:port.range)
endfunction

" define the formatting function for instance IOs
function! s:instanceIOFormatter(port)
    let l:format = printf("          %%-%ds => %%-%ds",
                \ a:port.max_sizes.name,
                \ a:port.max_sizes.name + len(a:port.suffix) +len(a:port.prefix))
    return printf(l:format, a:port.name, a:port.prefix .. a:port.name .. a:port.suffix)
endfunction

let vlsi#vhdl#formatPatterns = #{
   \     definition : #{
   \         start_module              : "entity {module_name} is\x01",
   \             start_generics        : "  generic (\x01",
   \                generics_item_func : "    {name} : {type} := {value}",
   \                generics_sep       : ";\x01",
   \             end_generics          : "\x01  );\x01",
   \             start_ports           : "  port (\x01",
   \                port_list_func     : function('s:entityIOFormatter'),
   \                port_list_sep      : ";\x01",
   \             end_ports             : "\x01  );\x01",
   \         end_module                : "end entity {module_name};\x01",
   \     },
   \     component : #{
   \         start_module              : "    component {module_name} is\x01",
   \             start_generics        : "        generic (\x01",
   \                generics_item_func : "          {name} : {type} := {value}",
   \                generics_sep       : ";\x01",
   \             end_generics          : "\x01        );\x01",
   \             start_ports           : "        port (\x01    ",
   \                port_list_func     : function('s:entityIOFormatter'),
   \                port_list_sep      : ";\x01    ",
   \             end_ports             : "\x01        );\x01",
   \         end_module                : "    end component {module_name};\x01",
   \     },
   \     instance : #{
   \         start_module              : "    u_{prefix}{module_name}{suffix} : {module_name}\x01",
   \             start_generics        : "        generic map (\x01",
   \                generics_item_func : "          {name} => {value}",
   \                generics_sep       : ",\x01",
   \             end_generics          : "\x01        )\x01",
   \             start_ports           : "        port map (\x01",
   \                port_list_func     : function('s:instanceIOFormatter'),
   \                port_list_sep      : ",\x01",
   \             end_ports             : "\x01        );\x01",
   \         end_module                : "    -- end instance u_{prefix}{module_name}{suffix}\x01",
   \     },
   \     signals  : #{
   \         start_module              : '',
   \             start_generics        : '',
   \                generics_item_func : '',
   \                generics_sep       : '',
   \             end_generics          : '',
   \             start_ports           : "-- interface signals for {prefix}{module_name}{suffix}\x01",
   \                port_list_func     : function('s:instanceSignalFormatter'),
   \                port_list_sep      : ";\x01",
   \             end_ports             : ";\x01",
   \         end_module                : "-- end of signals for {prefix}{module_name}{suffix}\x01\x01",
   \     },
   \ }
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

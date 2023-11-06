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
   \         start_module              : "component {module_name} is\x01",
   \             start_generics        : "    generic (\x01",
   \                generics_item_func : "        {name} : {type} := {value}",
   \                generics_sep       : ";\x01",
   \             end_generics          : "\x01    );\x01",
   \             start_ports           : "    port (\x01    ",
   \                port_list_func     : function('s:entityIOFormatter'),
   \                port_list_sep      : ";\x01    ",
   \             end_ports             : "\x01    );\x01",
   \         end_module                : "end component {module_name};\x01",
   \     },
   \     instance : #{
   \         start_module              : "u_{prefix}{module_name}{suffix} : {module_name}\x01",
   \             start_generics        : "    generic map (\x01",
   \                generics_item_func : "        {name} => {value}",
   \                generics_sep       : ",\x01",
   \             end_generics          : "\x01    )\x01",
   \             start_ports           : "    port map (\x01",
   \                port_list_func     : function('s:instanceIOFormatter'),
   \                port_list_sep      : ",\x01",
   \             end_ports             : "\x01    )",
   \         end_module                : ";\x01-- end instance u_{prefix}{module_name}{suffix}\x01",
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
    let entbegin = search(b:vlsi_config.entity_regexp.begin,'bcnW')
    let entend   = search(b:vlsi_config.entity_regexp.end,  'cnW')
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
    let g:modules[modname] = { 'generics' : [], 'ports' : [], 'lang' : b:vlsi_config.language, file: expand(bufname('')) }
    let kind = -1
    for curline in getline(entbegin, entend)
        "get rid of comments
        let curline = substitute(curline,'\s*--.*$','','g')
        if curline =~ '^\s*$'
            continue
        endif
        let linelist = matchlist(curline,'\c\(\<generic\>\)\s*\(.*\)')
        if !empty(linelist)
            let kind = 0
            let curline = linelist[2]
        endif
        let linelist = matchlist(curline,'\c\(\<port\>\)\s*\(.*\)')
        if !empty(linelist)
            let kind = 1
            let curline = linelist[2]
        endif

        "let linelist =matchlist(curline,'\c^\s*(*\s*\(' . idregex . '\)\s*:\s*\(.\{-}\S\)\s*\(\($\|;\|--\)\|:=\s*\(.\{-}\S\)\s*\($\|;\|--.*\|)\)\)\(.*\)$')
        "(param1 : natural := 4);
        "param1 : natural := 4;
        let matchpattern = '\c^\s*'
        "optionnal (
        let matchpattern .= '(*\s*'
        "param name until ':'
        let matchpattern .= '\(\w\+\)\s*:\s*' " [1] paramname
        " type until ':='
        "let matchpattern .= '\(\S\{-}\S\)\s*:=\s*' " [2] type
        let matchpattern .= '\([^: \t]\+\)\s*:=\s*' " [2] type
        " value until ';', eol, '-- blah' or ')'
        let matchpattern .= '\(\S\{-}\S\)\s*\(;\|)\|--.*\|$\)' " [3] value [4] termination
        " ^^ DOES not work for param : natural :=4); port(
        " rest of line
        let matchpattern .= '\(.*\)' " [5] rest of line

        let linelist = matchlist(curline,matchpattern)
        if kind == 0 && !empty(linelist)
            let linelist[2] = tolower(linelist[2])
            let g:modules[modname].generics += [ { 'name' : linelist[1], 'type' : linelist[2], 'value' : linelist[3] } ]
            let curline=linelist[5]
        endif
        let linelist = matchlist(curline,'\c^\s*(*\s*\(' . idregex . '\)\s*:\s*\(\<in\>\|\<out\>\|\<inout\>\)\s*\(.\{-}\S\)\s*\($\|;\|--\)')
        if kind == 1 && !empty(linelist)
            if linelist[2] =~ '\c^in\>'
                let dir = 'i'
            elseif linelist[2] =~ '\c^inout'
                let dir ='io'
            else
                let dir ='o'
            endif
            let rangelist = matchlist(linelist[3],'\cvector\s*(\s*\(' . mixregex . '\)\s*downto\s*\(' . mixregex . '\)\s*)')
            if !empty(rangelist)
                let range = substitute(rangelist[1],'\s*$','','') . "{{:}}" . substitute(rangelist[2],'\s*$','','')
                let type  = 'std_logic_vector'
            else
                let range = 0
                let type  = 'std_logic'
            endif
            let g:modules[modname].ports += [ { 'name' : linelist[1], 'dir' : dir, 'range' : range, 'type':type } ]
        endif
    endfor
    let g:Vlsi_last_yanked_entity = modname
    echo '    Capture for entity ' . modname . ' successful!'
endfunction

" Only do this when not done yet for this buffer
if exists("g:vlsi_loaded")
    finish
endif
let g:vlsi_loaded = 1

"Create plugin bindings
function! vlsi#Bindings()
    if !exists('b:VlsiYank')
        let b:VlsiYank = function('vlsi#YankNotDefined')
    endif
    if !exists('b:VlsiPasteAsDefinition')
        let b:VlsiPasteAsDefinition = function('vlsi#PasteAsDefinitionNotDefined')
    endif
    if !exists('b:VlsiPasteAsInterface')
        let b:VlsiPasteAsInterface = function('vlsi#PasteAsInterfaceNotDefined')
    endif
    if !exists('b:VlsiPasteAsInstance')
        let b:VlsiPasteAsInstance = function('vlsi#PasteAsInstanceNotDefined')
    endif
    " Command-line mode
    command! -nargs=0 VlsiYank      :call b:VlsiYank()
    command! -nargs=? VlsiList      :echo join(vlsi#ListModules('<args>','',''),' ')
    command! -nargs=0 VlsiDefineNew :call vlsi#DefineNew()
    command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsDefinition :call b:VlsiPasteAsDefinition('<args>')
    command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsInterface  :call b:VlsiPasteAsInterface('<args>')
    command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsInstance   :call b:VlsiPasteAsInstance('<args>')

    " <Plug> Mappings
    noremap <silent> <Plug>VlsiYank              :call b:VlsiYank     ()<CR>
    noremap <silent> <Plug>VlsiList              :echo join(vlsi#ListModules('<args>','',''),' ')<CR>
    noremap <silent> <Plug>VlsiDefineNew         :call vlsi#DefineNew ()<CR>
    noremap <silent> <Plug>VlsiPasteAsDefinition :call b:VlsiPasteAsDefinition   ('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInterface  :call b:VlsiPasteAsInterface('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInstance   :call b:VlsiPasteAsInstance ('')<CR>

    " Default mappings
    if !hasmapto('<Plug>VlsiDefineNew') &&  maparg('<M-S-F6>','n') ==# ''
        nmap <M-S-F6>  <Plug>VlsiDefineNew
    endif
    if !hasmapto('<Plug>VlsiYank') &&  maparg('<F6>','n') ==# ''
        nmap <F6>  <Plug>VlsiYank
    endif
    if !hasmapto('<Plug>VlsiPasteAsDefinition') &&  maparg('<S-F6>','n') ==# ''
        nmap <S-F6>  <Plug>VlsiPasteAsDefinition
    endif
    if !hasmapto('<Plug>VlsiPasteAsInterface') &&  maparg('<C-F6>','n') ==# ''
        nmap <C-F6>  <Plug>VlsiPasteAsInterface
    endif
    if !hasmapto('<Plug>VlsiPasteAsInstance') &&  maparg('<M-F6>','n') ==# ''
        nmap <M-F6>  <Plug>VlsiPasteAsInstance
    endif
endfunction

"Returns list of all entities
function! vlsi#ListModules(ArgLead,CmdLine,CursorPos)
    if !exists('g:modules')
        let g:modules = {}
    endif
    let listmodules = ''
    return filter(sort(keys(g:modules)), 'v:val =~ "^".a:ArgLead')
endfunction

"Capture Vlsi from user input
function! vlsi#DefineNew() abort
    let mixregex = '\%([^<]*\%(<[if]>\%([^<]\|<[^/]\)*<\/[if]>\)*\)*'
    if !exists('g:modules')
        let g:modules = {}
    endif
    let modname = input('Module name: ')
    if has_key(g:modules,modname)
        if input('Module exists! Overwrite (y/n)? ') != 'y'
            echo '    Module capture abandoned!'
            return
        endif
    endif
    let g:modules[modname] = { 'generics' : [], 'ports' : [] }
    let name = input('New generic parameter name (leave empty if no more): ')
    while name != ''
        let type = input('Generic parameter type: ', 'natural')
        let value = input('Generic parameter value: ', '0')
        let g:modules[modname].generics += [ { 'name' : name, 'type' : type, 'value' : value } ]
        let name = input('New generic parameter name (leave empty if no more): ')
    endwhile
    let name = input('New port name (leave empty if no more): ')
    while name != ''
        let dir = ''
        while dir !~ '^[io]$'
            let dir = input('Port direction (i/o): ', 'i')
        endwhile
        let range = ''
        while range !~ '^\s*\(0\|\[' . mixregex . ':' . mixregex . '\]\)\s*$'
            let range = input('Port range (0 for single wire / [h:l] for bus): ', '0')
        endwhile
        let g:modules[modname].ports += [ { 'name' : name, 'dir' : dir, 'range' : range } ]
        let name = input('New port name (leave empty if no more): ')
    endwhile
    echo '    Capture for module ' . modname . 'successful!'
endfunction

" Default function fallbacks when not defined for filetype
function! vlsi#YankNotDefined(...)
    echoerr 'VlsiYank command not defined for this filetype!'
endfunction
function! vlsi#PasteAsDefinitionNotDefined(...)
    echoerr 'VlsiPasteAsDefinition command not defined for this filetype!'
endfunction
function! vlsi#PasteAsInterfaceNotDefined(...)
    echoerr 'VlsiPasteAsInterface command not defined for this filetype!'
endfunction
function! vlsi#PasteAsInstanceNotDefined(...)
    echoerr 'VlsiPasteAsInstance command not defined for this filetype!'
endfunction


" format a dict based on a pattern string
" item (dict) a 'key' : value dictionary
" format (str or function)
"    - if str: will replace '{key}' by the corresponding item value
"          example " {dir} {type} {name}"
"    - if func: use function to format item
"          example function("myFunc")
"          will call myFunc(item)
function! vlsi#basicFormat(item, format)
    if type(a:format) == v:t_func
        return a:format(a:item)
    elseif type(a:format) == v:t_string
        let format = a:format
        let item   = a:item
        if has_key(item,'max_sizes')
            " has max_sizes, reformat fixed size = item.max_sizes.key
            let keys = []
            " add any keys to keys
            call substitute(format, '{\(\w\+\)}', '\=add(keys, submatch(1))', 'g')
            for key in keys
                if has_key(item.max_sizes,key)
                    let l:size = item.max_sizes[key]
                    "left align string of fixed length
                    let l:fmt = printf("%%-%ds",l:size) " %-8s
                else 
                    let l:size = 0
                    let l:fmt = "%s"
                endif
                let l:value = item[key]
                let item[key] = printf(l:fmt,l:value) " '23      '
            endfor
        endif

        " substitute every occurence of {key} with the value item[key] into str "format"
        return substitute(format,'{\(\w\+\)}','\=item[submatch(1)]','g')
        endif
    else
        echoerr "Invalid type (should be func or string)"
    endif
endfunction

" this function iterates over ports and format them using 'formatterFunctionName' function
" this allows code factorization for the Paste* functions
" @arg portList (list of dict) the module ports definition
" @arg formatter (function) the formatter function that will be used
" @arg defaults (dict) contains keys for langage : comment:"//", type:"wire', kind2dir:{'i':'input',... formatRange:function('formatter')
" @arg prefix (str) an optionnal prefix for all signals (used in instance and signal pasting)
" @arg suffix (str) an optionnal suffix for all signals (used in instance and signal pasting)
" @return a list of ports definition as strings
function! vlsi#portIterator(portList, formatter, suffix='', prefix='', expand=v:false, elem_max_size = {})
    if !empty(a:portList)
        let l:ports = []
        for l:state in ['align-pass', 'generate-pass']
            for l:item in a:portList
                let l:portdef = {
                        \ 'dir'         :  b:vlsi_config.kind2dir[l:item.dir],
                        \ 'name'        :  l:item.name,
                        \ 'range_start' :  '',
                        \ 'range_end'   :  '',
                        \ 'range'       :  '',
                        \ 'type'        :  b:vlsi_config.default_scalar_type,
                        \ 'suffix'      :  a:suffix,
                        \ 'prefix'      :  a:prefix,
                        \ 'max_sizes'   :  a:elem_max_size,
                        \ 'config'      :  b:vlsi_config
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
                    if a:expand || b:vlsi_config.language != 'systemverilog'
                        "We should expand the interface
                        if exists('g:interfaces') && has_key(g:interfaces,interface_name)
                            if has_key(g:interfaces[interface_name].modports, interface_modport)
                                "loop over interface.modports ports
                                if l:state == 'generate-pass'
                                    let l:if_ports = vlsi#portIterator(
                                                \ g:interfaces[interface_name].modports[interface_modport],
                                                \ a:formatter,
                                                \ a:suffix, a:prefix .. item.name .. "_", a:expand, a:elem_max_size)
                                    let l:if_ports[0] =  "    ".. b:vlsi_config.comment .." Expansion of interface "..item.type .. " start\x01" .. l:if_ports[0]
                                    let l:if_ports[-1] = l:if_ports[-1] .. ",\x01    ".. b:vlsi_config.comment .." Expansion of interface "..item.type .. " end"
                                    let l:ports = extend(l:ports, l:if_ports)
                                    continue
                                else
                                    " align-pass
                                    let l:portdef.type = b:vlsi_config.default_scalar_type
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
                    " Add formatted range
                    let l:portdef.range = b:vlsi_config.formatRange(l:portdef)
                    " switch to vector type
                    let l:portdef.type  = b:vlsi_config.default_vector_type
                endif

                "Actually format
                if l:state == 'generate-pass'
                    " Call formatter to format l:portdef
                    " e.g. moduleIOFormatter(l:portdef)
                    let l:port_full_def = vlsi#basicFormat(l:portdef,a:formatter)

                    " Add returned string to the list of ports
                    call add(l:ports, l:port_full_def)
                elseif l:state == 'align-pass'
                    " update each field max size for alignment
                    for key in keys(l:portdef)
                        if !has_key(a:elem_max_size,key)
                            let a:elem_max_size[key] = 0
                        endif
                        let val = l:portdef[key]
                        if type(val) == v:t_number || type(val) == v:t_string || type(val) == v:t_float
                            let a:elem_max_size[key] = (a:elem_max_size[key] < len(val) ?
                                                        \ len(val) : a:elem_max_size[key])
                        endif
                    endfor "align-pass
                endif "field size computation / port generation
            endfor "Foreach port
        endfor " align-pass / generate-pass
    endif
    return l:ports
endfunction

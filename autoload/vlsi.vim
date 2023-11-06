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
    if !exists('b:VlsiPasteSignals')
        let b:VlsiPasteSignals = function('vlsi#PasteSignalsNotDefined')
    endif

    " Command-line mode
    command! -nargs=0                                       VlsiYank              :call b:VlsiYank()
    command! -nargs=* -complete=file                        VlsiYankAll           :call vlsi#YankAll(<f-args>)
    command! -nargs=?                                       VlsiList              :echo join(vlsi#ListModules('<args>','',''),' ')
    command! -nargs=?                                       VlsiListInterfaces    :echo join(vlsi#ListInterfaces('<args>','',''),' ')
    command! -nargs=0                                       VlsiDefineNew         :call vlsi#DefineNew()
    command! -nargs=* -complete=customlist,vlsi#ListModules VlsiPasteAsDefinition :call b:VlsiPasteAsDefinition(<f-args>)
    command! -nargs=* -complete=customlist,vlsi#ListModules VlsiPasteAsInterface  :call b:VlsiPasteAsInterface(<f-args>)
    command! -nargs=* -complete=customlist,vlsi#ListModules VlsiPasteAsInstance   :call b:VlsiPasteAsInstance(<f-args>)
    command! -nargs=* -complete=customlist,vlsi#ListModules VlsiPasteSignals      :call b:VlsiPasteSignals(<f-args>)

    " <Plug> Mappings
    noremap <silent> <Plug>VlsiYank              :call b:VlsiYank                ()<CR>
    noremap <silent> <Plug>VlsiYankAll           :call b:VlsiYankAll             ()<CR>
    noremap <silent> <Plug>VlsiList              :echo join(vlsi#ListModules     ('<args>','',''),' ')<CR>
    noremap <silent> <Plug>VlsiListInterface     :echo join(vlsi#ListInterfaces  ('<args>','',''),' ')<CR>
    noremap <silent> <Plug>VlsiDefineNew         :call vlsi#DefineNew            ()<CR>
    noremap <silent> <Plug>VlsiPasteAsDefinition :call b:VlsiPasteAsDefinition   ('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInterface  :call b:VlsiPasteAsInterface    ('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInstance   :call b:VlsiPasteAsInstance     ('')<CR>
    noremap <silent> <Plug>VlsiPasteSignals      :call b:VlsiPasteSignals        ('')<CR>

    " Default mappings
    if !hasmapto('<Plug>VlsiDefineNew') &&  maparg('<M-S-F6>','n') ==# ''
        nmap <M-S-F6>  <Plug>VlsiDefineNew
    endif

    if !hasmapto('<Plug>VlsiYank') 
        if maparg('<M-F6>','n') ==# ''
            nmap <M-F6>  <Plug>VlsiYank
        endif
        if maparg('<leader>y','n') ==# ''
            nmap <leader>y <Plug>VlsiYank
        endif
    endif

    if !hasmapto('<Plug>VlsiYankAll') 
        if maparg('<C-M-F6>','n') ==# ''
            nmap <C-M-F6>  <Plug>VlsiYankAll
        endif
        if maparg('<leader>yy','n') ==# ''
            nmap <leader>yy <Plug>VlsiYankAll
        endif
    endif

    if !hasmapto('<Plug>VlsiPasteAsDefinition')
        if maparg('<S-F6>','n') ==# ''
            nmap <S-F6>  <Plug>VlsiPasteAsDefinition
        endif
        "pe as in paste entity
        if maparg('<leader>pe','n') ==# ''
            nmap <leader>pe <Plug>VlsiPasteAsDefinition
        endif
        "pm as in paste module
        if maparg('<leader>pm','n') ==# ''
            nmap <leader>pm <Plug>VlsiPasteAsDefinition
        endif
    endif
    if !hasmapto('<Plug>VlsiPasteAsInterface')
        if maparg('<C-F6>','n') ==# ''
            nmap <C-F6>  <Plug>VlsiPasteAsInterface
        endif
        "pc as in paste component
        if maparg('<leader>pc','n') ==# ''
            nmap <leader>pc <Plug>VlsiPasteAsInterface
        endif
    endif
    if !hasmapto('<Plug>VlsiPasteAsInstance') 
        if maparg('<F6>','n') ==# ''
            nmap <F6>  <Plug>VlsiPasteAsInstance
        endif
        "pi as in paste instance
        if maparg('<leader>pi','n') ==# ''
            nmap <leader>pi <Plug>VlsiPasteAsInstance
        endif
    endif
    if !hasmapto('<Plug>VlsiPasteSignals') 
        "ps as in paste signals
        if maparg('<leader>ps','n') ==# ''
            nmap <leader>ps <Plug>VlsiPasteSignals
        endif
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

"Returns list of all systemverilog interfaces
function! vlsi#ListInterfaces(ArgLead,CmdLine,CursorPos)
    if !exists('g:interfaces')
        let g:modules = {}
    endif
    let listinterfaces = ''
    return filter(sort(keys(g:interfaces)), 'v:val =~ "^".a:ArgLead')
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
    let g:modules[modname] = { 'generics' : [], 'ports' : [], 'lang'='',  'file'=''}
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
    echo '    Capture for module ' . modname . ' successful!'
endfunction

"Yank all modules inside current buffer or list of files
function! vlsi#YankAll(...)

    "set list of files to be yanked
    let l:file_list = copy(a:000)
    if len(l:file_list) == 0
        " No argument, add current buffer to file list
        let l:file_list += [bufname('')]
    endif
    " remember g:Vlsi_last_yanked_entity to restore it at the end
    if exists('g:Vlsi_last_yanked_entity')
        let l:saved_last_yanked_entity = g:Vlsi_last_yanked_entity
    else
        let l:saved_last_yanked_entity = v:none
    endif

    "iterate over files
    for data_file in file_list
        " expand funny things like '%', '~/', ...
        let data_file = expand(data_file)

        " load the buffer if needed and attribute it to a window
        " remember if we use 'split' and 'edit'
        let I_splitted = 0
        let I_loaded   = 0
        if !bufexists(expand(data_file))
            " The buffer doesn't exist. load it
            split
            let I_loaded = 1
            echomsg "VlsiYankAll: loading " .. data_file
            hide edit `=data_file`
        elseif bufwinnr(data_file) != -1
            " The buffer exists, and it has a window.
            execute bufwinnr(data_file) 'wincmd w'
        else
            " The buffer exists, but it has no window.
            split
            let I_splitted = 1
            execute 'buffer' bufnr(data_file)
        endif

        " Buffer opened and loaded into a window
        " Check if the buffer has the yank function
        if !exists('b:VlsiYank')
            "Hu Ho, this buffer can't yank, skip it
            echohl WarningMsg | echo "Invalid file for VlsiYankAll: " .. data_file | echohl None
        else
            "Buffer loaded and ready to yank
            try
                "load start and end patterns for this file
                let entbegin = b:vlsi_config.entity_regexp.begin
                let entend   = b:vlsi_config.entity_regexp.end

                "move to the start of buffer
                normal! gg
                "find the next entity
                while search(entbegin, 'cW')
                    " Yank entity just found
                    VlsiYank
                    " move to the end of entity
                    call search(entend, 'cW')
                endwhile

            catch 'E121\|E716'
                "E121 : vlsi_config doesn't exist
                "E716 : invalid key
                echohl Error | echo "Missing configuration b:vlsi_config.entity_regexp for buffer, " ..
                            \ "check ftplugin" | echohl None
            endtry
        endif

        " housekeeping
        if I_splitted
            "close window
            close!
        endif
        if I_loaded
            "unload buffer (and close split)
            bdelete!
        endif

        "restore Vlsi_last_yanked_entity (if needed)
        if l:saved_last_yanked_entity == v:none
            "was not defined, unlet if it exits
            if exists('g:Vlsi_last_yanked_entity')
                unlet g:Vlsi_last_yanked_entity
            endif
        else
            "preexisting, restore the value
            let g:Vlsi_last_yanked_entity = l:saved_last_yanked_entity
        endif

    endfor "file list
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
function! vlsi#PasteSignalsNotDefined(...)
    echoerr 'VlsiPasteSignals command not defined for this filetype!'
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
        let item   = deepcopy(a:item) " we will change it
        let item.max_sizes = get(item,'max_sizes',{}) " add 'max_sizes' if needed
        let format = a:format

        let keys = []
        " harvest any keys to l:keys
        call substitute(format, '{\(\w\+\)}', '\=add(keys, submatch(1))', 'g')
        for ckey in keys
            "ckey is a key with case preserved
            let key = tolower(ckey)

            if !has_key(item,key)
                "doesn't have this key, we shouldn't change this
                let item[ckey] = "{"..ckey.."}"
            else
                if has_key(item.max_sizes,key)
                    "has a max_size => format with padding
                    let l:size = item.max_sizes[key]
                    "left align string of fixed length
                    let l:fmt = printf("%%-%ds",l:size) " %-8s
                    let l:value = item[key]
                    let item[key] = printf(l:fmt,l:value) " '23      '
                else 
                    let item[key] = printf("%s",item[key])
                endif
                " ensure that {CaSeKey} = {casekey}
                let item[ckey] = item[key]
            endif "key doesn't exist
        endfor

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
function! vlsi#portIterator(portList, formatter, suffix='', prefix='', expand=v:false, elem_max_size = {}, if_port_prefix ='')
    if !empty(a:portList)
        let l:ports = []
        for l:state in ['align-pass', 'generate-pass']
            for l:item in a:portList
                let l:portdef = {
                        \ 'dir'         :  b:vlsi_config.kind2dir[l:item.dir],
                        \ 'name'        :  a:if_port_prefix .. l:item.name,
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
                                                \ a:suffix, a:prefix , a:expand, a:elem_max_size, item.name .. '_')
                                    let l:if_ports[0] =  "    ".. b:vlsi_config.comment .." Expansion of interface "..item.type .. " start\x01" .. l:if_ports[0]
                                    "let l:if_ports = l:if_ports + ["    ".. b:vlsi_config.comment .." Expansion of interface "..item.type .. " end"]
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


" Paste module 'moduleName' using patterns defined in patterns
" patterns should look like this dict, where each line is either
" a string (all {key} will be replaced by the corresponding item[key] value)
" or a function that will get item and should return a string
" NOTE: "\x01" char will be replaced by newlines
" example pattern for verilog module
"     #{
"        \ start_module          : "module {module_name}",
"
"            \ start_generics        : " #(\x01",
"               \ generics_item_func    : "    parameter {name} = {value}",
"               \ generics_sep          : ",\x01",
"            \ end_generics          : "\x01    )",
"
"            \ start_ports           : " (\x01",
"               \ port_list_func        : function('s:moduleIOFormatter'),
"               \ port_list_sep         : ",\x01",
"            \ end_ports             : "\x01);\x01",
"        \ end_module            : "\x01endmodule //{module_name}\x01",
"    \ }
"
" the (start|end)_* formatters are called with #{module_name: 'module name', prefix:'...', suffix:'...'} argument
" the generics_item_func formatter will be called with g:modules.moduleName.generics items
" the port_list_func formatter will be called by vlsi#portIterator enhanced g:modules.moduleName.ports
"
function! vlsi#GenericPaste(patterns, moduleName='', suffix='', prefix='', expand=v:false)
    let result = ""
    " Fool-proof
    if !exists('g:modules')
        let g:modules = {}
    endif

    " Find module name or ask for it
    let moduleName = a:moduleName
    if moduleName == ''
        "unspecified modulename, do we have a last_yanked entity ?
        if exists('g:Vlsi_last_yanked_entity')
            " unspecified moduleName but an entity was yanked, use that
            let moduleName= g:Vlsi_last_yanked_entity
        else
            " unspecified moduleName and no last_yanked entity, ask
            let moduleName = input('Module to paste ? ', '', 'customlist,vlsi#ListModules')
            echo "\r"
        endif
    endif

    if !has_key(g:modules,moduleName)
        echohl ErrorMsg
        echo "Module " .. moduleName .. " doesn't exist"
        echohl WarningMsg
        echo "(Maybe VlsiYank it first?)"
        echohl None
        return
    endif

    let mod_def = g:modules[moduleName]
    let mod_val = {'module_name': moduleName, 'prefix':a:prefix, 'suffix':a:suffix}

    " module start
    let result .= vlsi#basicFormat(mod_val,a:patterns.start_module)

    " generics
    if has_key(mod_def,'generics') && !empty(mod_def.generics)
        " generics
        let result .= vlsi#basicFormat(mod_val,a:patterns.start_generics)
        let generics_lines = []
        " iterate through generics
        for item in mod_def.generics
            call add(l:generics_lines, vlsi#basicFormat(item,a:patterns.generics_item_func))
        endfor
        " assemble generics
        let result .= join(generics_lines, a:patterns.generics_sep)
        " end generics
        let result .= vlsi#basicFormat(mod_val,a:patterns.end_generics)
    endif

    "between generics and ports
    if has_key(a:patterns,'gen2port')
        let result .= vlsi#basicFormat(mod_val,a:patterns.gen2port)
    endif

    " ports
    if has_key(mod_def,'ports') && !empty(mod_def.ports)
        let result .= vlsi#basicFormat(mod_val,a:patterns.start_ports)
        let port_lines = vlsi#portIterator(
            \ mod_def.ports,
            \ a:patterns.port_list_func,
            \ a:suffix, a:prefix, a:expand)
        " assemble ports
        let result .= join(port_lines, a:patterns.port_list_sep)
        let result .= vlsi#basicFormat(mod_val,a:patterns.end_ports)
    endif

    " end module
    let result .= vlsi#basicFormat(mod_val,a:patterns.end_module)

    " We now add padding to the left of each line that is exactly 
    " the current cursor position
    "construct padding of spaces (with the size of current column)
    let padding = printf(printf("%%%ds",col('.')),'')
    " add the padding after each linebreak
    let l:result = substitute(padding .. result, "\x01", "\x01" .. padding, 'g')
    " cleanup unused spaces
    let l:result = substitute(l:result,"\x01\s\+\x01","\x01\x01",'g')
    " split on \x01
    let l:result = split(l:result,"\x01")
    let l:result_count = len(l:result)
    " append result at cursor position
    call append(line('.'), l:result )
    " move to the end of inserted text
    exec "norm " .. l:result_count .. "j"
endfunction

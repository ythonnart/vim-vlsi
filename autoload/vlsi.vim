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
    noremap <silent> <Plug>VlsiYank              :call b:VlsiYank     ('')<CR>
    noremap <silent> <Plug>VlsiList              :echo join(vlsi#ListModules('<args>','',''),' ')<CR>
    noremap <silent> <Plug>VlsiDefineNew         :call vlsi#DefineNew ()<CR>
    noremap <silent> <Plug>VlsiPasteAsDefinition :call b:VlsiPasteAsDefinition   ('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInterface  :call b:VlsiPasteAsInterface('')<CR>
    noremap <silent> <Plug>VlsiPasteAsInstance   :call b:VlsiPasteAsInstance ('')<CR>

    " Default mappings
    if !hasmapto('<Plug>VlsiDefineNew') &&  maparg('<M-S-F6>','n') ==# ''
        nmap <M-S-F6>  <Plug>VlsiDefineNew
    endif
    if !hasmapto('<Plug>VlsiYank') &&  maparg('<M-F6>','n') ==# ''
        nmap <M-F6>  <Plug>VlsiYank
    endif
    if !hasmapto('<Plug>VlsiPasteAsDefinition') &&  maparg('<S-F6>','n') ==# ''
        nmap <S-F6>  <Plug>VlsiPasteAsDefinition
    endif
    if !hasmapto('<Plug>VlsiPasteAsInterface') &&  maparg('<C-F6>','n') ==# ''
        nmap <C-F6>  <Plug>VlsiPasteAsInterface
    endif
    if !hasmapto('<Plug>VlsiPasteAsInstance') &&  maparg('<F6>','n') ==# ''
        nmap <F6>  <Plug>VlsiPasteAsInstance
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

" Only do this when not done yet for this buffer
if exists("g:entity_yank_paste")
  finish
endif
let g:entity_yank_paste = 1

"Create plugin bindings
function! vlsi#Bindings()
  " Command-line mode
  command! -nargs=0 VlsiYank      :call b:VlsiYank()
  command! -nargs=? VlsiList      :echo join(vlsi#ListModules('<args>','',''),' ')
  command! -nargs=0 VlsiDefineNew :call vlsi#DefineNew()
  command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsEntity    :call b:VlsiPasteAsEntity('<args>')
  command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsComponent :call b:VlsiPasteAsComponent('<args>')
  command! -nargs=1 -complete=customlist,vlsi#ListModules VlsiPasteAsInstance  :call b:VlsiPasteAsInstance('<args>')

  " <Plug> Mappings
  noremap <silent> <Plug>VlsiYank                    :call b:VlsiYank     ()<CR>
  noremap <silent> <Plug>VlsiList                    :echo join(vlsi#ListModules('<args>','',''),' ')<CR>
  noremap <silent> <Plug>VlsiDefineNew               :call vlsi#DefineNew ()<CR>
  noremap <silent> <Plug>VlsiPasteAsEntity           :call b:VlsiPasteAsEntity   ('')<CR>
  noremap <silent> <Plug>VlsiPasteAsComponent        :call b:VlsiPasteAsComponent('')<CR>
  noremap <silent> <Plug>VlsiPasteAsInstance         :call b:VlsiPasteAsInstance ('')<CR>

  " Default mappings
  if !hasmapto('<Plug>VlsiDefineNew') &&  maparg('<M-S-F6>','n') ==# ''
    nmap <M-S-F6>  <Plug>VlsiDefineNew
  endif
  if !hasmapto('<Plug>VlsiYank') &&  maparg('<M-F6>','n') ==# ''
    nmap <M-F6>  <Plug>VlsiYank
  endif
  if !hasmapto('<Plug>VlsiPasteAsEntity') &&  maparg('<S-F6>','n') ==# ''
    nmap <S-F6>  <Plug>VlsiPasteAsEntity
  endif
  if !hasmapto('<Plug>VlsiPasteAsComponent') &&  maparg('<C-F6>','n') ==# ''
    nmap <C-F6>  <Plug>VlsiPasteAsComponent
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
  if !exists('g:modules')
    let g:modules = {}
  endif
  let modname = input('Module name: ')
  if has_key(g:modules,modname)
    if input('Module exists! Overwrite (y/n)? ') != 'y'
      echo
      echo 'Module capture abandoned!'
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
    while range !~ '^\(0\|\d\+:\d\+\)$'
        let range = input('Port range (0 for single wire / n:0 for bus): ', '0')
    endwhile
    let g:modules[modname].ports += [ { 'name' : name, 'dir' : dir, 'range' : range } ]
    let name = input('New port name (leave empty if no more): ')
  endwhile
  echo
  echo 'Module capture successful!'
endfunction

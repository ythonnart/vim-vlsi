"Parse module around cursor
function! vlsi#verilog#Yank() abort
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
  let linelist = matchlist(getline(modbegin),'\c^\s*\(module\)\s*\(\w\+\)')
  if empty(linelist)
    echo 'No match to module name on line ' . modbegin . '!'
    return
  endif
  let modname = linelist[2]
  if has_key(g:modules,modname)
    if input('Module ' . modname . ' exists! Overwrite (y/n)? ') != 'y'
      echo
      echo 'Module capture abandoned!'
      return
    endif
  endif
  let g:modules[modname] = { 'generics' : [], 'ports' : [] }
  let kind = -1
  for curline in getline(modbegin, modend)
    let linelist = matchlist(curline,'\c^\s*parameter\s*\(\w\+\)\s*=\s*\([^;]*\S\)\s*;')
    if !empty(linelist)
      let g:modules[modname].generics += [ { 'name' : linelist[1], 'type' : 'natural', 'value' : linelist[2] } ]
    endif
    let linelist = matchlist(curline,'\c^\(input\|output\)')
    if !empty(linelist)
      let kind = 1
      if linelist[1] =~ '\c^i'
        let dir = 'i'
      else
        let dir = 'o'
      endif
      let linelist = matchlist(curline,'\c^\(input\|output\)\s*\[\s*\(\d\+\)\s*:\s*\(\d\+\)\s*\]')
      if !empty(linelist)
        let range = linelist[2] . ":" . linelist[3]
        let curline = substitute(curline,'\c^\(input\|output\)\s*\[\s*\(\d\+\)\s*:\s*\(\d\+\)\s*\]','','')
      else
        let range = 0
        let curline = substitute(curline,'\c^\(input\|output\)','','')
      endif
    endif
    if kind == 1
      let portlist = split(curline, '\W\+')
      for port in portlist
        let g:modules[modname].ports += [ { 'name' : port, 'dir' : dir, 'range' : range } ]
      endfor
    endif
    if match(curline,';') != -1
      let kind = -1
    endif
  endfor
  echo 'Module capture successful!'
endfunction

"Insert entity defined a:name as 'module'
function! vlsi#verilog#PasteAsModule(name)
  if !exists('g:modules')
    let g:modules = {}
  endif
  let name = a:name
  if name == ''
      let name = input('Module? ', '', 'customlist,vlsi#ListModules')
  endif
  let lnum = line('.')
  if has_key(g:modules, name)
    call append(lnum, 'module ' . name . ' (') 
    let lnum = lnum + 1
    if !empty(g:modules[name].ports)
      let arglist = []
      let keynum = 0
      for item in g:modules[name].ports
        let arglist += [ '  ' . item.name  . ' ,' ]
        let keynum = keynum + 1
      endfor
      let arglist[-1] = arglist[-1][:-3]
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, [');',''])
      let lnum = lnum + 2
    endif
    if !empty(g:modules[name].generics)
      for item in g:modules[name].generics
        call append(lnum, 'parameter ' . item.name . ' = ' . item.value . ' ;')
        let lnum = lnum + 1
      endfor
      call append(lnum, [''])
      let lnum = lnum + 1
    endif
    if !empty(g:modules[name].ports)
      let arglist = []
      let keynum = 0
      for item in g:modules[name].ports
        if item.dir == 'i'
          let dir = 'input '
        else
          let dir = 'output'
        endif
        let rangelist = matchlist(item.range, '\(\d\+\):\(\d\+\)')
        if !empty(rangelist)
          let type = '[' . rangelist[1] . ':' . rangelist[2] . ']'
        else
          let type = '     '
        endif
        let arglist += [ dir . ' ' . type . ' ' . item.name  . ' ;' ]
        let keynum = keynum + 1
      endfor
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, ['',''])
      let lnum = lnum + 2
    endif
    call append(lnum, 'endmodule')
  else
    echo 'Unknown entity ' . name . '!'
  endif
endfunction

"Insert entity defined by a:name as instance
function! vlsi#verilog#PasteAsInstance(name)
  if !exists('g:modules')
    let g:modules = {}
  endif
  let name = a:name
  if name == ''
      let name = input('Entity? ', '', 'customlist,vlsi#ListModules')
  endif
  let lnum = line('.')
  if has_key(g:modules, name)
    if !empty(g:modules[name].generics)
      call append(lnum, name . ' I_' . name . ' #(') 
    else
      call append(lnum, name . ' I_' . name . ' (') 
    endif
    let lnum = lnum + 1
    if !empty(g:modules[name].generics)
      let arglist = []
      let keynum = 0
      for item in g:modules[name].generics
        let arglist += [ '  .' . item.name . '(' . item.value . ') ,' ]
        let keynum = keynum + 1
      endfor
      let arglist[-1] = arglist[-1][:-3]
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, ') (')
      let lnum = lnum + 1
    endif
    if !empty(g:modules[name].ports)
      let arglist = []
      let keynum = 0
      for item in g:modules[name].ports
        let arglist += [ '  .' . item.name . '(' . item.name . ') ,' ]
        let keynum = keynum + 1
      endfor
      let arglist[-1] = arglist[-1][:-3]
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, ');')
      let lnum = lnum + 1
    endif
  else
    echo 'Unknown entity ' . name . '!'
  endif
endfunction

"Parse Vlsi around cursor
function! vlsi#vhdl#Yank() abort
  if !exists('g:modules')
    let g:modules = {}
  endif
  mark z
  let entbegin = search('\c^\s*\(entity\|component\)','bcn')
  let entend   = search('\c^\s*end','cn')
  if entbegin == 0 || entend == 0
    echo 'Could not find entity or component around cursor!'
    return
  endif
  let linelist = matchlist(getline(entbegin),'\c^\s*\(entity\|component\)\s*\(\w\+\)')
  if empty(linelist)
    echo 'No match to entity or component on line ' . entbegin . '!'
    return
  endif
  let modname = linelist[2]
  if has_key(g:modules,modname)
    if input('Entity ' . modname . ' exists! Overwrite (y/n)? ') != 'y'
      echo
      echo 'Entity capture abandoned!'
      return
    endif
  endif
  let g:modules[modname] = { 'generics' : [], 'ports' : [] }
  let kind = -1
  for curline in getline(entbegin, entend)
    if match(curline,'\cgeneric') != -1
      let kind = 0
    endif
    if match(curline,'\cport') != -1
      let kind = 1
    endif
    let linelist = matchlist(curline,'\c^\s*\(\w\+\)\s*:\s*\(.\{-}\S\)\s*\(\($\|;\|--\)\|:=\s*\(.\{-}\S\)\s*\($\|;\|--\)\)')
    if kind == 0 && !empty(linelist)
      let linelist[2] = tolower(linelist[2])
      let g:modules[modname].generics += [ { 'name' : linelist[1], 'type' : linelist[2], 'value' : linelist[5] } ]
    endif
    let linelist = matchlist(curline,'\c^\s*\(\w\+\)\s*:\s*\(\w\+\)\s*\(.\{-}\S\)\s*\($\|;\|--\)')
    if kind == 1 && !empty(linelist)
      if linelist[2] =~ '\c^i'
        let dir = 'i'
      elseif linelist[2] =~ '\c^o'
        let dir = 'o'
      else
        echo 'Entity capture abandoned!'
        return
      endif
      let rangelist = matchlist(linelist[3],'\c^vector\s*(\s*\(\d\+\)\s*\w\+\s*\(\d\+\)')
      if !empty(rangelist)
        let range = rangelist[1] . ":" . rangelist[2]
      else
        let range = 0
      endif
      let g:modules[modname].ports += [ { 'name' : linelist[1], 'dir' : dir, 'range' : range } ]
    endif
  endfor
  echo 'Entity capture successful!'
endfunction

"Insert entity defined a:name as 'ENTITY'
function! vlsi#vhdl#PasteAsEntity(name)
  if !exists('g:modules')
    let g:modules = {}
  endif
  let name = a:name
  if name == ''
      let name = input('Entity? ', '', 'customlist,vlsi#ListModules')
  endif
  let lnum = line('.')
  if has_key(g:modules, name)
    call append(lnum, 'ENTITY ' . name . ' IS') 
    let lnum = lnum + 1
    if !empty(g:modules[name].generics)
      call append(lnum, '  GENERIC (')
      let lnum = lnum + 1
      let arglist = []
      let keynum = 0
      for item in g:modules[name].generics
        let arglist += [ '    ' . item.name . ' : ' . item.type . ' := ' . item.value . ' ;' ]
        let keynum = keynum + 1
      endfor
      let arglist[-1] = arglist[-1][:-3]
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, '  );')
      let lnum = lnum + 1
    endif
    if !empty(g:modules[name].ports)
      call append(lnum, '  PORT (')
      let lnum = lnum + 1
      let arglist = []
      let keynum = 0
      for item in g:modules[name].ports
        if item.dir == 'i'
          let dir = 'IN '
        else
          let dir = 'OUT'
        endif
        let rangelist = matchlist(item.range, '\(\d\+\):\(\d\+\)')
        if !empty(rangelist)
          let type = 'STD_LOGIC_VECTOR(' . rangelist[1] . ' DOWNTO ' . rangelist[0] . ')'
        else
          let type = 'STD_LOGIC'
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
    call append(lnum, 'END ' . name . ';')
  else
    echo 'Unknown entity ' . name . '!'
  endif
endfunction

"Insert entity defined by a:name as 'COMPONENT'
function! vlsi#vhdl#PasteAsComponent(name)
  if !exists('g:modules')
    let g:modules = {}
  endif
  let name = a:name
  if name == ''
      let name = input('Entity? ', '', 'customlist,vlsi#ListModules')
  endif
  let lnum = line('.')
  if has_key(g:modules, name)
    call append(lnum, '  COMPONENT ' . name) 
    let lnum = lnum + 1
    if !empty(g:modules[name].generics)
      call append(lnum, '    GENERIC (')
      let lnum = lnum + 1
      let arglist = []
      let keynum = 0
      for item in g:modules[name].generics
        let arglist += [ '      ' . item.name . ' : ' . item.type . ' := ' . item.value . ' ;' ]
        let keynum = keynum + 1
      endfor
      let arglist[-1] = arglist[-1][:-3]
      call append(lnum, arglist)
      let lnum = lnum + keynum
      call append(lnum, '  );')
      let lnum = lnum + 1
    endif
    if !empty(g:modules[name].ports)
      call append(lnum, '    PORT (')
      let lnum = lnum + 1
      let arglist = []
      let keynum = 0
      for item in g:modules[name].ports
        if item.dir == 'i'
          let dir = 'IN '
        else
          let dir = 'OUT'
        endif
        let rangelist = matchlist(item.range, '\(\d\+\):\(\d\+\)')
        if !empty(rangelist)
          let type = 'STD_LOGIC_VECTOR(' . rangelist[1] . ' DOWNTO ' . rangelist[0] . ')'
        else
          let type = 'STD_LOGIC'
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
    call append(lnum, '  END COMPONENT;')
  else
    echo 'Unknown entity ' . name . '!'
  endif
endfunction

"Insert entity defined by a:name as instance
function! vlsi#vhdl#PasteAsInstance(name)
  if !exists('g:modules')
    let g:modules = {}
  endif
  let name = a:name
  if name == ''
      let name = input('Entity? ', '', 'customlist,vlsi#ListModules')
  endif
  let lnum = line('.')
  if has_key(g:modules, name)
    call append(lnum, '  I_' . name . ' : ' . name) 
    let lnum = lnum + 1
    if !empty(g:modules[name].generics)
      call append(lnum, '    GENERIC MAP (')
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
      call append(lnum, '    PORT MAP (')
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
    echo 'Unknown entity ' . name . '!'
  endif
endfunction

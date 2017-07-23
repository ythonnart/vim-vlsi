" Load specific functions for VHDL entity yank/paste
let b:VlsiYank              = function('vlsi#vhdl#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#vhdl#PasteAsEntity')
let b:VlsiPasteAsInterface  = function('vlsi#vhdl#PasteAsComponent')
let b:VlsiPasteAsInstance   = function('vlsi#vhdl#PasteAsInstance')
 
" Create default bindings
call vlsi#Bindings()

" Tagbar ctags configuration
let g:tagbar_type_vhdl = {
    \ 'ctagsbin' : expand('<sfile>:p:h:h:h') . '/bin/ctags/vhdl.pl',
    \ 'kinds'     : [
        \ 'e:entities:1:0',
        \ 'g:generics:1:0',
        \ 'p:ports:1:0',
        \ 'a:architectures:1:0',
        \ 't:types:1:0',
        \ 's:signals:1:0',
        \ 'c:components:1:0',
        \ 'i:instances:1:0',
        \ 'r:processes:1:0',
        \ 'K:packages:1:0',
        \ 'k:package bodies:1:0',
        \ 'f:functions:1:0',
        \ 'P:procedures:1:0',
        \ 'v:variables:1:0',
    \ ],
    \ 'sro'        : '::',
    \ 'scope2kind' : {
        \ 'entity'       : 'e',
        \ 'generic'      : 'g',
        \ 'port'         : 'p',
        \ 'architecture' : 'a',
        \ 'type'         : 't',
        \ 'signal'       : 's',
        \ 'component'    : 'c',
        \ 'instance'     : 'i',
        \ 'process'      : 'r',
        \ 'package'      : 'k',
        \ 'package body' : 'K',
        \ 'function'     : 'f',
        \ 'procedure'    : 'P',
        \ 'variable'     : 'v',
    \ },
    \ 'kind2scope' : {
        \ 'e' : 'entity',
        \ 'g' : 'generic',
        \ 'p' : 'port',
        \ 'a' : 'architecture',
        \ 't' : 'type',
        \ 's' : 'signal',
        \ 'c' : 'component',
        \ 'i' : 'instance',
        \ 'r' : 'process',
        \ 'k' : 'package',
        \ 'K' : 'package body',
        \ 'f' : 'function',
        \ 'P' : 'procedure',
        \ 'v' : 'variable',
    \ },
\ }


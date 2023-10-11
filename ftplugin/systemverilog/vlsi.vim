" Load specific functions for VHDL entity yank/paste
let b:VlsiYank              = function('vlsi#verilog#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#verilog#PasteAsModule')
let b:VlsiPasteAsInstance   = function('vlsi#verilog#PasteAsInstance')
 
" Create default bindings
call vlsi#Bindings()

" Tagbar ctags configuration
let g:tagbar_type_systemverilog = {
    \ 'ctagsbin' : expand('<sfile>:p:h:h:h') . '/bin/ctags/systemverilog.pl',
    \ 'kinds'     : [
        \ 'd:macros:1:0',
        \ 'h:headers:1:0',
        \ 'm:modules:1:0',
        \ 'g:parameters:1:0',
        \ 'p:ports:1:0',
        \ 's:signals:1:0',
        \ 'i:instances:1:0',
        \ 'r:processes:1:0',
    \ ],
    \ 'sro'        : '::',
    \ 'scope2kind' : {
        \ 'module'       : 'm',
        \ 'parameter'    : 'g',
        \ 'port'         : 'p',
        \ 'signal'       : 's',
        \ 'instance'     : 'i',
        \ 'process'      : 'r',
    \ },
    \ 'kind2scope' : {
        \ 'm' : 'module',
        \ 'g' : 'parameter',
        \ 'p' : 'port',
        \ 's' : 'signal',
        \ 'i' : 'instance',
        \ 'r' : 'process',
    \ },
\ }


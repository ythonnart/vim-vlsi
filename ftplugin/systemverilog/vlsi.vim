" Load specific functions for VHDL entity yank/paste
let b:VlsiYank              = function('vlsi#v_sv#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#v_sv#PasteAsModule')
let b:VlsiPasteAsInstance   = function('vlsi#v_sv#PasteAsInstance')
let b:vlsi_config           = #{comment : "//", type:'logic',
            \ kind2dir : #{i:'input', o:'output', io:'inout'},
            \ formatRange:function("vlsi#v_sv#formatRange")}
 
" Create default bindings
call vlsi#Bindings()

" Tagbar ctags configuration
let g:tagbar_type_systemverilog = {
    \ 'ctagsbin' : expand('<sfile>:p:h:h:h') . '/bin/ctags/systemverilog.pl',
    \ 'kinds'     : [
        \ 'd:macros:1:0',
        \ 'h:headers:1:0',
        \ 'm:modules:1:0',
        \ 'I:interfaces:1:0',
        \ 'g:parameters:1:0',
        \ 'p:ports:1:0',
        \ 'P:modports:1:0',
        \ 's:signals:1:0',
        \ 'i:instances:1:0',
        \ 'r:processes:1:0',
    \ ],
    \ 'sro'        : '::',
    \ 'scope2kind' : {
        \ 'module'       : 'm',
        \ 'interface'       : 'I',
        \ 'parameter'    : 'g',
        \ 'port'         : 'p',
        \ 'modport'         : 'P',
        \ 'signal'       : 's',
        \ 'instance'     : 'i',
        \ 'process'      : 'r',
    \ },
    \ 'kind2scope' : {
        \ 'm' : 'module',
        \ 'I' : 'interface',
        \ 'g' : 'parameter',
        \ 'p' : 'port',
        \ 'P' : 'modport',
        \ 's' : 'signal',
        \ 'i' : 'instance',
        \ 'r' : 'process',
    \ },
\ }


" Load specific functions for verilog entity yank/paste
let b:VlsiYank              = function('vlsi#v_sv#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.definition])
let b:VlsiPasteAsInstance   = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.instance])
let b:VlsiPasteSignals      = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.signals])
let b:vlsi_config           = #{
            \ language            : 'verilog',
            \ comment             : "//",
            \ default_scalar_type : 'wire',
            \ default_vector_type : 'wire',
            \ kind2dir            : #{i: 'input', o: 'output', io: 'inout'},
            \ formatRange         : function("vlsi#v_sv#formatRange")}

" Create default bindings
call vlsi#Bindings()

" Tagbar ctags configuration
let g:tagbar_type_verilog = {
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


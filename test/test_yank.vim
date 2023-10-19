" Test suite for VlsiYank in various languages
" Install https://github.com/h1mesuke/vim-unittest
" Note: as of Oct 2023, the master branch fails, tag v0.5.1 works just fine
" Run :UnitTest <this file>
"
" where are we?
let s:here= expand('<sfile>:p:h')

"--------------------------------------------------------------------------------
" Helper functions for module comparison 
"--------------------------------------------------------------------------------
" {{{ 1
"
" module comparator
" compare module content in actual with awaited value in wanted
function! s:assert_module_equals(wanted,actual) dict
    " check for structure
"    " should be a dict
     call self.assert(type(a:actual) == type({}), "module should be a dictionnary")

    " should have basic keys
    for key in ["lang", "generics", "ports"]
        call self.assert(has_key(a:actual,key), "missing basic key " .. key)
    endfor

    "should have the same keys
    for key in keys(a:wanted)
        call self.assert(has_key(a:actual,key), "missing key " .. key)
    endfor
    for key in keys(a:actual)
        call self.assert(has_key(a:wanted,key), "extraneous key " .. key)
    endfor

    " compare lang
    call self.assert_equal(a:wanted.lang, a:actual.lang, "'lang' mismatch")

    " compare generics sizes
    if self.assert_equal(len(a:wanted.generics), len(a:actual.generics), "generics size mismatch")
        " size mismatch
        call self.puts('wanted: ' . string(a:wanted.generics) . ' actual:' . string(a:wanted.generics))
    else
        " size matches
        for i in range(len(a:actual.generics))
            call self.assert_equal(a:wanted.generics[i], a:actual.generics[i],"mismatch for generic " .. i)
        endfor
    endif

    " compare ports sizes
    if self.assert_equal(len(a:wanted.ports), len(a:actual.ports), "ports size mismatch")
        " size mismatch
    else
        " size matches
        for i in range(len(a:actual.ports))
            call self.assert_equal(a:wanted.ports[i], a:actual.ports[i],"mismatch for ports " .. i)
        endfor
    endif



endfunction

" Goto data(label)
" VlsiYank
" Compare yanked module to provided module_data
function! s:goto_yank_compare(label, module_data) dict
    call self.data.goto(a:label)
    VlsiYank
    call self.assert(has_key(g:modules,a:label), "capture failed for "..a:label)
    call self.assert_module_equals(a:module_data, g:modules[a:label])
endfunction

" }}}

"--------------------------------------------------------------------------------
" Testcase
"--------------------------------------------------------------------------------
let s:tc = unittest#testcase#new("Test VlsiYank functions", {'data' : s:here .. '/ressources/test_file.sv'})

"--------------------------------------------------------------------------------
" Setup and Teardown
"--------------------------------------------------------------------------------
" {{{ 1

""" Once SETUP
function! s:tc.SETUP()
    " define markers for data accessors
    call self.puts("Setting marker format for SystemVerilog")
    let self.data.marker_formats = ['// begin %s', '// end %s']
    " Add our comparison functions
    let s:tc.assert_module_equals = function ('s:assert_module_equals')
    let s:tc.assert_yank_equals = function ('s:goto_yank_compare')
endfunction

""" every test setup
function! s:tc.setup()
    " Always start with an empty g:modules and g:interfaces
    let g:modules = {}
    let g:interfaces = {}
endfunction

" }}}

""" test functions


function! s:tc.test_yank_minimal()
    let  l:label = 'minimal'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[]}
    call self.assert_yank_equals(l:label, s:wanted)
endfunction

function! s:tc.test_yank_generic1()
    let  l:label = 'generic1'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_equals(l:label, s:wanted)
endfunction

function! s:tc.test_yank_generic1a()
    let  l:label = 'generic1a'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_equals(l:label, s:wanted)
endfunction

function! s:tc.test_yank_generic1b()
    let  l:label = 'generic1b'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_equals(l:label, s:wanted)
endfunction

function! s:tc.test_yank_generics_multi()
    let  l:label = 'generics_multi'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ #{name:'truc', type:'natural', value:'4'},
        \ #{name:'machin', type:'natural', value:'{1, 0, 3}'},
        \ #{name:'chose', type:'natural', value:'10'},
        \ #{name:'thing', type:'natural', value:'{1,0}'},
        \ ], ports:[]}
    call self.assert_yank_equals(l:label, s:wanted)
endfunction



" vim: :fdm=marker

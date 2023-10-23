" Test suite for VlsiYank for SystemVerilog
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
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
    call self.assert_equal(len(a:wanted.generics), len(a:actual.generics), "generics size mismatch")
    if len(a:wanted.generics) == len(a:actual.generics)
        " size matches
        for i in range(len(a:actual.generics))
            call self.assert_equal(a:wanted.generics[i], a:actual.generics[i],"mismatch for generics[" .. i.."]")
        endfor
    endif

    " compare ports sizes
    call self.assert_equal(len(a:wanted.ports), len(a:actual.ports), "ports size mismatch")
    if len(a:wanted.ports) == len(a:actual.ports)
        " size matches
        for i in range(len(a:actual.ports))
            call self.assert_equal(a:wanted.ports[i], a:actual.ports[i],"mismatch for ports[" .. i .."]")
        endfor
    endif



endfunction

" Goto data(label)
" VlsiYank
" Compare yanked module to provided module_data
function! s:goto_yank_compare_module(label, module_data) dict
    call self.data.goto(a:label)
    VlsiYank
    call self.assert(has_key(g:modules,a:label), "capture failed for "..a:label)
    call self.assert_module_equals(a:module_data, g:modules[a:label])
endfunction

" Compare interfaces
function! s:assert_interface_equals(wanted,actual) dict

    call self.assert(type(a:actual) ==type({}), "interface should be a dictionnary")
    for key in ['lang','generics','ports']
        call self.assert(has_key(a:actual,key), "interface missing key: "..key)
    endfor

    " strip down actual and wanted to modules and compare them
    let actual_as_a_module = #{
                \    lang: a:actual.lang,
                \    ports: a:actual.ports,
                \    generics: a:actual.generics
                \}

    let wanted_as_a_module = #{
                \    lang: a:wanted.lang,
                \    ports: a:wanted.ports,
                \    generics: a:wanted.generics
                \}

    " compare the 'module' part
    call self.assert_module_equals(wanted_as_a_module, actual_as_a_module)

    " check modports existence
    call self.assert(has_key(a:actual,'modports'))
    call self.assert(type(a:actual.modports) == type({}), "interface.modports should be a dict")

    " check modports length
    call self.assert_equal(len(a:wanted.modports),len(a:actual.modports), "modports size differ")

    "should have the same keys
    for key in keys(a:wanted.modports)
        call self.assert(has_key(a:actual.modports,key), "missing key " .. key)
    endfor
    for key in keys(a:actual.modports)
        call self.assert(has_key(a:wanted.modports,key), "extraneous key " .. key)
    endfor

    " iterate through modports
    if len(a:wanted.modports) == len(a:actual.modports)
        for key in keys(a:wanted.modports)
            let wanted_sigs = a:wanted.modports[key]
            let actual_sigs = a:actual.modports[key]
            call self.assert_equal(len(wanted_sigs), len(actual_sigs), "modport '"..key.."' size differ")
            if len(wanted_sigs) == len(actual_sigs)
                for i in range(len(wanted_sigs))
                    call self.assert_equal(
                                \ wanted_sigs[i], actual_sigs[i], 
                                \ "modport '"..key.."' signal [" ..i.. "] differ")
                endfor
            endif
        endfor
    endif

endfunction
" Goto data(label)
" VlsiYank
" Compare yanked interface to provided interface_data
function! s:goto_yank_compare_interface(label, interface_data) dict
    call self.data.goto(a:label)
    VlsiYank
    call self.assert(has_key(g:interfaces,a:label), "capture failed for "..a:label)
    call self.assert_interface_equals(a:interface_data, g:interfaces[a:label])
endfunction

" }}}

"--------------------------------------------------------------------------------
" Testcase
"--------------------------------------------------------------------------------
let s:tc = unittest#testcase#new("Test VlsiYank functions for SystemVerilog", {'data' : s:here .. '/ressources/test_file.sv'})

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
    let s:tc.assert_yank_module_equals = function ('s:goto_yank_compare_module')

    let s:tc.assert_interface_equals = function ('s:assert_interface_equals')
    let s:tc.assert_yank_interface_equals = function ('s:goto_yank_compare_interface')
endfunction

""" every test setup
function! s:tc.setup()
    " Always start with an empty g:modules and g:interfaces
    let g:modules = {}
    let g:interfaces = {}
endfunction

" }}}

""" test functions


"--------------------------------------------------------------------------------
" Generics Tests
"--------------------------------------------------------------------------------
" {{{ 1
function! s:tc.test_sv_yank_minimal()
    let  l:label = 'minimal'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generic1()
    let  l:label = 'generic1'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generic1a()
    let  l:label = 'generic1a'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generic1b()
    let  l:label = 'generic1b'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generic_with_special_value()
    let  l:label = 'generic_special_val'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'{1,0,3}'}], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generics_multi()
    let  l:label = 'generics_multi'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ #{name:'truc', type:'natural', value:'4'},
        \ #{name:'machin', type:'natural', value:'33'},
        \ #{name:'chose', type:'natural', value:'10'},
        \ #{name:'thing', type:'natural', value:'6'},
        \ ], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_generics_in_body()
    let  l:label = 'generics_in_body'
    let  s:wanted = #{ lang:'systemverilog', generics:[
                \ #{name:'param1', type:'natural', value:'1'},
                \ #{name:'param2', type:'natural', value:'2'},
                \ ], ports:[]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

" }}}
"--------------------------------------------------------------------------------
" Ports Tests
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tc.test_sv_yank_port1()
    let  l:label = 'port1'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_on_same_line_as_module()
    let  l:label = 'port1a'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port1b()
    let  l:label = 'port1b'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_ports_multi()
    let  l:label = 'ports_multi'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
                \ #{name:'port1', type:'logic', range:0, dir:'i'},
                \ #{name:'port2', type:'logic', range:0, dir:'o'},
                \ #{name:'port3', type:'logic', range:0, dir:'io'},
                \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_ports_multi_in_body()
    let  l:label = 'ports_multi_in_body'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
                \ #{name:'port1', type:'logic', range:0, dir:'i'},
                \ #{name:'port2', type:'logic', range:0, dir:'o'},
                \ #{name:'port3', type:'logic', range:0, dir:'io'},
                \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

" }}}
"--------------------------------------------------------------------------------
" Ports with special type
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tc.test_sv_yank_port_with_typedef()
    let  l:label = 'porttype1'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'mytype', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_with_typedef2()
    let  l:label = 'porttype1a'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'mytype', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_with_typedef3()
    let  l:label = 'porttype1b'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
        \ #{name:'port1', type:'mytype', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_with_typedefs_multi()
    let  l:label = 'porttypes_multi'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
                \ #{name:'port1', type:'mytype', range:0, dir:'i'},
                \ #{name:'port2', type:'mytype', range:0, dir:'o'},
                \ #{name:'port3', type:'mytype', range:0, dir:'io'},
                \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction
" }}}
"--------------------------------------------------------------------------------
" Ports and generics tests
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tc.test_sv_yank_ports_and_generics1()
    let  l:label = 'pg1'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ #{name:'param1', type:'natural', value:'4'}
        \ ], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_ports_and_generics_on_the_same_line()
    let  l:label = 'pg1a'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_ports_and_generics1b()
    let  l:label = 'pg1b'
    let  s:wanted = #{ lang:'systemverilog', generics:[#{name:'param1', type:'natural', value:'4'}], ports:[
        \ #{name:'port1', type:'logic', range:0, dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_ports_and_genericss_multi()
    let  l:label = 'pgs_multi'
    let  s:wanted = #{ lang:'systemverilog', generics:[
                \ #{name:'truc', type:'natural', value:'4'},
                \ #{name:'machin', type:'natural', value:'33'},
                \ #{name:'chose', type:'natural', value:'10'},
                \ #{name:'thing', type:'natural', value:'6'},
                \], ports:[
                \ #{name:'port1', type:'logic', range:0, dir:'i'},
                \ #{name:'port2', type:'logic', range:0, dir:'o'},
                \ #{name:'port3', type:'logic', range:0, dir:'io'},
                \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

" }}}
"--------------------------------------------------------------------------------
" Ports with range
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tc.test_sv_yank_port_with_range()
    let  l:label = 'pr1'
    let  s:wanted = #{ lang:'systemverilog', generics:[
            \ #{name:'BUS_WIDTH', type:'natural', value:'32'}
        \ ], ports:[
            \ #{name:'bus', type:'logic',  range:'BUS_WIDTH-1{{:}}0', dir:'i'},
            \ #{name:'bus2', type:'logic', range:'31{{:}}0', dir:'i'}
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

" }}}
"--------------------------------------------------------------------------------
" Ports with default port type
"--------------------------------------------------------------------------------
" {{{ 
"
function! s:tc.test_sv_yank_port_with_no_data_type()
    let  l:label = 'pdt'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ ], ports:[
            \ #{name:'port1', type:'',  range:0, dir:'i'},
            \ #{name:'port2', type:'',  range:'3{{:}}0', dir:'o'},
            \ #{name:'port3', type:'',  range:0, dir:'io'},
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_with_no_data_type_and_signal_list()
    let  l:label = 'pdt1'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ ], ports:[
            \ #{name:'port1', type:'',  range:0, dir:'i'},
            \ #{name:'port2', type:'',  range:0, dir:'i'},
            \ #{name:'port3', type:'',  range:0, dir:'o'},
            \ #{name:'port4', type:'',  range:0, dir:'io'},
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_port_no_data_type_all_ports_on_same_line()
    let  l:label = 'pdt2'
    let  s:wanted = #{ lang:'systemverilog', generics:[
        \ ], ports:[
            \ #{name:'port1', type:'',  range:0, dir:'i'},
            \ #{name:'port2', type:'',  range:0, dir:'i'},
            \ #{name:'port3', type:'',  range:0, dir:'o'},
            \ #{name:'port4', type:'',  range:0, dir:'io'},
        \ ]}
    call self.assert_yank_module_equals(l:label, s:wanted)
endfunction

" }}}
"--------------------------------------------------------------------------------
" Interface capture
"--------------------------------------------------------------------------------
" {{{ 
"
function! s:tc.test_sv_yank_interface()
    let  l:label = 'if1'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
            \ #{name:'sig1', type:'logic',  range:'31{{:}}0'  , dir:'io'},
            \ #{name:'sig2', type:'logic',  range:0           , dir:'io'},
        \ ], modports : {}}
    call self.assert_yank_interface_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_interface_with_generics()
    let  l:label = 'if1g'
    let  s:wanted = #{ lang:'systemverilog', generics:[
            \ #{name:'gen1',  type:'natural', value:'32'},
        \ ], ports:[
            \ #{name:'sig1', type:'logic',  range:'gen1{{:}}0', dir:'io'},
            \ #{name:'sig2', type:'logic',  range:0           , dir:'io'},
        \ ], modports : {}}
    call self.assert_yank_interface_equals(l:label, s:wanted)
endfunction

function! s:tc.test_sv_yank_interface_with_modports()
    let  l:label = 'ifmp1'
    let  s:wanted = #{ lang:'systemverilog', generics:[], ports:[
            \ #{name:'sig1', type:'logic',  range:'31{{:}}0'  , dir:'io'},
            \ #{name:'sig2', type:'logic',  range:0           , dir:'io'},
            \ ], modports : #{
            \     master: [
            \           #{name:'sig1', type:'logic',  range:'31{{:}}0', dir:'o'},
            \     ],
            \     slave: [
            \           #{name:'sig1', type:'logic',  range:'31{{:}}0', dir:'i'},
            \           #{name:'sig2', type:'logic',  range:0         , dir:'o'},
            \     ],
        \}}
    call self.assert_yank_interface_equals(l:label, s:wanted)
endfunction
" }}}

" vim: :fdm=marker

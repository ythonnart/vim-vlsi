" Test suite for VlsiYank for SystemVerilog
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
" Run :UnitTest <this file>
"
" where are we?
let s:here= expand('<sfile>:p:h')

"--------------------------------------------------------------------------------
" Testcase
"--------------------------------------------------------------------------------
let s:tc = unittest#testcase#new("Test core functions")

"--------------------------------------------------------------------------------
" Setup and Teardown
"--------------------------------------------------------------------------------
" {{{ 1

""" Once SETUP
function! s:tc.SETUP()
endfunction

""" every test setup
function! s:tc.setup()
    " Always start with an empty g:modules and g:interfaces
    let g:modules = {}
    let g:interfaces = {}
endfunction

" }}}

"--------------------------------------------------------------------------------
" Test functions
"--------------------------------------------------------------------------------
" {{{ 1

" As pattern substitution
function! s:tc.test_basicFormat_patterns()
    let item = #{key1:'value1', key2:'value2'}
    " simple string
    call self.assert_equal(
                \ "no { format",
                \ vlsi#basicFormat(item,"no { format"),
                \ "invalid pattern substitution")
    " substitution
    call self.assert_equal(
                \ "value2 is value1",
                \ vlsi#basicFormat(item,"{key2} is {key1}"),
                \ "invalid pattern substitution")

    " substitution can support case change
    try
        call self.assert_equal(
                    \ "value2 is NoCASEchange value1",
                    \ vlsi#basicFormat(item,"{KEY2} is NoCASEchange {kEy1}"),
                    \ "Problem with case")
    catch 'E716'
        call self.assert(0, "keys in pattern are case sensitive")
    endtry

    " unknown keys should be left as-is
    try
        call self.assert_equal(
                    \ "value2 is {unKNown}",
                    \ vlsi#basicFormat(item,"{KEY2} is {unKNown}"),
                    \ "Unknown keys should be left as is")
    catch 'E716'
        call self.assert(0, "Unknown keys should be left as is (but they throw!)")
    endtry

    let item = #{key1:1, key2:2, max_sizes:#{key2:10}}
    call self.assert_equal('1', vlsi#basicFormat(item,"{key1}"),"Bad int conversion or wrong padding")
    call self.assert_equal('2         ', vlsi#basicFormat(item,"{key2}"),"wrong length for padded field key2")
endfunction

"As a function call
"return a basic message
function! s:basic_message(item)
    return "basic_message:" .. string(a:item)
endfunction

" return the list of arguments
function! s:arguments(...)
    return a:000
endfunction

" test basicFormat with function calls
function! s:tc.test_basicFormat_calls()
    call self.assert_equal( "basic_message:{'key': 'wantedval'}",
                \ vlsi#basicFormat({'key':'wantedval'}, function('s:basic_message')),
                \ "Invalid return value from func calling")

    let args = vlsi#basicFormat({'key':'value'}, function('s:arguments'))

    call self.assert_equal(1,len(args),
                \ "Invalid call with incorrect number of arguments from basicFormat")

    if len(args) == 1
        call self.assert_is_Dict(args[0], "Invalid call with wrong argument type")
        if type(args[0]) == type({})
            call self.assert_has_key('key', args[0],
                        \'Invalid argument key [' .. string(args[0]) ..']')
            call self.assert_equal('value', get(args[0],'key','badval'),
                        \'Invalid argument value [' .. string(args[0]) ..']')
        endif
    endif
endfunction

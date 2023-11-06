" test for Vlsi
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
" Run :UnitTest <this file>
" NOTE: Some test are currently failing with low priority
" NOTE: They are skipped by default
" NOTE: Uncomment this line to run failing tests
" let g:include_failing_tests = 1
" NOTE: Some tests need 'vcom' and 'vlog' shell commands to be active
" NOTE: don't forget to load questa if you need to run them.

let s:here = expand('<sfile>:p:h')
execute 'source' s:here . '/test_yank_sv.vim'
execute 'source' s:here . '/test_yank_v.vim'
execute 'source' s:here . '/test_yank_vhd.vim'
execute 'source' s:here . '/test_core_functions.vim'
execute 'source' s:here . '/test_paste.vim'
execute 'source' s:here . '/test_ctags_v_sv.vim'
execute 'source' s:here . '/test_ctags_vhd.vim'


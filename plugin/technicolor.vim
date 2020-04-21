scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

inoremap <expr> <Plug>(technicolor) technicolor#main()

let &cpoptions = s:save_cpo

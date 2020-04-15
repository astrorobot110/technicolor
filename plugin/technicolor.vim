scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=1 Tech2cterm echo technicolor#gui2cterm(<q-args>)
command! -nargs=1 Tech2gui echo technicolor#cterm2gui(<q-args>)
command! -nargs=1 Technicolor call technicolor#main(<q-args>)

let &cpoptions = s:save_cpo

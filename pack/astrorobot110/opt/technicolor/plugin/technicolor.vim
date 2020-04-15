scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoption&vim

" コマンド登録: テスト中につきここに書いてあります {{{1
command! -nargs=1 Tech2cterm echo s:gui2cterm(<q-args>)
command! -nargs=1 Tech2gui echo s:cterm2gui(<q-args>)
command! -nargs=1 Technicolor call technicolor#main(<q-args>)
"}}}

let &cpoptions = s:save_cpo

" vim: set fdm=marker:

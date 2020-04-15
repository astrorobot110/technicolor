scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let technicolorPath = expand('<sfile>:p:h')
		\ ->matchstr('^.\+\ze[\/\\]plugin')

let &packpath .= ','..technicolorPath

let &cpoptions = s:save_cpo

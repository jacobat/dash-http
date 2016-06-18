#!/bin/sh

ruby generate.rb && tar --exclude='.DS_Store' -cvzf http.tgz http.docset

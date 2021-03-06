#!/usr/bin/env ruby
# -*- coding: utf-8; -*-
#
# update.rb
#
# Copyright (C) 2001-2009, TADA Tadashi <t@tdtds.jp>
# You can redistribute it and/or modify it under GPL2.
#
BEGIN { $stdout.binmode }
begin
	Encoding::default_external = 'UTF-8'
rescue NameError
	$KCODE = 'n'
end

begin
	if FileTest::symlink?( __FILE__ ) then
		org_path = File::dirname( File::readlink( __FILE__ ) ).untaint
	else
		org_path = File::dirname( __FILE__ ).untaint
	end
	$:.unshift( org_path ) unless $:.include?( org_path )
	require 'tdiary'

	@cgi = CGI::new
	conf = TDiary::Config::new(@cgi)
	tdiary = nil

	begin
		if @cgi.valid?( 'append' )
			tdiary = TDiary::TDiaryAppend::new( @cgi, 'show.rhtml', conf )
		elsif @cgi.valid?( 'edit' )
			tdiary = TDiary::TDiaryEdit::new( @cgi, 'update.rhtml', conf )
		elsif @cgi.valid?( 'replace' )
			tdiary = TDiary::TDiaryReplace::new( @cgi, 'show.rhtml', conf )
		elsif @cgi.valid?( 'appendpreview' ) or @cgi.valid?( 'replacepreview' ) 
			tdiary = TDiary::TDiaryPreview::new( @cgi, 'preview.rhtml', conf )
		elsif @cgi.valid?( 'plugin' )
			tdiary = TDiary::TDiaryFormPlugin::new( @cgi, 'update.rhtml', conf )
		elsif @cgi.valid?( 'comment' )
			tdiary = TDiary::TDiaryShowComment::new( @cgi, 'update.rhtml', conf )
		elsif @cgi.valid?( 'saveconf' )
			tdiary = TDiary::TDiarySaveConf::new( @cgi, 'conf.rhtml', conf )
		elsif @cgi.valid?( 'conf' )
			tdiary = TDiary::TDiaryConf::new( @cgi, 'conf.rhtml', conf )
		elsif @cgi.valid?( 'referer' )
			tdiary = TDiary::TDiaryConf::new( @cgi, 'referer.rhtml', conf )
		else
			tdiary = TDiary::TDiaryForm::new( @cgi, 'update.rhtml', conf )
		end
	rescue TDiary::TDiaryError
		tdiary = TDiary::TDiaryForm::new( @cgi, 'update.rhtml', conf )
	end

	begin
		head = body = ''
		if @cgi.mobile_agent? then
			body = conf.to_mobile( tdiary.eval_rhtml( 'i.' ) )
			head = @cgi.header(
				'status' => '200 OK',
				'type' => 'text/html',
				'charset' => conf.mobile_encoding,
				'Content-Length' => body.bytesize.to_s,
				'Vary' => 'User-Agent'
			)
		else
			body = tdiary.eval_rhtml
			head = @cgi.header(
				'status' => '200 OK',
				'type' => 'text/html',
				'charset' => conf.encoding,
				'Content-Length' => body.bytesize.to_s,
				'Vary' => 'User-Agent'
			)
		end
		print head
		print body if /HEAD/i !~ @cgi.request_method
	rescue TDiary::ForceRedirect
		head = {
			#'Location' => $!.path
			'type' => 'text/html',
		}
		head['cookie'] = tdiary.cookies if tdiary.cookies.size > 0
		print @cgi.header( head )
		print %Q[
			<html>
			<head>
			<meta http-equiv="refresh" content="1;url=#{$!.path}">
			<title>moving...</title>
			</head>
			<body>Wait or <a href="#{$!.path}">Click here!</a></body>
			</html>]
	end

rescue Exception
	if @cgi then
		print @cgi.header( 'status' => '500 Internal Server Error', 'type' => 'text/html' )
	else
		print "Status: 500 Internal Server Error\n"
		print "Content-Type: text/html\n\n"
	end
	puts "<h1>500 Internal Server Error</h1>"
	puts "<pre>"
	puts CGI::escapeHTML( "#{$!} (#{$!.class})" )
	puts ""
	puts CGI::escapeHTML( $@.join( "\n" ) )
	puts "</pre>"
	puts "<div>#{' ' * 500}</div>"
end


# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:

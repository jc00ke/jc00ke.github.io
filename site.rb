require 'rubygems'
require 'sinatra'

get '/' do
	body = '<!DOCTYPE html><html>'
	body << '<head><title>jc00ke llc</title>'
	body << '<meta name=\"google-site-verification\" content=\"2OjD3SXVlbH70lZl5vUDKKDEtqUcwQ2sSfaW91C-0O4\" >'
	body << '</head><body>'
	body << 'It gets better, just give it some time<br />But for now you can get a hold of me via: work at jc00ke dot com<br /><script src="http://www.ubuntu.com/files/countdown/display2.js"></script>'
	body << '</body></html>'
	body
end

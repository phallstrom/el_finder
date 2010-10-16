== Description:

Ruby library to provide server side functionality for elFinder.  elFinder is an
open-source file manager for web, written in JavaScript using jQuery UI.

  http://elrte.org/redmine/projects/elfinder

== Features/Problems:

* Does not yet support archive/extraction.
* Does not yet support thumbnail generation.

== Requirements:

The gem, by default, relies upon the 'imagesize' ruby gem and ImageMagick's 'mogrify' command.
These requirements can be changed by implementing custom methods for determining image size
and resizing of an image.

== Install:

* Install elFinder (http://elrte.org/redmine/projects/elfinder/wiki/Install_EN)
* Install ImageMagick (http://www.imagemagick.org/)
* Do whatever is necessary for your Ruby framework to tie it together.

=== Rails 3

1. Add +gem 'el_finder'+ to +Gemfile+
1. +bundle install+
1. Switch to using jQuery instead of Prototype
1. Add the following action to a controller of your choosing.

    skip_before_filter :verify_authenticity_token, :only => ['elfinder']
    def elfinder
      h, r = ElFinder::Connector.new(
        :root => File.join(Rails.public_path, 'system', 'elfinder'),
        :url => '/system/elfinder'
      ).run(params)
      headers.merge!(h)
      if r.empty?
        render :nothing => true, :layout => false
      else
        render :text => r.to_json , :layout => false
      end

    end





== License:

(The MIT License)

Copyright (c) 2010 Philip Hallstrom

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

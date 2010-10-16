== el_finder

* http://elrte.org/redmine/projects/elfinder

== Description:

Ruby library to provide server side functionality for elFinder.  elFinder is an
open-source file manager for web, written in JavaScript using jQuery UI.

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

* Add "gem 'el_finder'" to Gemfile
* % bundle install
* Switch to using jQuery instead of Prototype
* Add the following action to a controller of your choosing.

    skip_before_filter :verify_authenticity_token, :only => ['elfinder']
    def elfinder
      h, r = ElFinder::Connector.new(
        :root => File.join(Rails.public_path, 'system', 'elfinder'),
        :url => '/system/elfinder'
      ).run(params)
      headers.merge!(h)
      render (r.empty? ? {:nothing => true} : {:text => r.to_json}), :layout => false
    end

* Add the appropriate route to config/routes.rb such as:

    match 'elfinder' => 'home#elfinder'

* Add the following to your layout. The paths may be different depending 
on where you installed the various js/css files.

    <%= stylesheet_link_tag 'jquery-ui/base/jquery.ui.all', 'elfinder' %>
    <%= javascript_include_tag :defaults, 'elfinder/elfinder.min' %>

* Add the following to the view that will display elFinder:

    <%= javascript_tag do %>
      $().ready(function() { 
        $('#elfinder').elfinder({ 
          url: '/elfinder',
          lang: 'en'
        })
      })
    <% end %>
    <div id='elfinder'></div>

* That's it.  I think.  If not, check out the example rails application at http://github.com/phallstrom/el_finder-rails-example.

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

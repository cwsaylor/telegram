Telegram
========

Telegram is a minimalist blogging engine built on Sinatra and MongoDB.
Templates are created in Haml and writing is done in markdown.
It is meant to easily be deployed to Heroku or any hosting system that 
supports Rack. If you don't like Haml and Markdown, fork it.

Features
--------
* Posts
* Markdown
* Drafts
* Atom Feed
* Single author
* Pretty permalinks
* Authentication through Basic HTTP Auth
* Update Haml templates and CSS through the admin

Planned Features
----------------
* Real time statistics
* Admin encrypted using Heroku's free Piggyback SSL support
* iPhone/iPad interface

Caveats
-------
* Templates are currently being rendered directly from the database so don't allow access to your admin by someone you don't trust.
* You must close the browser after logging out. This is a limitation of HTTP Auth.

Requirements
------------

* Sinatra 1.1
* Mongoid 2.0.0.beta.19
* Haml
* Builder
* RDiscount

Demo
----
You can view a demo here:
[http://telegram.heroku.com](http://telegram.heroku.com)


Installation
------------
These instructions are for deploying to Heroku.

    git clone git://github.com/cwsaylor/telegram.git
    cd telegram
    gem install heroku
    heroku create
    heroku addons:add mongohq:free
    git push heroku master
    heroku open
    
Browse to /settings and login with username 'admin' and password 'change_me' to setup your new CMS. 

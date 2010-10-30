Telegram
========

Telegram is a minimalist blogging engine built on Sinatra and MongoDB,
it is meant to easily be deployed to Heroku or any hosting system that 
supports Rack.

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

Installation
------------

These instructions are for deploying to Heroku.
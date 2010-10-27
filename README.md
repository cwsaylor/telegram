Telegram
========

Telegram is a minimalist blogging engine built on Sinatra and MongoDB,
it is meant to easily be deployed to Heroku or any hosting system that 
supports Rack.

Features
--------

* Posts
* Drafts
* Atom Feed
* Single author
* Pretty permalinks
* Authentication through Basic HTTP Auth
* Admin encrypted using Heroku's free Piggyback SSL support
* Update templates and CSS through the admin
* iPhone/iPad interface

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
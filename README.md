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
* Assets
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
* Mongoid 2.0.0.beta.20
* Haml
* Builder
* RDiscount
* Carrierwave
* An S3 account to use the asset uploader

Demo
----
You can view a demo here:
[http://www.telegramcms.com](http://www.telegramcms.com)


Installation
------------
These instructions are for deploying to Heroku. Replace xxxx below with appropriate S3 parameters.

    git clone git://github.com/cwsaylor/telegram.git
    cd telegram
    gem install heroku
    heroku create
    heroku addons:add mongohq:free
    heroku config:add S3_KEY=xxxx S3_SECRET=xxxx S3_BUCKET=xxxx
    git push heroku master
    heroku open
    
Browse to /settings and login with username 'admin' and password 'change_me' to setup your new CMS.

Deploying to Multiple Heroku Apps from One Repository
-----------------------------------------------------
This is a pretty cool feature that I find very useful if you're managing multiple sites. You only
need one repository using this trick, because all site Telegram site customizations are stored in
the database.

Assuming you've already performed the above steps and you have a heroku remote in your .git/config,
let's setup another web site from this same repository.

    heroku create my_new_app
  
Make a note of the git repository that is displayed after this command. We are about to use it.
  
You will now need to create this second remote manually. The easiest way to do that is to open 
.git/config in your favorite text editor and duplicate the heroku remote entry and edit it like so...

    [remote "my_new_app"]
      url = git@heroku.com:my_new_app.git
      fetch = +refs/heads/*:refs/remotes/heroku/*

Note that you need to change the remote name and the url, which we noted above.

To perform any heroku commands on this app, we just need to append '--app my_new_app' to the command

    heroku info --app my_new_app
    heroku addons:add custom_domains --app my_new_app
    heroku config:add S3_KEY=xxxx S3_SECRET=xxxx S3_BUCKET=xxxx --app my_new_app




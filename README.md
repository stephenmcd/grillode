Overview
========

Grillode is A web-based chat application written in [CoffeeScript] 
for [Node.js]. It is [BSD licensed].

Due to web sockets and Node's evented model, the Grillode server 
should be able to handle thousands of real-time users simultaneously. 

A demo can be found at [http://chat.jupo.org]().

Installation
============

Grillode is available in source form on both [Github] and [Bitbucket].
Grillode also makes use of the following libraries which can be installed 
using [Node Package Manager] (NPM).

  * [express] >= 1.0.3
  * [socket.io] >= 0.6.8
  * [coffee-script] >= 1.0.0
  * [coffeekup] >= 0.2.2
  * [htmlparser] >= 1.7.3
  * [node-markdown] >= 0.1.0

With Node.js and NPM installed, you can install all of the above 
dependencies by running the following command from within the Grillode 
directory:

    $ npm install .

You can then run the Grillode server by running the following command 
from within the Grillode directory, with an optional port number:

    $ coffee server.coffee 8000
    
To allow the server to continue to run detached from the terminal 
session, you can run the same command using `nohup]:

    $ nohup coffee server.coffee 8000 &
    
When running the server detached from the terminal session, you can 
shut the server down in one command with::

    $ kill -9 `ps aux | grep server.coffee | grep -v grep | awk '{print $2}'`

Configuration
=============

Grillode can operate in several modes to support different use cases:

  * A general chat server with a fixed set of rooms
  * A hybrid of the above, where users can add their own rooms
  * A customer support service, where customers join a chat queue and 
    support staff answers each customer chat one by one
  * A hybrid of the above, where users are randomly matched to each other
  * All of the above at once!

Several settings found in the file `settings.coffee` can be used to 
control the modes described above, these are:

  * `ROOMS` - The initial list of fixed room names
  * `ADDABLE_ROOMS` - When set to `on`, rooms can be added, allowing for 
    the applicable modes described above
  * `ADDABLE_ROOMS_VISIBLE` - When set to `on`, dynamically added rooms 
    are visible in the room list
  * `DEFAULT_URL` - URL redirected to from the index page, which can be 
    one of the URLs listed below
  
The following URLs are provided which cater for the various modes described:

  * `/rooms` - List all rooms
  * `/rooms/add` - Add a room
  * `/wait` - Wait for someone
  * `/match` - Join someone waiting
  * `/random` - Random match up
  * `/about` - Renders this README file

[CoffeeScript]: http://coffeescript.org/
[Node.js]: http://nodejs.org/
[BSD licensed]: http://www.linfo.org/bsdlicense.html
[Github]: http://github.com/stephenmcd/grillode/
[Bitbucket]: http://bitbucket.org/stephenmcd/grillode/
[Node Package Manager]: http://npmjs.org/
[express]: http://expressjs.com/
[socket.io]: http://socket.io/
[coffee-script]: http://coffeescript.org/
[coffeekup]: http://coffeekup.org/
[htmlparser]: http://github.com/tautologistics/node-htmlparser
[node-markdown]: http://github.com/andris9/node-markdown

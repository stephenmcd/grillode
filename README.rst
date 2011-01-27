Overview
========

Grillode is A web-based chat application written in `CoffeeScript`_ 
for `Node.js`_. It is `BSD licensed`_.

Due to web sockets and Node's evented model, the Grillode server 
should be able to handle thousands of real-time users simultaneously. 

A demo can be found at http://chat.jupo.org.

Installation
============

Grillode is available in source form on both `Github`_ and `Bitbucket`_.
Grillode also makes use of the following libraries which can be installed 
using `Node Package Manager`_ (NPM).

  * `express`_ >= 1.0.3
  * `socket.io`_ >= 0.6.8
  * `coffee-script`_ >= 1.0.0
  * `coffeekup`_ >= 0.2.2
  * `htmlparser`_ >= 1.7.3

With Node.js and NPM installed, you can install all of the above 
dependencies by running the following command from within the Grillode 
directory::

    $ npm install .

You can then run the Grillode server by running the following command 
from within the Grillode directory, with an optional port number::

    $ coffee server.coffee [PORT]
    
To allow the server to continue to run after the terminal session has 
ended, you can run the same command using ``nohup``::

    $ nohup coffee server.coffee [PORT] &

Configuration
=============

Grillode can operate in several modes to support different use cases:

  * A general chat server with a fixed set of rooms
  * A hybrid of the above, where users can add their own rooms
  * A customer support service, where customers join a chat queue and support staff answers each customer chat one by one
  * A hybrid of the above, where users are randomly matched to each other
  * All of the above at once!

Several settings found in the file ``settings.coffee`` can be used to 
control the modes described above, these are:

  * ``ROOMS`` - The initial list of fixed room names
  * ``ADDABLE_ROOMS`` - When set to ``on``, rooms can be added, allowing for the applicable modes described above
  * ``ADDABLE_ROOMS_VISIBLE`` - When set to ``on``, dynamically added rooms are visible in the room list
  * ``DEFAULT_URL`` - URL redirected to from the index page, which can be one of the URLs listed below
  
The following URLs are provided which cater for the various modes described:

  * ``/rooms`` - List all rooms
  * ``/rooms/add`` - Add a room
  * ``/wait`` - Wait for someone
  * ``/match`` - Join someone waiting
  * ``/random`` - Random match up

.. _`CoffeeScript`: http://coffeescript.org/
.. _`Node.js`: http://nodejs.org/
.. _`BSD licensed`: http://www.linfo.org/bsdlicense.html
.. _`Github`: http://github.com/stephenmcd/grillode/
.. _`Bitbucket`: http://bitbucket.org/stephenmcd/grillode/
.. _`Node Package Manager`: http://npmjs.org/
.. _`express`: http://expressjs.com/
.. _`socket.io`: http://socket.io/
.. _`coffee-script`: http://coffeescript.org/
.. _`coffeekup`: http://coffeekup.org/
.. _`htmlparser`: http://github.com/tautologistics/node-htmlparser


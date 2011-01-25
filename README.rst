Overview
========

Grillode is a web-based chat application written in `CoffeeScript`_ 
and built for `Node.js`_. It is `BSD licensed`_.

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

Fixed rooms can be configured by changing the list of default rooms in 
the settings file ``settings.coffee`` via the ``ROOM`` setting. In the 
same file, the ``ADDABLE_ROOMS`` setting can be set to ``on`` or ``off`` 
to enable the other modes, which are each then accessed via the following 
URLs:

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


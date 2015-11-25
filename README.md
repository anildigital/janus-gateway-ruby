janus-gateway-ruby [![Build Status](https://travis-ci.org/cargomedia/janus-gateway-ruby.svg)](https://travis-ci.org/cargomedia/janus-gateway-ruby)
==================
Minimalistic [janus-gateway](https://github.com/meetecho/janus-gateway) client for ruby

Installation
------------
```
gem install janus_gateway
```

API coverage
------------
Current implementation support only a few of API features. For more details please follow official documentation of [REST API](https://janus.conf.meetecho.com/docs/rest.html)

|Resource       |Get All |Get One |Create |Update |Delete |
|:--------------|:------:|:------:|:-----:|:-----:|:-----:|
|Session        |        |        | +     |       | +     |
|Plugin         |        |        | +     |       |       |

Library usage
-------------

Source code itself is well-documented so when writing code it should auto-complete and hint in all supported usages.

### Client
In order to make any request you need to instantiate client with correct transport layer (see transport section).

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
```

This client is used by all other classes connecting to api no matter if it's Resource or helper class like Agent.

### Transports
Client allows to use multiple, supported by Janus transportation layers. Currently the `WebSocket` transport is implemented and is the default.

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
```

### Resources
Each resource has built-in event emitter to handle basic behaviours like `create` and `destroy`. Additionally the creation of resources can be chained.
There are two types of resources: Janus-API resource and Plugin-API (please see Plugin section).

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
resource = JanusGateway::Resource::Resource.new(client)
```

#### New

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
session = JanusGateway::Resource::Session.new(client)
plugin = JanusGateway::Resource::Plugin.new(client, session, 'plugin-name')
```

#### Create

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
session = JanusGateway::Resource::Session.new(client)
session.create
```

#### Events

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
session = JanusGateway::Resource::Session.new(client)

session.on :create do |session|
  # do something
end

session.on :destroy do |session|
  # do something
end

session.create
```

#### Chaining

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)
session = JanusGateway::Resource::Session.new(client)

session.create.then do |session|
  # do something with success
end.rescue do |error|
  # do something with error
end
```

### Plugins
Janus support for native and custom [plugins](https://janus.conf.meetecho.com/docs/group__plugins.html).

#### Rtpbrodcast plugin
This is custom plugin for `RTP` streaming. Please find more details in official [repository](https://github.com/cargomedia/janus-gateway-rtpbroadcast).
Plugin must be installed and active in `Janus` server.

Coverage of plugin resources.

|Resource       |Get All |Get One |Create |Update |Delete |
|:--------------|:------:|:------:|:-----:|:-----:|:-----:|
|Mountpoint     |        |        | +     |       |       |

Plugin resource supports `events` and `chaining` in the same way like `Janus` resource.

##### Mountpoint create
Plugins allows to create `RTP` mountpoint.

```ruby
ws = JanusGateway::Transport::WebSocket.new('ws://localhost:8188/janus')
client = JanusGateway::Client.new(ws)

client.on :open do
  JanusGateway::Resource::Session.new(client).create.then do |session|
    JanusGateway::Resource::Plugin.new(client, session, JanusGateway::Plugin::Rtpbroadcast.plugin_name).create.then do |plugin|
      JanusGateway::Plugin::Rtpbroadcast::Resource::Mountpoint.new(client, plugin, 'test-mountpoint').create.then do |mountpoint|
        # do something with mountpoint
      end
    end
  end
end

client.connect
```

require 'spec_helper'

describe JanusGateway::Resource::Session do
  let(:transport) { JanusGateway::Transport::WebSocket.new('') }
  let(:client) { JanusGateway::Client.new(transport) }
  let(:session) { JanusGateway::Resource::Session.new(client) }

  it 'should throw exception' do

    janus_response = {
      :create => '{"janus":"error", "transaction":"123", "error":{"code":468, "reason": "The ID provided to create a new session is already in use"}}'
    }

    transport.stub(:_create_client).and_return(WebSocketClientMock.new(janus_response))
    transport.stub(:transaction_id_new).and_return('123')

    client.on :open do
      session.create.rescue do |error|
        error.code.should eq(468)
        client.disconnect
      end
    end

    client.connect
  end

  it 'should destroy session' do

    janus_response = {
      :create => '{"janus":"success", "transaction":"ABCDEFGHIJK", "data":{"id":"12345"}}',
      :destroy => '{"janus":"success", "session_id":12345, "transaction":"ABCDEFGHIJK"}'
    }

    transport.stub(:_create_client).and_return(WebSocketClientMock.new(janus_response))
    transport.stub(:transaction_id_new).and_return('ABCDEFGHIJK')

    client.on :open do
      session.create.then do
        session.destroy.then do
          client.disconnect
        end
      end
    end

    client.connect
  end

  it 'should fail to destroy session' do

    janus_response = {
      :create => '{"janus":"success", "transaction":"ABCDEFGHIJK", "data":{"id":"12345"}}',
      :destroy => '{"janus":"error", "session_id":999, "transaction":"ABCDEFGHIJK", "error":{"code":458, "error": "Session not found"}}'
    }

    transport.stub(:_create_client).and_return(WebSocketClientMock.new(janus_response))
    transport.stub(:transaction_id_new).and_return('ABCDEFGHIJK')

    client.on :open do
      session.create.then do
        session.id = 999
        session.destroy.rescue do
          client.disconnect
        end
      end
    end

    client.connect
  end

  it 'should session timeout' do

    janus_response = {
      :create => '{"janus":"success", "transaction":"ABCDEFGHIJK", "data":{"id":12345}}'
    }

    transport.stub(:_create_client).and_return(WebSocketClientMock.new(janus_response))
    transport.stub(:transaction_id_new).and_return('ABCDEFGHIJK')

    client.on :open do
      session.on :destroy do
        client.disconnect
      end
      session.create.then do
        client.transport.client.receive_message('{"janus":"timeout", "session_id":12345}')
      end
    end

    client.connect
  end

end


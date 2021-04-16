require_relative 'helper'

module KeepassXC
  class Client
    include Helper

    attr_reader :client_id, :client_identifier, :client_name

    def initialize(client_identifier: nil, client_name: nil)
      @client_id = generate_nonce
      user_id = `id -u`.chomp.to_i
      @sock = UNIXSocket.new("/run/user/#{user_id}/org.keepassxc.KeePassXC.BrowserServer")
      @private_key = RbNaCl::PrivateKey.generate
      @client_identifier = client_identifier || to_b64(@private_key.public_key)
      @client_name = client_name
    end

    def generate_nonce
      to_b64 RbNaCl::Random.random_bytes
    end

    def change_public_keys
      resp = send_msg(
        action: 'change-public-keys',
        publicKey: to_b64(@private_key.public_key),
        nonce: generate_nonce,
        clientID: @client_id
      )
      @session = RbNaCl::SimpleBox.from_keypair(resp['publicKey'].unpack1('m*'), @private_key)

      resp
    end

    def associate
      resp = send_encrypted_msg(
        'action' => 'associate',
        'key' => to_b64(@private_key.public_key),
        'idKey' => @client_identifier
      )
      @client_name = resp['id']

      resp
    end

    def test_associate
      send_encrypted_msg(
        'action' => 'test-associate',
        'key' => @client_identifier,
        'id' => @client_name
      )
    end

    def get_logins(url)
      send_encrypted_msg(
        'action' => 'get-logins',
        'url' => url,
        'keys' => [
          {
            'id' => @client_name,
            'key' => @client_identifier
          }
        ]
      )['entries']
    end

    def send_encrypted_msg(msg)
      nonce, enc = encrypt(msg)

      send_msg(
        action: msg['action'],
        message: to_b64(enc),
        nonce: to_b64(nonce),
        clientID: client_id
      )
    end

    def encrypt(msg)
      crypt = @session.box(JSON.dump(msg.transform_keys(&:to_s)))
      nonce = crypt.slice!(0, RbNaCl::SecretBox.nonce_bytes)

      [nonce, crypt]
    end

    def decrypt(msg, nonce:)
      @session.decrypt(from_b64(nonce) + from_b64(msg))
    end

    def send_msg(msg)
      @sock.send(JSON.dump(msg.transform_keys(&:to_s)), 0)
      json = @sock.recvfrom(4096).first
      resp = JSON.parse(json)

      raise Error, resp['error'] if resp.key?('error')
      resp = JSON.parse(decrypt(resp['message'], nonce: resp['nonce'])) if resp.key?('message')
      binding.irb if resp['success'] != 'true'

      resp
    end
  end
end

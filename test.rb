require 'socket'
require 'oj'
require 'rbnacl'

class KeepassXC
  class Error < StandardError; end

  def to_b64(string)
    [string].pack('m*').chomp
  end

  def from_b64(string)
    string.unpack1('m*')
  end

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
    p 'change-public-keys'
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
    p 'Associate'
    resp = send_encrypted_msg(
      'action' => 'associate',
      'key' => to_b64(@private_key.public_key),
      'idKey' => @client_identifier
    )
    @client_name = resp['id']

    resp
  end

  def test_associate
    p 'test-associate'
    send_encrypted_msg(
      'action' => 'test-associate',
      'key' => @client_identifier,
      'id' => @client_name
    )
  end

  def get_logins(url)
    puts "get-logins (#{url})"
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
    crypt = @session.box(Oj.dump(msg, mode: :compat))
    nonce = crypt.slice!(0, RbNaCl::SecretBox.nonce_bytes)

    [nonce, crypt]
  end

  def decrypt(msg, nonce:)
    @session.decrypt(from_b64(nonce) + from_b64(msg))
  end

  def send_msg(msg)
    msg = Oj.dump(msg, mode: :compat)
    @sock.send msg, 0
    json = @sock.recvfrom(4096).first
    resp = Oj.load(json)

    if resp.key?('error')
      warn resp['error']
      binding.irb
    end
    resp = Oj.load(decrypt(resp['message'], nonce: resp['nonce'])) if resp.key?('message')

    if resp['success'] != 'true'
      warn resp['error']
      binding.irb
    end

    resp
  end
end

kpx = KeepassXC.new client_identifier: 'kiVMXPidJ1ZCZ3WaaLHJKrHLzPw2uEFcB1amS7aMNmM=', client_name: 'HelloWorld'
kpx.change_public_keys
# kpx.associate
kpx.test_associate
p kpx.get_logins 'https://github.com'

require 'socket'
require 'oj'
require 'rbnacl'

class KeepassXC
  class Error < StandardError; end
    
  def to_b64(string)
    [string].pack('m*').chomp
  end

  def from_b64(string)
    string.unpack('m*').first
  end
  
  attr_reader :client_id
  attr_reader :client_identifier
  attr_reader :client_name
  def initialize(client_identifier: nil, client_name: nil)
    @client_id = generate_nonce
    @sock = UNIXSocket.new("/run/user/1000/org.keepassxc.KeePassXC.BrowserServer")
    @private_key = RbNaCl::PrivateKey.generate
    @client_identifier = client_identifier || to_b64(@private_key.public_key)
    @client_name = client_name
  end
  
  def generate_nonce
    to_b64 RbNaCl::Random.random_bytes
  end
  
  def next_nonce(nonce)
    next_nonce = nonce.dup
    # next_nonce[0] += 
  end
  
  # TODO,
  def verify_nonce!(orig, increment)
    return true
    return if next_nonce([orig].pack('m*')) == increment
    
    raise Error, <<~MSG
      Verification failed - nonce missmatch
      Orig: #{orig}
      Next: #{increment}
      Calc: #{next_nonce(orig)}
    MSG
  end

  # => ["{\"action\":\"change-public-keys\",\"nonce\":\"K0o6k8aryTaojvjC0aI0rQ==\",\"publicKey\":\"SBq9Il9sc8uIskldtU5obsPPTax6WSkTl6Mt1v5E4Rs=\",\"success\":\"true\",\"version\":\"2.3.1\"}", ["AF_UNIX", "/run/user/1000/N2h3kr/s"]]
  def change_public_keys
    p 'Create new session'
    msg = { action: 'change-public-keys', publicKey: to_b64(@private_key.public_key), nonce: generate_nonce, clientID: @client_id }
    resp = send_msg(msg)
    
#     resp['publicKey'] = '6CQyGaK8Lyid2a0WdoEuS9rBlTEckRfDMrz+X14vjzo='
    @session = RbNaCl::SimpleBox.from_keypair(resp['publicKey'].unpack('m*').first, @private_key)
    p 'Success'
    verify_nonce!(msg[:nonce], resp['nonce'])
  end
  
  def associate
    p 'Associate'
    msg = {
      "action": "associate",
      "key": to_b64(@private_key.public_key),
      "idKey": @client_identifier,
    }
    nonce, enc = encrypt(msg)
    print 'Nonce: `', to_b64(nonce)
    puts '`'
    print 'Msg: `', to_b64(enc).inspect
    puts '`'
    print 'Key: `', to_b64(@private_key.public_key)
    puts '`'
    
    resp = send_msg(
      action: "associate",
      message: to_b64(enc),
      nonce: to_b64(nonce),
      clientID: client_id
    )
    p resp
    p resp = Oj.load(decrypt(resp['message'], nonce: resp['nonce']))
    p 'Success'
    binding.irb
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
    resp = @sock.recvfrom(4096).first
    Oj.load(resp)
  end
end

kpx = KeepassXC.new
kpx.change_public_keys
kpx.associate

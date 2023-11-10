require 'socket'
require 'json'

# TODO, replace this with openssl
require 'rbnacl'

module KeepassXC
  class Error < StandardError; end

  autoload :Client, 'keepassxc/client'
  autoload :Helper, 'keepassxc/helper'
  autoload :KeyStore, 'keepassxc/key_store'
  autoload :VERSION, 'keepassxc/version'

  def self.open_session(client_name)
    raise ArgumentError if client_name.nil?

    client_name = client_name.to_s
    cfg = KeyStore.find_or_create
    kpx = Client.new client_name: client_name
    kpx.change_public_keys
    if cfg.profiles[client_name]
      kpx.client_identifier = cfg.profiles[client_name]
    else
      kpx.associate
      cfg.profiles[client_name] = kpx.client_identifier
      cfg.save
    end
    kpx.test_associate
    return yield(kpx) if block_given?

    kpx
  end
end

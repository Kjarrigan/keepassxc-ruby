require 'socket'
require 'json'

# TODO, replace this with openssl
require 'rbnacl'

module KeepassXC
  class Error < StandardError; end

  autoload :Client, 'keepassxc/client'
  autoload :Helper, 'keepassxc/helper'
  autoload :VERSION, 'keepassxc/version'
end

require 'fileutils'
require 'json'

module KeepassXC
  class KeyStore
    attr_reader :path

    DEFAULT_PATH = File.join(Dir.home, '.config', 'keepassxc-rb')
    def initialize(path: DEFAULT_PATH)
      @path = path
    end

    def create
      unless exist?
        FileUtils.mkdir_p File.dirname(path)
        File.write(path, JSON.dump(profiles: {}))
      end
      File.chmod(0600, path) unless secure?
    end

    def self.find_or_create(path: DEFAULT_PATH)
      storage = new(path: path)
      storage.create
      storage
    end

    def raw
      @raw ||= JSON.load_file(path)
    rescue Errno::ENOENT
      @raw = {}
    end

    def profiles
      raw['profiles']
    end

    def save
      create
      File.write(path, JSON.dump(raw))
    end

    def secure?
      File.stat(path).mode == 0600
    end

    def exist?
      File.exist?(path)
    end
  end
end

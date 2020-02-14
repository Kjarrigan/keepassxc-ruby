# KeypassXC Ruby binding

You want to fetch login data as the browsers do. Then this is for you.
Similar to my https://github.com/Kjarrigan/keepasshttp-ruby repo.

## Work in progress

A coworker just asked me wether I have use the keepassxc-cli but it requires
to enter a password every time which is annoying and then I remembered my
keepasshttp-ruby binding and it turns out this is no longer the descired way
for KeepassXC. So why not make the new version work. Yay!

## Links

Some things have changed but the rough idea is the same. So I can probably copy
over quite a bit of context.

* [My HTTP Code](https://github.com/Kjarrigan/keepasshttp-ruby/blob/master/lib/keepasshttp.rb)
* [The official protocal docs](https://github.com/keepassxreboot/keepassxc-browser/blob/develop/keepassxc-protocol.md)
* [A python binding for the unix socket](https://github.com/varjolintu/keepassxc-proxy/blob/master/python_version/keepassxc-proxy)

## Basic communication snippet

A "cleaned" up list of my irb tinkering.

```
require 'socket'
require 'oj'
require 'openssl'

sock = UNIXSocket.new("/run/user/1000/kpxc_server")
session = OpenSSL::Cipher.new('AES-256-CBC')
session.encrypt

nonce = [session.random_iv].pack('m*').chomp

msg = { action: 'change-public-keys', publicKey: 'foo', nonce: nonce, clientID: nonce }
msg = Oj.dump(msg, mode: compat)
sock.send msg, 0
resp = sock.recvfrom 4096
# => ["{\"action\":\"change-public-keys\",\"nonce\":\"K0o6k8aryTaojvjC0aI0rQ==\",\"publicKey\":\"SBq9Il9sc8uIskldtU5obsPPTax6WSkTl6Mt1v5E4Rs=\",\"success\":\"true\",\"version\":\"2.3.1\"}", ["AF_UNIX", "/run/user/1000/N2h3kr/s"]]
```

Seems easy enough and like a good weekend project.

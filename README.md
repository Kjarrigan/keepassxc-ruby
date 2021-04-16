# KeypassXC Ruby binding

You want to fetch login data as the browsers do. Then this is for you.
Similar to my https://github.com/Kjarrigan/keepasshttp-ruby repo.

## Work in progress

A coworker just asked me wether I have use the keepassxc-cli but it requires
to enter a password every time which is annoying and then I remembered my
keepasshttp-ruby binding and it turns out this is no longer the desired way
for KeepassXC. So why not make the new version work. Yay!

## Links

Some things have changed but the rough idea is the same. So I can probably copy
over quite a bit of context.

* [My HTTP Code](https://github.com/Kjarrigan/keepasshttp-ruby/blob/master/lib/keepasshttp.rb)
* [The official protocal docs](https://github.com/keepassxreboot/keepassxc-browser/blob/develop/keepassxc-protocol.md)

## Basic communication snippet

It is already working now! Altough some comfort is still missing, you can already register your client and
fetch logins. Yay!

```ruby
load 'test.rb'

kpx = KeepassXC.new client_identifier: KEY_FROM_ASSOCIATE_OR_DB, client_name: ID_FROM_ASSOCIATE_OR_DB
kpx.change_public_keys
# kpx.associate
kpx.test_associate
p kpx.get_logins 'https://github.com'
```

You can check what clients are already registered in your DB via the GUI like this:
* Database
* Database-Settings
* Browser-Integration

Technically you could even re-use the Key/ID from your browser by just copying them from there.

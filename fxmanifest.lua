fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author "SLaYN"
description "Anti Map Collision Standalone Script for FiveM"
version "1.0.0b"

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_script 'client.lua'

dependencies {
    'ox_lib'
}
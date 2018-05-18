weak_ciphers = [ccs: "current_control_set".camelize, control: "control".camelize, \
   sp: "security_providers".camelize, protocols: "protocols".camelize, sl: "schannel".upcase, \
   ci: "ciphers".camelize, rc4128: "rc4 128/128".upcase, rc440: "rc4 40/128".upcase, \
   rc456: "rc4 56/128".upcase, reg_prefix: "HKEY_LOCAL_MACHINE\\SYSTEM" \
  ]


disable_weak_ciphers = [
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ci>s\\%<rc4128>s" % weak_ciphers,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ci>s\\%<rc440>s" % weak_ciphers,
  "%<reg_prefix>s\\%<ccs>s\\%<control>s\\%<sp>s\\%<sl>s\\%<protocols>s\\%<ci>s\\%<rc456>s" % weak_ciphers
]


disable_weak_ciphers.each do | cipher_registry_key |
  registry_key cipher_registry_key do
    values [ {name: "Enabled" % cipher_registry_key, :type => :dword, :data => '0'} ]
    recursive true
    action :create_if_missing
  end
end

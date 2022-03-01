local expect =   require "cc.expect".expect
local chacha20 = require "ccryptolib.chacha20"
local poly1305 = require "ccryptolib.poly1305"

local bxor = bit32.bxor
local bor = bit32.bor

local function encrypt(key, nonce, message, aad, rounds)
    expect(1, key, "string")
    assert(#key == 32, "key length must be 32")
    expect(2, nonce, "string")
    assert(#nonce == 12, "nonce length must be 12")
    expect(3, message, "string")
    expect(4, aad, "string")
    expect(5, rounds, "number", "nil")
    rounds = rounds or 20

    -- Generate auth key and encrypt.
    local msgLong = ("\0"):rep(64) .. message
    local ctxLong = chacha20.crypt(key, nonce, msgLong, rounds, 0)
    local authKey = ctxLong:sub(1, 32)
    local ciphertext = ctxLong:sub(65)

    -- Authenticate.
    local pad1 = ("\0"):rep(-#aad % 16)
    local pad2 = ("\0"):rep(-#ciphertext % 16)
    local aadLen = ("<I8"):pack(#aad)
    local ctxLen = ("<I8"):pack(#ciphertext)
    local combined = aad .. pad1 .. ciphertext .. pad2 .. aadLen .. ctxLen
    local tag = poly1305.mac(authKey, combined)

    return ciphertext, tag
end

local function decrypt(key, nonce, tag, ciphertext, aad, rounds)
    expect(1, key, "string")
    assert(#key == 32, "key length must be 32")
    expect(2, nonce, "string")
    assert(#nonce == 12, "nonce length must be 12")
    expect(3, ciphertext, "string")
    expect(4, aad, "string")
    expect(5, rounds, "number", "nil")
    rounds = rounds or 20

    -- Generate auth key and decrypt.
    local ctxLong = ("\0"):rep(64) .. ciphertext
    local msgLong = chacha20.crypt(key, nonce, ctxLong, rounds, 0)
    local authKey = msgLong:sub(1, 32)
    local message = msgLong:sub(65)

    -- Check tag.
    local pad1 = ("\0"):rep(-#aad % 16)
    local pad2 = ("\0"):rep(-#ciphertext % 16)
    local aadLen = ("<I8"):pack(#aad)
    local ctxLen = ("<I8"):pack(#ciphertext)
    local combined = aad .. pad1 .. ciphertext .. pad2 .. aadLen .. ctxLen
    local t1, t2, t3, t4 = ("<I4I4I4I4"):unpack(tag)
    local u1, u2, u3, u4 = ("<I4I4I4I4"):unpack(poly1305.mac(authKey, combined))
    local eq = bor(bxor(t1, u1), bxor(t2, u2), bxor(t3, u3), bxor(t4, u4))
    if eq == 0 then return message end
end

return {
    encrypt = encrypt,
    decrypt = decrypt,
}

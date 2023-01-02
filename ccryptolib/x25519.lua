--- The X25519 key exchange scheme.
--
-- @module x25519
--

local expect = require "cc.expect".expect
local lassert = require "ccryptolib.internal.util".lassert
local util   = require "ccryptolib.internal.util"
local c25    = require "ccryptolib.internal.curve25519"

local mod = {}

--- Computes the public key from a secret key.
--
-- @tparam string sk A random 32-byte secret key.
-- @treturn string The matching public key.
--
function mod.publicKey(sk)
    expect(1, sk, "string")
    assert(#sk == 32, "secret key length must be 32")
    return c25.encode(c25.scale(c25.mulG(util.bits(sk))))
end

--- Performs the key exchange.
--
-- @tparam string sk A secret key.
-- @tparam string pk A public key, usually derived from a second secret key.
-- @treturn string The 32-byte shared secret between both keys.
--
function mod.exchange(sk, pk)
    expect(1, sk, "string")
    lassert(#sk == 32, "secret key length must be 32", 2)
    expect(2, pk, "string")
    lassert(#pk == 32, "public key length must be 32", 2)
    return c25.encode(c25.scale(c25.ladder8(c25.decode(pk), util.bits8(sk))))
end

--- Same as @{exchange}, but decodes the public key as an Edwards25519 point.
function mod.exchangeEd(sk, pk)
    expect(1, sk, "string")
    lassert(#sk == 32, "secret key length must be 32", 2)
    expect(2, pk, "string")
    lassert(#pk == 32, "public key length must be 32", 2)
    return c25.encode(c25.scale(c25.ladder8(c25.decodeEd(pk), util.bits8(sk))))
end

return mod
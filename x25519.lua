local expect = require "cc.expect".expect
local fp     = require "ccryptolib.internal.fp"
local random = require "ccryptolib.random"

local unpack = unpack or table.unpack

local function double(x1, z1)
    local a = fp.add(x1, z1)
    local aa = fp.square(a)
    local b = fp.sub(x1, z1)
    local bb = fp.square(b)
    local c = fp.sub(aa, bb)
    local x3 = fp.mul(aa, bb)
    local z3 = fp.mul(c, fp.add(bb, fp.kmul(c, 121666)))
    return x3, z3
end

local function step(dx, x1, z1, x2, z2)
    local a = fp.add(x1, z1)
    local aa = fp.square(a)
    local b = fp.sub(x1, z1)
    local bb = fp.square(b)
    local e = fp.sub(aa, bb)
    local c = fp.add(x2, z2)
    local d = fp.sub(x2, z2)
    local da = fp.mul(d, a)
    local cb = fp.mul(c, b)
    local x4 = fp.square(fp.add(da, cb))
    local z4 = fp.mul(dx, fp.square(fp.sub(da, cb)))
    local x3 = fp.mul(aa, bb)
    local z3 = fp.mul(e, fp.add(bb, fp.kmul(e, 121666)))
    return x3, z3, x4, z4
end

local function bits(str)
    -- Decode.
    local bytes = {str:byte(1, 32)}
    local out = {}
    for i = 1, 32 do
        local byte = bytes[i]
        for j = -7, 0 do
            local bit = byte % 2
            out[8 * i + j] = bit
            byte = (byte - bit) / 2
        end
    end

    -- Clamp.
    out[256] = 0
    out[255] = 1

    -- We remove the 3 lowest bits since the ladder already multiplies by 8.
    return {unpack(out, 4)}
end

local function ladder8(dx, bits)
    local x1 = fp.num(1)
    local z1 = fp.num(0)

    local z2 = fp.decode(random.random(32))
    local x2 = fp.mul(dx, z2)

    -- Standard ladder.
    for i = #bits, 1, -1 do
        if bits[i] == 0 then
            x1, z1, x2, z2 = step(dx, x1, z1, x2, z2)
        else
            x2, z2, x1, z1 = step(dx, x2, z2, x1, z1)
        end
    end

    -- Multiply by 8 (double 3 times).
    for _ = 1, 3 do
        x1, z1 = double(x1, z1)
    end

    return fp.mul(x1, fp.invert(z1))
end

local mod = {}

function mod.publicKey(sk)
    expect(1, sk, "string")
    assert(#sk == 32, "secret key length must be 32")

    return fp.encode(ladder8(fp.num(9), bits(sk)))
end

function mod.exchange(sk, pk)
    expect(1, sk, "string")
    assert(#sk == 32, "secret key length must be 32")
    expect(2, pk, "string")
    assert(#pk == 32, "public key length must be 32")

    return fp.encode(ladder8(fp.decode(pk), bits(sk)))
end

return mod

//sitar_token_utils.h
//
//Utility functions for packing and unpacking data into/from a token payload.
//pack() serializes a set of arguments into the token payload sequentially.
//unpack() deserializes them back in the same order.
//The total size of the arguments must exactly match the token payload size,
//enforced at compile time via static_assert.
//Requires C++11 or later.

#ifndef SITAR_TOKEN_UTILS_H
#define SITAR_TOKEN_UTILS_H

#include <cstring>
#include <stdint.h>
#include "sitar_token.h"

namespace sitar{

//--- Compile-time size summation (C++11 recursive helper) ---

//base case: no types, total size is 0
template<typename... Args>
struct total_sizeof;

template<>
struct total_sizeof<>
{
    static const unsigned int value = 0;
};

template<typename T, typename... Rest>
struct total_sizeof<T, Rest...>
{
    static const unsigned int value = sizeof(T) + total_sizeof<Rest...>::value;
};


//--- Internal pack helpers ---

//base case: nothing left to pack, offset unused
inline void _pack_impl(uint8_t* /*buf*/, unsigned int /*offset*/){}

template<typename T, typename... Rest>
inline void _pack_impl(uint8_t* buf, unsigned int offset, const T& first, const Rest&... rest)
{
    std::memcpy(buf + offset, &first, sizeof(T));
    _pack_impl(buf, offset + sizeof(T), rest...);
}


//--- Internal unpack helpers ---

inline void _unpack_impl(const uint8_t* /*buf*/, unsigned int /*offset*/){}

template<typename T, typename... Rest>
inline void _unpack_impl(const uint8_t* buf, unsigned int offset, T& first, Rest&... rest)
{
    std::memcpy(&first, buf + offset, sizeof(T));
    _unpack_impl(buf, offset + sizeof(T), rest...);
}


//--- Public API ---

//pack: serialize args into token payload in order.
//Compile-time check: sum of sizeof(args) must equal token payload size.
template<unsigned int N, typename... Args>
inline void pack(token<N>& tok, const Args&... args)
{
    static_assert(
        total_sizeof<Args...>::value == N,
        "sitar::pack - total size of arguments does not match token payload size"
    );
    _pack_impl(tok.data(), 0, args...);
}

//unpack: deserialize token payload into args in the same order as pack.
//Compile-time check: sum of sizeof(args) must equal token payload size.
template<unsigned int N, typename... Args>
inline void unpack(token<N>& tok, Args&... args)
{
    static_assert(
        total_sizeof<Args...>::value == N,
        "sitar::unpack - total size of arguments does not match token payload size"
    );
    _unpack_impl(tok.data(), 0, args...);
}

}
#endif

# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

class Rijndael:
    """Configurable Rijndael implementation used as a reference for the cocotb test suite"""

    NB: int # Number of columns in the state
    NK: int # Number of columns in the key
    NR: int # Number of rounds to be performed

    state    : list # Internal Rijndael state
    state_hex: str  # Internal Rijndael state as a hex string
    roundkeys: list # List of all required round keys

    def __init__(self, nb: int, nk: int):
        self.NB = nb
        self.NK = nk
        self.NR = max(nb, nk) + 6

    def encrypt(self, key: list, pt: list) -> list:
        """Takes a key and plaintext as lists of bytes as input and returns the ciphertext"""

        # Perform key expansion to generate roundkeys
        self.expand_key(key)

        # Initialize state and perform initial roundkey addition
        self.state = pt.copy()
        self.update_state_hex()
        self.add_round_key(0)

        # Perform NR-many rounds
        for round_idx in range(0, self.NR):
            self.sub_bytes()
            self.shift_rows()
            if round_idx != self.NR - 1:
                self.mix_columns()
            self.add_round_key(round_idx + 1)

        return self.state
    
    def encrypt_hex(self, key_str: str, pt_str: str) -> str:
        """Wrapper around the encrypt function that uses hex-strings as inputs and outputs"""

        key = [int(key_str[i:i+2], 16) for i in range(0, len(key_str), 2)]
        pt = [int(pt_str[i:i+2], 16) for i in range(0, len(pt_str), 2)]

        return "".join([f"{x:02x}" for x in self.encrypt(key, pt)])

    # ============================================================
    # SubBytes
    # ============================================================
    SBOX = [
        0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
        0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
        0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
        0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
        0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
        0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
        0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
        0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
        0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
        0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
        0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
        0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
        0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
        0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
        0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
        0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
    ]

    def sub_bytes(self) -> None:
        for i in range(4 * self.NB):
            self.state[i] = self.SBOX[self.state[i]]
        self.update_state_hex()

    # ============================================================
    # ShiftRows
    # ============================================================
    def shift_rows(self) -> None:
        OFFSETS = [0,1,2,3] if (self.NB != 8) else [0,1,3,4]

        res = self.state.copy()
        for row_idx in range(4):
            for col_idx in range(self.NB):
                source_col_idx = (col_idx + OFFSETS[row_idx]) % self.NB
                res[4*col_idx+row_idx] = self.state[4*source_col_idx+row_idx]
        
        self.state[:] = res
        self.update_state_hex()

    # ============================================================
    # MixColumns
    # ============================================================
    def mul2(self,a: int) -> int:
        res = (a << 1) & 0xff
        if (a & 0x80):
            res ^= 0x1b
        return res

    def mul3(self, a: int) -> int:
        return self.mul2(a) ^ a 

    def mix_column(self, col: list) -> list:
        a0, a1, a2, a3 = col
        b0 = self.mul2(a0) ^ self.mul3(a1) ^ a2 ^ a3
        b1 = a0 ^ self.mul2(a1) ^ self.mul3(a2) ^ a3
        b2 = a0 ^ a1 ^ self.mul2(a2) ^ self.mul3(a3)
        b3 = self.mul3(a0) ^ a1 ^ a2 ^ self.mul2(a3)
        return [b0, b1, b2, b3]

    def mix_columns(self) -> None:
        for i in range(self.NB):
            col = self.state[4*i : 4*i+4]
            self.state[4*i : 4*i+4] = self.mix_column(col)
        self.update_state_hex()

    # ============================================================
    # AddRoundKey
    # ============================================================
    def add_round_key(self, key_idx: int) -> None:
        for i in range(4 * self.NB):
            self.state[i] ^= self.roundkeys[key_idx][i]
        self.update_state_hex()
    
    # ============================================================
    # Key Expansion / Key Schedule
    # ============================================================
    def word_from_bytes(self, b: list) -> int:
        return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | (b[3] << 0)
    
    def bytes_from_word(self, w: int) -> list:
        return [(w >> 24) & 0xff, (w >> 16) & 0xff, (w >> 8) & 0xff, (w >> 0) & 0xff]
    
    def rotword(self, w: int) -> int:
        return ((w << 8) & 0xffffffff) | ((w >> 24) & 0xff)
    
    def subword(self, w: int) -> int:
        w_bytes = self.bytes_from_word(w)
        return self.word_from_bytes([self.SBOX[x] for x in w_bytes])

    def expand_key(self, key: list) -> None:
        num_words = self.NB * (self.NR + 1)

        # Initialize array containing all expanded words
        w = [0] * num_words

        # Initialization with Rijndael key
        for i in range(self.NK):
            w[i] = self.word_from_bytes(key[4*i:4*i+4])

        # Key schedule to create all other words
        rcon = 0x01

        for i in range(self.NK, num_words):
            xor_term = w[i-1]
            if i % self.NK == 0:
                xor_term = self.subword(self.rotword(xor_term)) ^ (rcon << 24)
                rcon = self.mul2(rcon)
            elif self.NK == 8 and (i % self.NK == 4):
                xor_term = self.subword(xor_term)
            w[i] = w[i-self.NK] ^ xor_term

        # Construct individual round keys
        self.roundkeys = []
        for i in range(self.NR + 1):
            key_words = w[self.NB * i : self.NB * (i + 1)]
            roundkey = [y for x in key_words for y in self.bytes_from_word(x)]
            self.roundkeys.append(roundkey)

    # ============================================================
    # Other helper functions
    # ============================================================
    def update_state_hex(self):
        self.state_hex = "".join([f"{x:02x}" for x in self.state])

# Test functionality of Rijndael implementation
if __name__ == "__main__":
    key = "2b7e151628aed2a6abf7158809cf4f3c"
    pt = "3243f6a8885a308d313198a2e0370734"
    expected_ct = "3925841d02dc09fbdc118597196a0b32"

    rijndael_128_128 = Rijndael(nb = 4, nk = 4)
    ct = rijndael_128_128.encrypt_hex(key, pt)
    
    assert ct == expected_ct, "Rijndael-128-128 ciphertext does not match expected value"
    print("Rijndael-128-128 ciphertext matches the expected value")
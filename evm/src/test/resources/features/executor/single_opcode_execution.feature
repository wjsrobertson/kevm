Feature: Single Opcode Execution

  Check that each opcode executes correctly

  Background: Plenty gas available and plenty balance available
    Given there is 500000 gas remaining
    And the contract address is 0xC0476AC7
    And the account with address 0xC0476AC7 has balance 0x1000

  Scenario: Two numbers can be added using ADD
    Given 0x01 is pushed onto the stack
    And 0x02 is pushed onto the stack
    When opcode ADD is executed
    Then the stack contains 0x03

  Scenario: Contract address is correct using ADDRESS
    Given the contract address is 0xEE
    When opcode ADDRESS is executed
    Then the stack contains 0xEE

  Scenario: Balance of an address is retrieved with BALANCE
    Given an account with address 0xAA has balance 0x123
    And 0xAA is pushed onto the stack
    When opcode BALANCE is executed
    Then the stack contains 0x123

  Scenario: Transaction origin is correct using ORIGIN
    Given transaction origin is 0xBB
    When opcode ORIGIN is executed
    Then the stack contains 0xBB

  Scenario Outline: Caller is returned for CALLER during <callType>
    Given the current caller address is 0xABC
    And the current call type is <callType>
    When opcode CALLER is executed
    Then the stack contains 0xABC

    Examples:
      | callType   |
      | INITIAL    |
      | CALL       |
      | CALLCODE   |
      | STATICCALL |

  Scenario Outline: Current caller is not used if current call is DELEGATECALL during <callType>
    Given the current caller address is 0xABC
    And the current call type is DELEGATECALL
    And the previous caller address is 0xFFF
    And the previous call type is <callType>
    When opcode CALLER is executed
    Then the stack contains 0xFFF

    Examples:
      | callType   |
      | INITIAL    |
      | CALL       |
      | CALLCODE   |
      | STATICCALL |

  Scenario Outline: Call fails if caller doesn't have enough balance - <callType>
    Given the stack contains elements [0x1, 0xADD7E55, 0x100, 0x0, 0x0, 0x0, 0x0]
    And the contract address is 0xC0476AC7
    And the account with address 0xC0476AC7 has balance 0x99
    When opcode <callType> is executed
    Then the last error is now INSUFFICIENT_FUNDS with message "0x00000000000000000000000000000000c0476ac7 has balance of 153 but attempted to send 256"

    Examples:
      | callType |
      | CALL     |
      | CALLCODE |

  Scenario Outline: Call succeeds when caller has enough balance - <callType>
    Given the stack contains elements [0x1, 0xADD7E55, 0x100, 0x0, 0x0, 0x0, 0x0]
    And the contract address is 0xC0476AC7
    And the account with address 0xC0476AC7 has balance 0x100
    When opcode <callType> is executed
    Then there is no last error

    Examples:
      | callType |
      | CALL     |
      | CALLCODE |

  Scenario: Current call value is returned by CALLVALUE
    Given the current call value is 0x1111
    When opcode CALLVALUE is executed
    Then the stack contains 0x1111

  Scenario: Call data can be loaded with CALLDATALOAD
    Given call data is 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
    And 0x0 is pushed onto the stack
    When opcode CALLDATALOAD is executed
    Then the stack contains 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe

  Scenario: Call data can be loaded with CALLDATALOAD and an offset
    Given call data is 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
    And 0x2 is pushed onto the stack
    When opcode CALLDATALOAD is executed
    Then the stack contains 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0000

  Scenario: Call data length can be retrieved with CALLDATASIZE
    Given call data is 0x1234
    When opcode CALLDATASIZE is executed
    Then the stack contains 0x2

  Scenario: Zero call data length can be retrieved with CALLDATASIZE
    Given call data is empty
    When opcode CALLDATASIZE is executed
    Then the stack contains 0x0

  Scenario: Call data can be copied into memory
    Given call data is 0x12345678
    And 0x2 is pushed onto the stack
    And 0x0 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When opcode CALLDATACOPY is executed
    Then 2 bytes of memory from position 3 is 0x1234
    And 3 bytes of memory from position 0 is empty
    And 100 bytes of memory from position 5 is empty

  Scenario: Contract code length can be retrieved with CODESIZE
    Given contract code is [CODESIZE, DUP1, DUP1, BLOCKHASH]
    When the next opcode in the context is executed
    Then the stack contains 0x4

  Scenario: Contract code can be coped into memory with CODECOPY
    Given contract code is [CODECOPY, DUP1, DUP1, BLOCKHASH]
    And 0x4 is pushed onto the stack
    And 0x0 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When the next opcode in the context is executed
    Then 4 bytes of memory from position 3 is 0x39808040
    And 3 bytes of memory from position 0 is empty
    And 100 bytes of memory from position 7 is empty

  Scenario: External contract code can be copied into memory with EXTCODECOPY
    Given contract at address 0x12345 has code [BLOCKHASH, DUP1, DUP1, BLOCKHASH]
    And 0x4 is pushed onto the stack
    And 0x0 is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x12345 is pushed onto the stack
    When opcode EXTCODECOPY is executed
    Then 4 bytes of memory from position 3 is 0x40808040
    And 3 bytes of memory from position 0 is empty
    And 100 bytes of memory from position 7 is empty

  Scenario: External contract code size is returned with EXTCODESIZE
    Given contract at address 0x12345 has code [BLOCKHASH, DUP1, DUP1, BLOCKHASH]
    And 0x12345 is pushed onto the stack
    When opcode EXTCODESIZE is executed
    Then the stack contains 0x4

  Scenario: Return data size is returned with RETURNDATASIZE
    Given return data is 0xABCD
    When opcode RETURNDATASIZE is executed
    Then the stack contains 0x2

  Scenario: Return data is copied into memory with RETURNDATACOPY
    Given return data is 0x10203040
    And 0x4 is pushed onto the stack
    And 0x0 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When opcode RETURNDATACOPY is executed
    Then 4 bytes of memory from position 3 is 0x10203040
    And 3 bytes of memory from position 0 is empty
    And 100 bytes of memory from position 7 is empty

  Scenario: blockhash is returned by BLOCKHASH
    Given recent block 5 has hash 0x123
    And 0x5 is pushed onto the stack
    When opcode BLOCKHASH is executed
    Then the stack contains 0x123

  Scenario: coinbase is returned by COINBASE
    Given coinbase is 0x12345
    When opcode COINBASE is executed
    Then the stack contains 0x12345

  Scenario: time is returned by TIMESTAMP
    Given time is "2014-01-01T14:30:01Z"
    When opcode TIMESTAMP is executed
    Then the stack contains a timestamp of "2014-01-01T14:30:01Z"

  Scenario: current block number is returned by NUMBER
    Given current block number is 0x100
    When opcode NUMBER is executed
    Then the stack contains 0x100

  Scenario: current block difficulty is returned by DIFFICULTY
    Given current block difficulty is 0x100
    When opcode DIFFICULTY is executed
    Then the stack contains 0x100

  Scenario: current block gas limit is returned by GASLIMIT
    Given current block gas limit is 0x100
    When opcode GASLIMIT is executed
    Then the stack contains 0x100

  Scenario: element is removed from stack with POP
    Given 0x5 is pushed onto the stack
    When opcode POP is executed
    Then the stack is empty

  Scenario: only one element is removed from stack with POP
    Given 0x5 is pushed onto the stack
    And 0x6 is pushed onto the stack
    When opcode POP is executed
    Then the stack contains 0x5

  Scenario: memory is loaded onto stack with MLOAD
    Given 0x123456 is stored in memory at location 0x100
    And 0x100 is pushed onto the stack
    When opcode MLOAD is executed
    Then the stack contains 0x1234560000000000000000000000000000000000000000000000000000000000

  Scenario: memory is stored from stack with MSTORE
    Given 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode MSTORE is executed
    Then 32 bytes of memory from position 9 is 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee
    And 9 bytes of memory from position 0 is empty

  Scenario: a byte of memory is stored from stack with MSTORE8
    Given 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode MSTORE8 is executed
    Then 1 byte of memory from position 9 is 0xaa
    And 9 bytes of memory from position 0 is empty
    And 100 bytes of memory from position 10 is empty

  Scenario: data is loaded from storage with SLOAD
    Given 0x123456 is in storage at location 0x100 of current contract
    And 0x100 is pushed onto the stack
    When opcode SLOAD is executed
    Then the stack contains 0x123456

  Scenario: data is stored in storage from stack with SSTORE
    Given 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode SSTORE is executed
    Then data in storage at location 9 of current contract is now 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee
    And 9 bytes of memory from position 0 is empty

  Scenario: data is stored in storage from stack with SSTORE
    Given 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode SSTORE is executed
    Then data in storage at location 9 of current contract is now 0xaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee
    And 9 bytes of memory from position 0 is empty

  Scenario: clearing storage triggers refund for tx origin
    Given 0x123456 is in storage at location 0x9 of current contract
    And transaction origin is 0xBB
    And 0x0 is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode SSTORE is executed
    Then account 0xBB has a refund of 15000

  Scenario: overwriting zero with zero storage triggers no refund
    Given 0x0 is in storage at location 0x9 of current contract
    And transaction origin is 0xBB
    And 0x0 is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode SSTORE is executed
    Then account 0xBB has a refund of 0

  Scenario: overwriting zero with non-zero storage triggers no refund
    Given 0x0 is in storage at location 0x9 of current contract
    And transaction origin is 0xBB
    And 0x1 is pushed onto the stack
    And 0x9 is pushed onto the stack
    When opcode SSTORE is executed
    Then account 0xBB has a refund of 0

  Scenario: can jump to a location in code with JUMP
    Given contract code is [JUMP, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x3 is pushed onto the stack
    When the next opcode in the context is executed
    Then the next position in code is now 3

  Scenario: fail when jumping with JUMP to a location without a JUMPDEST
    Given contract code is [JUMP, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x4 is pushed onto the stack
    When the next opcode in the context is executed
    Then the last error is now INVALID_JUMP_DESTINATION with message "Invalid jump destination 0x4"

  Scenario: fail when jumping with JUMP to a location outside the contract code
    Given contract code is [JUMP, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x400 is pushed onto the stack
    When the next opcode in the context is executed
    Then the last error is now INVALID_JUMP_DESTINATION with message "Invalid jump destination 0x400"

  Scenario: can jump to a location in code with JUMPI when condition is 1
    Given contract code is [JUMPI, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x1 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When the next opcode in the context is executed
    Then the next position in code is now 3

  Scenario: can jump to a location in code with JUMPI when condition is 2
    Given contract code is [JUMPI, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x2 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When the next opcode in the context is executed
    Then the next position in code is now 3

  Scenario: fail when jumping with JUMPI to a location without a JUMPDEST
    Given contract code is [JUMPI, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x1 is pushed onto the stack
    And 0x4 is pushed onto the stack
    When the next opcode in the context is executed
    Then the last error is now INVALID_JUMP_DESTINATION with message "Invalid jump destination 0x4"

  Scenario: fail when jumping with JUMPI to a location outside the contract code
    Given contract code is [JUMPI, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x1 is pushed onto the stack
    And 0x5 is pushed onto the stack
    When the next opcode in the context is executed
    Then the last error is now INVALID_JUMP_DESTINATION with message "Invalid jump destination 0x5"

  Scenario: won't jump to a location in code with JUMPI when condition is 0
    Given contract code is [JUMPI, DUP1, DUP1, JUMPDEST, SSTORE, GAS]
    And 0x0 is pushed onto the stack
    And 0x3 is pushed onto the stack
    When the next opcode in the context is executed
    Then the next position in code is now 1

  Scenario: contract position is retrieved with PC
    Given contract code is [JUMPDEST, DUP1, DUP1, PC, SSTORE, GAS]
    And the code location is 3
    When the next opcode in the context is executed
    Then the stack contains 0x3

  Scenario: max byte address in memory is returned by MSIZE
    Given 0x123456 is stored in memory at location 0x0
    When opcode MSIZE is executed
    Then the stack contains 0x3

  Scenario: remaining gas is returned by GAS minus two for cost of GAS opcode execution
    Given there is 5 gas remaining
    When opcode GAS is executed
    Then the stack contains 0x3

  Scenario: Push opcodes push the right amount of bytes onto the stack
    Given contract code ends with 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    When the push opcode is executed it will have data on stack
      | PUSH1  | 0xff                                                               |
      | PUSH2  | 0xffff                                                             |
      | PUSH3  | 0xffffff                                                           |
      | PUSH4  | 0xffffffff                                                         |
      | PUSH5  | 0xffffffffff                                                       |
      | PUSH6  | 0xffffffffffff                                                     |
      | PUSH7  | 0xffffffffffffff                                                   |
      | PUSH8  | 0xffffffffffffffff                                                 |
      | PUSH9  | 0xffffffffffffffffff                                               |
      | PUSH10 | 0xffffffffffffffffffff                                             |
      | PUSH11 | 0xffffffffffffffffffffff                                           |
      | PUSH12 | 0xffffffffffffffffffffffff                                         |
      | PUSH13 | 0xffffffffffffffffffffffffff                                       |
      | PUSH14 | 0xffffffffffffffffffffffffffff                                     |
      | PUSH15 | 0xffffffffffffffffffffffffffffff                                   |
      | PUSH16 | 0xffffffffffffffffffffffffffffffff                                 |
      | PUSH17 | 0xffffffffffffffffffffffffffffffffff                               |
      | PUSH18 | 0xffffffffffffffffffffffffffffffffffff                             |
      | PUSH19 | 0xffffffffffffffffffffffffffffffffffffff                           |
      | PUSH20 | 0xffffffffffffffffffffffffffffffffffffffff                         |
      | PUSH21 | 0xffffffffffffffffffffffffffffffffffffffffff                       |
      | PUSH22 | 0xffffffffffffffffffffffffffffffffffffffffffff                     |
      | PUSH23 | 0xffffffffffffffffffffffffffffffffffffffffffffff                   |
      | PUSH24 | 0xffffffffffffffffffffffffffffffffffffffffffffffff                 |
      | PUSH25 | 0xffffffffffffffffffffffffffffffffffffffffffffffffff               |
      | PUSH26 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffff             |
      | PUSH27 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff           |
      | PUSH28 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff         |
      | PUSH29 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff       |
      | PUSH30 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff     |
      | PUSH31 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff   |
      | PUSH32 | 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff |

  Scenario: the dup opcodes duplicate the stack element at the correct depth
    Given 0x1 is pushed onto the stack
    And 0x2 is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x4 is pushed onto the stack
    And 0x5 is pushed onto the stack
    And 0x6 is pushed onto the stack
    And 0x7 is pushed onto the stack
    And 0x8 is pushed onto the stack
    And 0x9 is pushed onto the stack
    And 0x10 is pushed onto the stack
    And 0x11 is pushed onto the stack
    And 0x12 is pushed onto the stack
    And 0x13 is pushed onto the stack
    And 0x14 is pushed onto the stack
    And 0x15 is pushed onto the stack
    And 0x16 is pushed onto the stack
    When the DUP opcode is executed it will have data on stack
      | DUP1  | 0x16 |
      | DUP2  | 0x15 |
      | DUP3  | 0x14 |
      | DUP4  | 0x13 |
      | DUP5  | 0x12 |
      | DUP6  | 0x11 |
      | DUP7  | 0x10 |
      | DUP8  | 0x09 |
      | DUP9  | 0x08 |
      | DUP10 | 0x07 |
      | DUP11 | 0x06 |
      | DUP12 | 0x05 |
      | DUP13 | 0x04 |
      | DUP14 | 0x03 |
      | DUP15 | 0x02 |
      | DUP16 | 0x01 |

  Scenario: the swap opcodes swap the stack element at the correct depth
    Given 0x1 is pushed onto the stack
    And 0x2 is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x4 is pushed onto the stack
    And 0x5 is pushed onto the stack
    And 0x6 is pushed onto the stack
    And 0x7 is pushed onto the stack
    And 0x8 is pushed onto the stack
    And 0x9 is pushed onto the stack
    And 0x10 is pushed onto the stack
    And 0x11 is pushed onto the stack
    And 0x12 is pushed onto the stack
    And 0x13 is pushed onto the stack
    And 0x14 is pushed onto the stack
    And 0x15 is pushed onto the stack
    And 0x16 is pushed onto the stack
    And 0xAA is pushed onto the stack
    When the SWAP opcode is executed it will have data on top of stack and 0xAA at index
      | SWAP1  | 0x16 | 1  |
      | SWAP2  | 0x15 | 2  |
      | SWAP3  | 0x14 | 3  |
      | SWAP4  | 0x13 | 4  |
      | SWAP5  | 0x12 | 5  |
      | SWAP6  | 0x11 | 6  |
      | SWAP7  | 0x10 | 7  |
      | SWAP8  | 0x09 | 8  |
      | SWAP9  | 0x08 | 9  |
      | SWAP10 | 0x07 | 10 |
      | SWAP11 | 0x06 | 11 |
      | SWAP12 | 0x05 | 12 |
      | SWAP13 | 0x04 | 13 |
      | SWAP14 | 0x03 | 14 |
      | SWAP15 | 0x02 | 15 |
      | SWAP16 | 0x01 | 16 |

  Scenario: transaction logs are raised with the LOG0 opcode
    Given 0x123456 is stored in memory at location 0x0
    And 0x3 is pushed onto the stack
    And 0x0 is pushed onto the stack
    When opcode LOG0 is executed
    Then a log has been generated with data 0x123456
    And the log has no topics

  Scenario: transaction logs are raised with the LOG1 opcode
    Given 0x123456 is stored in memory at location 0x0
    And 0xA is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x0 is pushed onto the stack
    When opcode LOG1 is executed
    Then a log has been generated with data 0x123456
    And the log has topic data
      | 0xA |

  Scenario: transaction logs are raised with the LOG2 opcode
    Given 0x123456 is stored in memory at location 0x0
    And 0xB is pushed onto the stack
    And 0xA is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x0 is pushed onto the stack
    When opcode LOG2 is executed
    Then a log has been generated with data 0x123456
    And the log has topic data
      | 0xA |
      | 0xB |

  Scenario: transaction logs are raised with the LOG3 opcode
    Given 0x123456 is stored in memory at location 0x0
    And 0xC is pushed onto the stack
    And 0xB is pushed onto the stack
    And 0xA is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x0 is pushed onto the stack
    When opcode LOG3 is executed
    Then a log has been generated with data 0x123456
    And the log has topic data
      | 0xA |
      | 0xB |
      | 0xC |

  Scenario: transaction logs are raised with the LOG4 opcode
    Given 0x123456 is stored in memory at location 0x0
    And 0xD is pushed onto the stack
    And 0xC is pushed onto the stack
    And 0xB is pushed onto the stack
    And 0xA is pushed onto the stack
    And 0x3 is pushed onto the stack
    And 0x0 is pushed onto the stack
    When opcode LOG4 is executed
    Then a log has been generated with data 0x123456
    And the log has topic data
      | 0xA |
      | 0xB |
      | 0xC |
      | 0xD |

  Scenario: a contract is created and deployed with CREATE
    Given the contract address is 0xEE
    And the account with address 0xEE has balance 0x9
    And 0x123456 is stored in memory at location 0x100
    And 0x3 is pushed onto the stack
    And 0x100 is pushed onto the stack
    And 0x4 is pushed onto the stack
    When opcode CREATE is executed
    Then the balance of account 0xEE is now 5
    And the balance of account 0xcb5e6c71453ca7b77d1bdce5d5bbac1c3ef28730 is now 4
    And the code at address 0xcb5e6c71453ca7b77d1bdce5d5bbac1c3ef28730 is 0x123456
    And the stack contains 0xcb5e6c71453ca7b77d1bdce5d5bbac1c3ef28730


  Scenario: a contract is created and deployed with CREATE2
    Given the contract address is 0xEE
    And the account with address 0xEE has balance 0x9
    And 0x123456 is stored in memory at location 0x100
    And the stack contains elements [0x4, 0x1, 0x100, 0x3]
    When opcode CREATE2 is executed
    Then the balance of account 0xEE is now 5
    And the balance of account 0xa2a956ee5601fc53037cc0eec353e9606217d653 is now 4
    And the code at address 0xa2a956ee5601fc53037cc0eec353e9606217d653 is 0x123456
    And the stack contains 0xa2a956ee5601fc53037cc0eec353e9606217d653


  Scenario: contract creation fails when sender doesn't have enough balance
    Given the contract address is 0xEE
    And the account with address 0xEE has balance 0x3
    And 0x123456 is stored in memory at location 0x100
    And the stack contains elements [0x4, 0x1, 0x100, 0x3]
    When opcode CREATE2 is executed
    Then the balance of account 0xEE is now 3
    And there is now no account with address 0xdb5f240f1a0f0dde5420d6fdf3e7fdca02441426
    Then the last error is now INSUFFICIENT_FUNDS with message "0x00000000000000000000000000000000000000ee has balance of 3 but attempted to send 0x0000000000000000000000000000000000000000000000000000000000000004"


  Scenario: Execution is halted with STOP in main contract
    Given the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A5 | 0x200        | 0x2      |
    And there is only one call on the stack
    When opcode STOP is executed
    Then the call stack is now 0 deep
    And the execution context is now marked as complete
    And return data is now empty

  Scenario: Execution is halted with STOP in child contract
    Given the previous call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A5 | 0x0          | 0x0      |
    And the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x2      |
    When opcode STOP is executed
    Then the call stack is now 1 deep
    And the execution context is now marked as not complete
    And return data is now empty
    And the stack contains 0x1

  Scenario: Execution is halted with RETURN in child contract
    Given the previous call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A5 | 0x0          | 0x0      |
    And the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    And 0x123456 is stored in memory at location 0x100
    And 0x3 is pushed onto the stack
    And 0x100 is pushed onto the stack
    When opcode RETURN is executed
    Then the call stack is now 1 deep
    And the execution context is now marked as not complete
    And return data is now 0x123456
    And 3 bytes of memory from position 0x200 is 0x123456
    And the stack contains 0x1

  Scenario: Execution is halted with INVALID in main contract
    Given the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    And there is only one call on the stack
    When opcode INVALID is executed
    Then the call stack is now 0 deep
    And the execution context is now marked as complete

  Scenario: Execution is halted with INVALID in child contract
    Given the previous call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A5 | 0x0          | 0x0      |
    And the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    When opcode INVALID is executed
    Then the call stack is now 1 deep
    And the execution context is now marked as not complete
    And return data is now empty
    And the last error is now INVALID_INSTRUCTION with message "Invalid instruction"
    And the stack contains 0x0

  Scenario: Execution is halted with REVERT in main contract
    Given the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    And there is only one call on the stack
    And 0x123456 is stored in memory at location 0x100
    And 0x3 is pushed onto the stack
    And 0x100 is pushed onto the stack
    When opcode REVERT is executed
    Then the call stack is now 0 deep
    And the execution context is now marked as complete

  Scenario: Execution is halted with REVERT in child contract
    Given the previous call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A5 | 0x0          | 0x0      |
    And the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    And 0x123456 is stored in memory at location 0x100
    And 0x3 is pushed onto the stack
    And 0x100 is pushed onto the stack
    When opcode REVERT is executed
    Then the call stack is now 1 deep
    And the execution context is now marked as not complete
    And return data is now 0x123456
    And 3 bytes of memory from position 0x200 is 0x123456
    And the stack contains 0x0

  Scenario: Execution is halted with SUICIDE in main contract
    Given the current call is:
      | type | caller address | calldata | contract address | value | gas     | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A500 | 0x200        | 0x3      |
    And there is only one call on the stack
    And the account with address 0xFFFFFFF has balance 0x1234
    And 0xAAAAAAA is pushed onto the stack
    When opcode SUICIDE is executed
    Then the call stack is now 0 deep
    And the execution context is now marked as complete
    And the balance of account 0xAAAAAAA is now 0x1234
    And the balance of account 0xFFFFFFF is now 0
    And the code at address 0xFFFFFFF is empty

  Scenario: Execution is halted with SUICIDE in child contract
    Given the previous call is:
      | type | caller address | calldata | contract address | value | gas     | out location | out size |
      | CALL | 0xEEEEEE       | 0x123456 | 0xADD8E55        | 0x0   | 0x6A500 | 0x0          | 0x0      |
    And the current call is:
      | type | caller address | calldata | contract address | value | gas     | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A500 | 0x200        | 0x3      |
    And the account with address 0xFFFFFFF has balance 0x1234
    And 0xAAAAAAA is pushed onto the stack
    When opcode SUICIDE is executed
    Then the call stack is now 1 deep
    And the execution context is now marked as not complete
    And the balance of account 0xAAAAAAA is now 0x1234
    And the balance of account 0xFFFFFFF is now 0
    And the code at address 0xFFFFFFF is empty
    And the stack contains 0x1

  Scenario: Execution is halted with unknown opcode in main contract
    Given the current call is:
      | type | caller address | calldata | contract address | value | gas   | out location | out size |
      | CALL | 0xADD8E55      | 0x123456 | 0xFFFFFFF        | 0x0   | 0x6A5 | 0x200        | 0x3      |
    And there is only one call on the stack
    When opcode 0xBB is executed
    Then the call stack is now 0 deep
    And the execution context is now marked as complete
    And the last error is now INVALID_INSTRUCTION with message "Invalid instruction: 0xbb"

  Scenario: fail when not enough elements on the stack
    Given 0x5 is pushed onto the stack
    When opcode ADD is executed
    Then the last error is now STACK_UNDERFLOW with message "Stack not deep enough for ADD"

  Scenario: fail when over 1024 elements on stack
    Given the stack contains 1024 elements
    When opcode DUP1 is executed
    Then the last error is now STACK_OVERFLOW with message "Stack overflow"

  Scenario Outline: Can call any of the read-only opcodes in static context <opcode>
    Given the current call type is STATICCALL
    And the stack contains elements [0x1, 0x20, 0x3, 0x4, 0x5, 0x6, 0x7]
    When opcode <opcode> is executed
    Then there is no last error

    Examples:
      | opcode         |
      | STOP           |
      | ADD            |
      | SUB            |
      | MUL            |
      | DIV            |
      | SDIV           |
      | MOD            |
      | SMOD           |
      | EXP            |
      | NOT            |
      | LT             |
      | GT             |
      | SLT            |
      | SGT            |
      | EQ             |
      | ISZERO         |
      | AND            |
      | OR             |
      | XOR            |
      | BYTE           |
      | SHL            |
      | SHR            |
      | SAR            |
      | ADDMOD         |
      | MULMOD         |
      | SIGNEXTEND     |
      | SHA3           |
      | SHA3           |
      | JUMP           |
      | JUMPI          |
      | PC             |
      | POP            |
      | DUP1           |
      | SWAP1          |
      | MLOAD          |
      | MSTORE         |
      | MSTORE8        |
      | SLOAD          |
      | MSIZE          |
      | GAS            |
      | ADDRESS        |
      | BALANCE        |
      | CALLER         |
      | CALLVALUE      |
      | CALLDATALOAD   |
      | CALLDATASIZE   |
      | CALLDATACOPY   |
      | CODESIZE       |
      | CODECOPY       |
      | EXTCODESIZE    |
      | EXTCODECOPY    |
      | RETURNDATASIZE |
      | RETURNDATACOPY |
      | CALLCODE       |
      | DELEGATECALL   |
      | STATICCALL     |
      | RETURN         |
      | ORIGIN         |
      | GASPRICE       |
      | BLOCKHASH      |
      | COINBASE       |
      | TIMESTAMP      |
      | NUMBER         |
      | DIFFICULTY     |
      | GASLIMIT       |
      | JUMPDEST       |
      | REVERT         |


  Scenario Outline: fail if trying to execute non-read only opcodes in static context <opcode>
    Given the current call type is STATICCALL
    And the stack contains elements [0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7]
    When opcode <opcode> is executed
    Then the last error is now STATE_CHANGE_STATIC_CALL with message "<opcode> not allowed in static call"

    Examples:
      | opcode  |
      | SSTORE  |
      | CREATE  |
      | CREATE2 |
      | SUICIDE |
      | LOG0    |
      | LOG1    |
      | LOG2    |
      | LOG3    |
      | LOG4    |

  Scenario: Can call INVALID opcode from static context
    Given the current call type is STATICCALL
    When opcode INVALID is executed
    Then the last error is now INVALID_INSTRUCTION with message "Invalid instruction"

  Scenario: Can't execute CALL with non-zero value in STATIC context
    Given the current call type is STATICCALL
    And the stack contains elements [0x1, 0xADD7E55, 0x100, 0x0, 0x0, 0x0, 0x0]
    When opcode CALL is executed
    Then the last error is now STATE_CHANGE_STATIC_CALL with message "CALL not allowed in static call"

  Scenario: Can execute CALL with zero value in STATIC context
    Given the current call type is STATICCALL
    And the stack contains elements [0x1, 0xADD7E55, 0x0, 0x0, 0x0, 0x0, 0x0]
    When opcode CALL is executed
    Then there is no last error

  Scenario: Execution is halted at end of main contract
    Given contract code is [DUP1, DUP1, GAS]
    And the code location is 3
    When the next opcode in the context is executed
    Then the execution context is now marked as complete
    And return data is now empty

package com.gammadex.kevin.evm.gas

import java.math.BigInteger


enum class Refund(val wei: Int) {
    SelfDestruct(24000),
    StorageClear(15000)
}

enum class GasCategory {
    Formula,
    MemoryUsage,
    Simple
}

enum class GasCost(val cost: Int) {
    Zero(0),
    Base(2),
    VeryLow(3),
    Low(5),
    Mid(8),
    High(10),
    ExtCode(700),
    Balance(400),
    Sha3(30),
    Sha3Word(6),
    SLoad(200),
    JumpDest(1),
    SSet(20000),
    SReset(5000),
    SelfDestruct(5000),
    Create(32000),
    CodeDeposit(200),
    Call(700),
    CallValue(9000),
    CallStipend(2300),
    NewAccount(25000),
    Exp(10),
    ExpByte(50),
    Memory(3),
    BlockHash(20),
    Formula(0),
    Copy(3),
    Log(375),
    LogData(8),
    LogTopic(375);

    val costBigInt: BigInteger
        get() = cost.toBigInteger()
}
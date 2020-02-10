package org.kevm.evm.gas

import java.math.BigInteger

enum class Refund(val wei: Int) {
    SelfDestruct(24000),
    StorageClear(15000)
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
    SLoadHomestead(50),
    SLoadEip150(200),
    JumpDest(1),
    SSet(20000),
    SReset(5000),
    SelfDestructEip150(5000),
    SelfDestructHomestead(0),
    Create(32000),
    TxCreate(32000),
    TxDataZero(4),
    TxDataNonZero(68),
    Transaction(21000),
    CodeDeposit(200),
    Call(700),
    CallValue(9000),
    CallStipend(2300),
    NewAccountEip150(25000),
    NewAccountHomestead(0),
    Exp(10),
    ExpByteEip160(50),
    ExpByteHomestead(10),
    Memory(3),
    BlockHash(20),
    Formula(0),
    Copy(3),
    Log(375),
    LogData(8),
    LogTopic(375),
    QuadDivisor(20);

    val costBigInt: BigInteger
        get() = cost.toBigInteger()
}
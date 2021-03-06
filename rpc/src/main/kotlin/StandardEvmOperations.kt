package org.kevem.rpc

import org.kevem.common.Logger
import org.kevem.evm.StatefulTransactionProcessor
import org.kevem.common.conversions.bytesToString
import org.kevem.evm.crypto.keccak256
import org.kevem.evm.model.*
import org.kevem.common.Byte
import org.kevem.common.CategorisedKevemException
import org.kevem.common.conversions.toByteList
import org.web3j.crypto.SignedRawTransaction
import org.web3j.crypto.TransactionDecoder
import java.math.BigInteger
import org.kevem.common.conversions.*

sealed class BlockReference {
    companion object {
        fun fromString(blockValue: String?): BlockReference =
            when {
                blockValue == null || blockValue == "latest" || blockValue == "" -> LatestBlock
                blockValue == "pending" -> PendingBlock
                blockValue == "earliest" -> EarliestBlock
                !blockValue.startsWith("0x") ->
                    throw CategorisedKevemException("Invalid block number - missing 0x prefix", -32602)
                !blockValue.matches("^0x[0-9a-faA-F]+$".toRegex()) ->
                    throw CategorisedKevemException("Invalid block number", -32602)
                else -> NumericBlock(toBigInteger(blockValue))
            }
    }
}

data class NumericBlock(val number: BigInteger) : BlockReference()
object LatestBlock : BlockReference()
object PendingBlock : BlockReference()
object EarliestBlock : BlockReference()

class StandardEvmOperations(
    private val stp: StatefulTransactionProcessor,
    private val evmConfig: EvmConfig,
    private val log: Logger = Logger.createLogger(StandardEvmOperations::class)
) {

    fun getTransactionCount(address: Address, block: BlockReference): BigInteger = stp.getWorldState().let { ws ->
        return getTransactions(address, block, ws).size.toBigInteger()
    }

    fun sendRawTransaction(signedTxData: List<Byte>): List<Byte> {
        val tran = TransactionDecoder.decode(bytesToString(signedTxData)) as SignedRawTransaction

        val from =
            if (tran.from != null) Address(tran.from)
            else throw RuntimeException("can't determine transaction sender")

        val to = if (isEmptyHex(tran.to)) null else Address(tran.to)
        val value = tran.value ?: BigInteger.ZERO

        val hash = keccak256(signedTxData)
        val tx = TransactionMessage(
            from,
            to,
            value,
            tran.gasPrice,
            tran.gasLimit,
            toByteList(tran.data),
            tran.nonce,
            hash
        )

        log.debug("received raw tx with nonce ${tran.nonce} / ${tx.nonce}")

        return sendTransaction(tx)
    }

    fun sendTransaction(tx: TransactionMessage): List<Byte> {
        stp.process(tx)
        return tx.hash
    }

    fun getTransactionReceipt(txHash: List<Byte>) = getTxAndBlockByTxHash(txHash)

    private fun getTransactions(address: Address, block: BlockReference, ws: WorldState): List<MinedTransaction> =
        when (block) {
            is LatestBlock -> ws.blocks
                .flatMap { it.transactions }
                .filter { it.message.from == address }
            is EarliestBlock -> ws.blocks
                .first().transactions
                .filter { it.message.from == address }
            is NumericBlock -> ws.blocks
                .filter { it.block.number <= block.number }
                .flatMap { it.transactions }
                .filter { it.message.from == address }
            is PendingBlock -> ws.blocks
                .flatMap { it.transactions }
                .filter { it.message.from == address }
        }

    fun coinbase(): Address = evmConfig.coinbase

    fun blockNumber(): BigInteger = stp.getWorldState().blocks.last().block.number

    fun getBalance(address: Address, block: BlockReference?): BigInteger =
        processWorldStateAtBlock(block) { ws ->
            ws.accounts.balanceOf(address)
        }

    fun getStorageAt(address: Address, location: BigInteger, block: BlockReference): Word =
        processWorldStateAtBlock(block) { ws ->
            ws.accounts.storageAt(address, location)
        }

    fun getBlockTransactionCountByHash(hash: List<Byte>): Int =
        stp.getWorldState().blocks.find { it.hash == hash }?.transactions?.size ?: 0

    fun getBlockTransactionCountByNumber(block: BlockReference): Int = stp.getWorldState().let { ws ->
        return when (block) {
            is LatestBlock -> ws.blocks.last().transactions.size
            is EarliestBlock -> ws.blocks.first().transactions.size
            is NumericBlock -> ws.blocks.find { it.block.number == block.number }?.transactions?.size ?: 0
            is PendingBlock -> 0
        }
    }

    fun getUncleCountByBlockHash(hash: List<Byte>): BigInteger = BigInteger.ZERO

    fun getUncleCountByBlockNumber(block: BlockReference): BigInteger = BigInteger.ZERO

    fun getCode(address: Address, block: BlockReference): List<Byte> =
        processWorldStateAtBlock(block) { ws ->
            ws.accounts.contractAt(address)?.code?.toList() ?: emptyList()
        }

    fun getBlockByHash(hash: List<Byte>): MinedBlock? =
        stp.getWorldState().blocks.find { it.hash == hash }

    fun getBlockByNumber(block: BlockReference): MinedBlock? =
        processWorldStateAtBlock(block) { ws ->
            ws.blocks.last()
        }

    fun getTransactionByHash(txHash: List<Byte>) = getTxAndBlockByTxHash(txHash)

    private fun getTxAndBlockByTxHash(txHash: List<Byte>): Pair<MinedTransaction, MinedBlock>? =
        stp.getWorldState().let { ws ->
            val block = ws.blocks.find { b ->
                b.transactions.any { it.message.hash == txHash }
            }

            if (block == null) return null
            else Pair(block.transactions.find { it.message.hash == txHash }!!, block)
        }

    fun getTransactionByBlockHashAndIndex(
        blockHash: List<Byte>,
        txIndex: BigInteger
    ): Pair<MinedTransaction, MinedBlock>? = stp.getWorldState().let { ws ->
        val block = ws.blocks.find { it.hash == blockHash }

        return getPairOfBlockAndTxByIndex(block, txIndex)
    }

    fun getTransactionByBlockNumberAndIndex(
        block: BlockReference,
        txIndex: BigInteger
    ): Pair<MinedTransaction, MinedBlock>? = when (block) {
        is LatestBlock -> getPairOfBlockAndTxByIndex(stp.getWorldState().blocks.last(), txIndex)
        is NumericBlock -> getPairOfBlockAndTxByIndex(
            stp.getWorldState().blocks.find { it.block.number == block.number }, txIndex
        )
        is EarliestBlock -> getPairOfBlockAndTxByIndex(stp.getWorldState().blocks.first(), txIndex)
        is PendingBlock -> getPairOfBlockAndTxByIndex(stp.getPendingWorldState().blocks.last(), txIndex)
    }

    fun getNonce(address: Address): BigInteger = stp.getWorldState().accounts.nonceOf(address)

    fun pendingBlockGasLimit(): BigInteger = stp.getWorldState().blocks.last().block.gasLimit

    fun estimateGas(tx: TransactionMessage, block: BlockReference): BigInteger =
        processWorldStateAtBlock(block) { ws ->
            stp.call(tx, ws).gasUsed
        }

    fun call(tx: TransactionMessage, block: BlockReference): List<Byte> =
        processWorldStateAtBlock(block) { ws ->
            stp.call(tx, ws).returnData
        }

    fun getLogs(
        from: BlockReference? = null,
        to: BlockReference? = null,
        address: List<Address>? = null,
        topics: List<Word>? = null,
        blockHash: List<Byte>? = null
    ) = stp.getWorldState().let { ws ->
        val fromBlock = getBlockNumber(from, ws) ?: ws.blocks.first().block.number
        val toBlock = getBlockNumber(to, ws) ?: ws.blocks.last().block.number

        val blocks = ws.blocks
            .filter { it.block.number >= fromBlock }
            .filter { it.block.number <= toBlock }
            .filter { blockHash == null || blockHash == it.hash }

        blocks.flatMap { it.transactions }
            .flatMap { it.result.logs }
            .filter { address == null || address != null } // TODO - include source address in Log and filter here - https://github.com/wjsrobertson/kevem/issues/32
            .filter { topics == null || it.topics.any { t -> topics.contains(t) } }
    }

    fun chainId() = evmConfig.chainId

    fun getBlockNumber(block: BlockReference?, ws: WorldState): BigInteger? {
        return when (block) {
            is LatestBlock -> ws.blocks.last().block.number
            is NumericBlock -> block.number
            is EarliestBlock -> ws.blocks.first().block.number
            is PendingBlock -> ws.blocks.last().block.number
            null -> null
        }
    }

    private fun <T> processWorldStateAtBlock(
        block: BlockReference?,
        op: (ws: WorldState) -> T
    ): T {
        return when (block) {
            is PendingBlock -> op(stp.getPendingWorldState())
            is EarliestBlock -> op(stp.getEarliestWorldState())
            is NumericBlock -> {
                val ws = stp.findWorldStateAtBlock(block.number)
                if (ws != null) op(ws)
                else throw CategorisedKevemException("Unknown block number", -32602)
            }
            else -> op(stp.getWorldState())
        }
    }

    private fun getPairOfBlockAndTxByIndex(
        block: MinedBlock?,
        txIndex: BigInteger
    ): Pair<MinedTransaction, MinedBlock>? =
        if (block == null) null
        else {
            val tx = block.transactions.getOrNull(txIndex.toInt()) // TODO - should be indexed by BigInteger
            if (tx == null) null
            else Pair(tx, block)
        }
}

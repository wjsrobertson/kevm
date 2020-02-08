package org.kevm.evm

import org.kevm.evm.crypto.*
import org.kevm.evm.model.Address
import org.kevm.evm.model.Byte
import org.kevm.evm.model.ExecutionContext
import org.kevm.evm.ops.CallArguments
import org.kevm.evm.precompiled.expmod
import java.math.BigInteger

// TODO - convert to class
object PrecompiledContractExecutor {

    fun isPrecompiledContractCall(address: Address) =
        address.value <= BigInteger("8")

    fun doPrecompiled(context: ExecutionContext, args: CallArguments): ExecutionContext =
        when (args.address.value.toInt()) {
            1 -> executePrecompiled(context, args) { input -> Byte.trimAndPadLeft(ecdsarecover(input), 32) }
            2 -> executePrecompiled(context, args) { input -> sha256(input).data }
            3 -> executePrecompiled(context, args) { input -> ripemd160(input).data }
            4 -> executePrecompiled(context, args) { input -> input }
            5 -> executePrecompiled(context, args) { input -> expmod(input) }
            6 -> executePrecompiled(context, args) { input -> bnAdd(input) }
            7 -> executePrecompiled(context, args) { input -> bnMul(input) }
            8 -> executePrecompiled(context, args) { input -> snarkV(input) }
            else -> TODO()
        }

    private fun executePrecompiled(
        context: ExecutionContext,
        args: CallArguments,
        func: (List<Byte>) -> List<Byte>
    ): ExecutionContext =
        with(context) {
            val (input, newMemory) = memory.read(args.inLocation, args.inSize)
            val newMemory2 = func(input).let {
                if (it.isNotEmpty())
                    newMemory.write(args.outLocation, Byte.trimAndPadRight(it, args.outSize))
                else
                    newMemory
            }

            updateCurrentCallCtx(memory = newMemory2)
        }

}
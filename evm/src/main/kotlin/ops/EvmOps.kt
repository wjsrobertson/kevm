package org.kevem.evm.ops

import org.kevem.evm.model.ExecutionContext
import org.kevem.evm.model.Log

object EvmOps {
    fun push(context: ExecutionContext, numBytes: Int): ExecutionContext {
        val call = context.callStack.last()
        val data = call.code.read((context.currentLocation + 1).toBigInteger(), numBytes)
        val newStack = context.stack.push(data)

        return context.updateCurrentCallCtx(stack = newStack)
    }

    fun dup(context: ExecutionContext, offset: Int): ExecutionContext {
        val data = context.stack.peek(offset)
        val newStack = context.stack.push(data)

        return context.updateCurrentCallCtx(stack = newStack)
    }

    fun swap(context: ExecutionContext, offset: Int): ExecutionContext {
        val a = context.stack.peekWord(offset + 1)
        val b = context.stack.peekWord()
        val newStack = context.stack
            .set(offset + 1, b.data)
            .set(0, a.data)

        return context.updateCurrentCallCtx(stack = newStack)
    }

    fun log(context: ExecutionContext, num: Int): ExecutionContext = with(context) {
        val (elements, newStack) = stack.popWords(2)
        val (p, s) = elements
        val (topics, newStack2) = newStack.popWords(num)

        val (data, newMemory) = memory.read(p.toBigInt(), s.toInt())
        val newLog = Log(data, topics)

        return context
            .updateCurrentCallCtx(stack = newStack2, memory = newMemory)
            .copy(logs = context.logs + newLog)
    }

    fun pop(context: ExecutionContext): ExecutionContext = with(context) {
        val (_, newStack) = stack.pop()

        context.updateCurrentCallCtx(stack = newStack)
    }
}
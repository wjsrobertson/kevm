package gas

import org.junit.jupiter.api.Test

import org.assertj.core.api.Assertions.assertThat
import org.kevem.evm.gas.TransactionValidator
import org.kevem.evm.model.Address
import org.kevem.evm.model.Features
import org.kevem.evm.model.TransactionMessage
import test.TestObjects
import java.math.BigInteger

class TransactionValidatorTest {

    private val underTest = TransactionValidator()

    @Test
    internal fun `up front cost is valid when balance is equal`() {
        val worldState = TestObjects.worldState
        val transaction = TransactionMessage(
            Address("0x1"), Address("0x2"), BigInteger.ZERO, BigInteger.ZERO, BigInteger("21000"), emptyList(), BigInteger.ZERO
        )

        val valid = underTest.isValid(worldState, transaction, Features(emptyList()))

        assertThat(valid).isTrue()
    }
}
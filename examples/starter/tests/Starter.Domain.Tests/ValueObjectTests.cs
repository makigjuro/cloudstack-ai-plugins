using Starter.Domain.ValueObjects;

namespace Starter.Domain.Tests;

public class ValueObjectTests
{
    [Fact]
    public void OrderId_SameValue_AreEqual()
    {
        // Arrange
        var value = Guid.NewGuid();

        // Act
        var first = new OrderId(value);
        var second = new OrderId(value);

        // Assert
        first.Should().Be(second);
        (first == second).Should().BeTrue();
        first.GetHashCode().Should().Be(second.GetHashCode());
    }

    [Fact]
    public void OrderId_DifferentValues_AreNotEqual()
    {
        // Assert
        (OrderId.New() == OrderId.New()).Should().BeFalse();
    }

    [Fact]
    public void OrderId_EmptyGuid_Throws()
    {
        // Act
        var act = () => new OrderId(Guid.Empty);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void TenantId_EmptyGuid_Throws()
    {
        // Act
        var act = () => new TenantId(Guid.Empty);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void DifferentValueObjectTypes_SameGuid_AreNotEqual()
    {
        // Arrange
        var value = Guid.NewGuid();

        // Assert
        new OrderId(value).Equals(new TenantId(value)).Should().BeFalse();
    }
}

using Starter.Domain.Entities;
using Starter.Domain.Events;
using Starter.Domain.ValueObjects;

namespace Starter.Domain.Tests;

public class OrderTests
{
    private static readonly TenantId Tenant = new(Guid.NewGuid());

    [Fact]
    public void Create_ValidInput_CreatesPendingOrder()
    {
        // Act
        var order = Order.Create(Tenant, "  Ada Lovelace  ", 42.50m);

        // Assert
        order.Id.Should().NotBeNull();
        order.TenantId.Should().Be(Tenant);
        order.CustomerName.Should().Be("Ada Lovelace");
        order.TotalAmount.Should().Be(42.50m);
        order.Status.Should().Be(OrderStatus.Pending);
        order.CreatedAt.Should().BeCloseTo(DateTimeOffset.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public void Create_ValidInput_RaisesOrderCreatedEvent()
    {
        // Act
        var order = Order.Create(Tenant, "Ada Lovelace", 10m);

        // Assert
        var domainEvent = order.DomainEvents.Should().ContainSingle()
            .Which.Should().BeOfType<OrderCreatedEvent>().Subject;
        domainEvent.OrderId.Should().Be(order.Id);
        domainEvent.TenantId.Should().Be(Tenant);
        domainEvent.OccurredAt.Should().Be(order.CreatedAt);
    }

    [Fact]
    public void ClearDomainEvents_AfterCreate_RemovesEvents()
    {
        // Arrange
        var order = Order.Create(Tenant, "Ada Lovelace", 10m);

        // Act
        order.ClearDomainEvents();

        // Assert
        order.DomainEvents.Should().BeEmpty();
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Create_NonPositiveTotalAmount_Throws(decimal totalAmount)
    {
        // Act
        var act = () => Order.Create(Tenant, "Ada Lovelace", totalAmount);

        // Assert
        act.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_BlankCustomerName_Throws(string customerName)
    {
        // Act
        var act = () => Order.Create(Tenant, customerName, 10m);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Create_CustomerNameTooLong_Throws()
    {
        // Act
        var act = () => Order.Create(Tenant, new string('x', Order.CustomerNameMaxLength + 1), 10m);

        // Assert
        act.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void Equals_SameId_AreEqual()
    {
        // Arrange
        var order = Order.Create(Tenant, "Ada Lovelace", 10m);
        var other = Order.Create(Tenant, "Grace Hopper", 20m);

        // Assert
        order.Should().Be(order);
        order.Should().NotBe(other);
    }
}

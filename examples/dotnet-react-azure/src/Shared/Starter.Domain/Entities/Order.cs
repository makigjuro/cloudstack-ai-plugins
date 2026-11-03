using Starter.Domain.Abstractions;
using Starter.Domain.Events;
using Starter.Domain.ValueObjects;

namespace Starter.Domain.Entities;

public class Order : AggregateRoot<OrderId>
{
    public const int CustomerNameMaxLength = 200;

    public TenantId TenantId { get; private set; }
    public string CustomerName { get; private set; }
    public decimal TotalAmount { get; private set; }
    public OrderStatus Status { get; private set; }
    public DateTimeOffset CreatedAt { get; private set; }

    // EF Core constructor
    protected Order() : base(default!)
    {
        TenantId = default!;
        CustomerName = default!;
    }

    // Private constructor called by factory method
    private Order(OrderId id, TenantId tenantId, string customerName, decimal totalAmount, DateTimeOffset createdAt)
        : base(id)
    {
        TenantId = tenantId;
        CustomerName = customerName;
        TotalAmount = totalAmount;
        Status = OrderStatus.Pending;
        CreatedAt = createdAt;
    }

    // Factory method - the ONLY way to create instances.
    // Input is validated at the application boundary (CreateOrderValidator); these guards
    // protect the invariants against programmer errors only.
    public static Order Create(TenantId tenantId, string customerName, decimal totalAmount)
    {
        ArgumentNullException.ThrowIfNull(tenantId);
        ArgumentException.ThrowIfNullOrWhiteSpace(customerName);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(customerName.Trim().Length, CustomerNameMaxLength, nameof(customerName));
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(totalAmount);

        var id = OrderId.New();
        var createdAt = DateTimeOffset.UtcNow;
        var order = new Order(id, tenantId, customerName.Trim(), totalAmount, createdAt);
        order.RaiseDomainEvent(new OrderCreatedEvent(id, tenantId, createdAt));
        return order;
    }
}

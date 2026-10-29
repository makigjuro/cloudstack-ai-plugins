using Starter.Domain.Abstractions;
using Starter.Domain.ValueObjects;

namespace Starter.Domain.Events;

public class OrderCreatedEvent : DomainEvent
{
    public OrderId OrderId { get; }
    public TenantId TenantId { get; }
    public DateTimeOffset OccurredAt { get; }

    public OrderCreatedEvent(OrderId orderId, TenantId tenantId, DateTimeOffset occurredAt)
    {
        OrderId = orderId;
        TenantId = tenantId;
        OccurredAt = occurredAt;
    }
}

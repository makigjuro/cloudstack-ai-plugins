using Microsoft.Extensions.Logging;
using Starter.Domain.Events;

namespace Starter.Orders.Application.Events;

/// <summary>
/// Reacts to <see cref="OrderCreatedEvent"/>. Discovered by WolverineFx by convention.
/// This starter only logs; replace with read-model updates, notifications or integration events.
/// Logging is naturally idempotent, so redelivery is safe.
/// </summary>
public class OrderCreatedEventHandler
{
    private readonly ILogger<OrderCreatedEventHandler> _logger;

    public OrderCreatedEventHandler(ILogger<OrderCreatedEventHandler> logger)
    {
        _logger = logger;
    }

    public Task Handle(OrderCreatedEvent @event, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(@event);

        _logger.LogInformation(
            "Handling {Event} for order {OrderId} in tenant {TenantId} (event {EventId})",
            nameof(OrderCreatedEvent),
            @event.OrderId.Value,
            @event.TenantId.Value,
            @event.EventId);

        return Task.CompletedTask;
    }
}

using Starter.Domain.Abstractions;
using Wolverine;

namespace Starter.Shared.Infrastructure.Messaging;

/// <summary>
/// Publishes domain events to WolverineFx. Handlers are discovered by convention
/// (e.g. <c>OrderCreatedEventHandler.Handle(OrderCreatedEvent, CancellationToken)</c>).
/// </summary>
public sealed class WolverineDomainEventDispatcher : IDomainEventDispatcher
{
    private readonly IMessageBus _messageBus;

    public WolverineDomainEventDispatcher(IMessageBus messageBus)
    {
        _messageBus = messageBus;
    }

    public async Task DispatchAsync(IEnumerable<DomainEvent> domainEvents, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(domainEvents);

        foreach (var domainEvent in domainEvents)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await _messageBus.PublishAsync(domainEvent);
        }
    }
}

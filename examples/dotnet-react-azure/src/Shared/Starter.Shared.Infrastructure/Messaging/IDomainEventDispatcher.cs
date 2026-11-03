using Starter.Domain.Abstractions;

namespace Starter.Shared.Infrastructure.Messaging;

/// <summary>
/// Publishes domain events collected from aggregates after they have been persisted.
/// </summary>
public interface IDomainEventDispatcher
{
    Task DispatchAsync(IEnumerable<DomainEvent> domainEvents, CancellationToken cancellationToken = default);
}

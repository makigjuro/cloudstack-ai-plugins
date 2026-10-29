namespace Starter.Domain.Abstractions;

/// <summary>
/// Base class for domain events. Concrete events are named in past tense and carry only the data consumers need.
/// </summary>
public abstract class DomainEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
}

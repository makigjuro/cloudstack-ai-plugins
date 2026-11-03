namespace Starter.Domain.Abstractions;

/// <summary>
/// Marker for domain events raised by aggregate roots.
/// </summary>
public interface IDomainEvent
{
    Guid EventId { get; }
}

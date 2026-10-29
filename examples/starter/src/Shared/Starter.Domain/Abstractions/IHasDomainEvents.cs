namespace Starter.Domain.Abstractions;

/// <summary>
/// Lets infrastructure collect and clear domain events without knowing the aggregate's ID type.
/// </summary>
public interface IHasDomainEvents
{
    IReadOnlyCollection<DomainEvent> DomainEvents { get; }

    void ClearDomainEvents();
}

namespace Starter.Domain.Abstractions;

/// <summary>
/// Base class for entities. Identity equality is based on the strongly-typed ID only.
/// </summary>
public abstract class Entity<TId> : IEquatable<Entity<TId>>
    where TId : ValueObject
{
    protected Entity(TId id)
    {
        Id = id;
    }

    public TId Id { get; protected set; }

    public bool Equals(Entity<TId>? other) =>
        other is not null && other.GetType() == GetType() && Id == other.Id;

    public override bool Equals(object? obj) => obj is Entity<TId> other && Equals(other);

    public override int GetHashCode() => Id?.GetHashCode() ?? 0;

    public static bool operator ==(Entity<TId>? left, Entity<TId>? right) => Equals(left, right);

    public static bool operator !=(Entity<TId>? left, Entity<TId>? right) => !Equals(left, right);
}

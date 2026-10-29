using Starter.Domain.Abstractions;

namespace Starter.Domain.ValueObjects;

public class OrderId : ValueObject
{
    public Guid Value { get; init; }

    public OrderId(Guid value)
    {
        if (value == Guid.Empty)
            throw new ArgumentException("OrderId cannot be empty.", nameof(value));
        Value = value;
    }

    public static OrderId New() => new(Guid.NewGuid());

    public override string ToString() => Value.ToString();

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }
}

using Starter.Domain.Abstractions;

namespace Starter.Domain.ValueObjects;

public class TenantId : ValueObject
{
    public Guid Value { get; init; }

    public TenantId(Guid value)
    {
        if (value == Guid.Empty)
            throw new ArgumentException("TenantId cannot be empty.", nameof(value));
        Value = value;
    }

    public override string ToString() => Value.ToString();

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value;
    }
}

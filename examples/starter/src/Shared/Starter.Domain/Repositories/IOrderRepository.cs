using Starter.Domain.Entities;
using Starter.Domain.ValueObjects;

namespace Starter.Domain.Repositories;

/// <summary>
/// Command-side port for the Order aggregate (mutations).
/// </summary>
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(OrderId id, CancellationToken cancellationToken = default);
    Task AddAsync(Order entity, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}

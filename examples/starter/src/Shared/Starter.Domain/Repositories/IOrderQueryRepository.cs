using Starter.Domain.Entities;
using Starter.Domain.ValueObjects;

namespace Starter.Domain.Repositories;

/// <summary>
/// Query-side port for the Order aggregate (read-only, no change tracking).
/// </summary>
public interface IOrderQueryRepository
{
    Task<Order?> GetByIdAsync(OrderId id, CancellationToken cancellationToken = default);
    Task<(IReadOnlyCollection<Order> Items, int TotalCount)> ListAsync(TenantId tenantId, int page, int pageSize, CancellationToken cancellationToken = default);
}

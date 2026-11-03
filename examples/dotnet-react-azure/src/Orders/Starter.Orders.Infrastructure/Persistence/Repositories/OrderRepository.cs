using Microsoft.EntityFrameworkCore;
using Starter.Domain.Abstractions;
using Starter.Domain.Entities;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Shared.Infrastructure.Messaging;

namespace Starter.Orders.Infrastructure.Persistence.Repositories;

/// <summary>
/// EF Core adapter for both Order ports. Writes are change-tracked; the query side is explicit
/// (<see cref="IOrderQueryRepository"/>) and uses no-tracking reads.
/// </summary>
public class OrderRepository : IOrderRepository, IOrderQueryRepository
{
    private readonly OrdersDbContext _dbContext;
    private readonly IDomainEventDispatcher _domainEventDispatcher;

    public OrderRepository(OrdersDbContext dbContext, IDomainEventDispatcher domainEventDispatcher)
    {
        _dbContext = dbContext;
        _domainEventDispatcher = domainEventDispatcher;
    }

    public async Task<Order?> GetByIdAsync(OrderId id, CancellationToken cancellationToken = default) =>
        await _dbContext.Orders.FindAsync([id], cancellationToken);

    public async Task AddAsync(Order entity, CancellationToken cancellationToken = default) =>
        await _dbContext.Orders.AddAsync(entity, cancellationToken);

    /// <summary>Persists changes, then publishes the domain events raised by the saved aggregates.</summary>
    public async Task SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var aggregates = _dbContext.ChangeTracker
            .Entries<IHasDomainEvents>()
            .Select(entry => entry.Entity)
            .Where(aggregate => aggregate.DomainEvents.Count > 0)
            .ToList();

        var domainEvents = aggregates.SelectMany(aggregate => aggregate.DomainEvents).ToList();

        await _dbContext.SaveChangesAsync(cancellationToken);

        aggregates.ForEach(aggregate => aggregate.ClearDomainEvents());
        await _domainEventDispatcher.DispatchAsync(domainEvents, cancellationToken);
    }

    async Task<Order?> IOrderQueryRepository.GetByIdAsync(OrderId id, CancellationToken cancellationToken) =>
        await _dbContext.Orders
            .AsNoTracking()
            .FirstOrDefaultAsync(order => order.Id == id, cancellationToken);

    public async Task<(IReadOnlyCollection<Order> Items, int TotalCount)> ListAsync(
        TenantId tenantId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var query = _dbContext.Orders
            .AsNoTracking()
            .Where(order => order.TenantId == tenantId);

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(order => order.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalCount);
    }
}

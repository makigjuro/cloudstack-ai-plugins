using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Starter.Domain.Abstractions;
using Starter.Domain.Entities;

namespace Starter.Orders.Infrastructure.Persistence;

public class OrdersDbContext : DbContext
{
    public const string Schema = "orders";

    public OrdersDbContext(DbContextOptions<OrdersDbContext> options) : base(options)
    {
    }

    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        modelBuilder.HasDefaultSchema(Schema);
        modelBuilder.Ignore<DomainEvent>();
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}

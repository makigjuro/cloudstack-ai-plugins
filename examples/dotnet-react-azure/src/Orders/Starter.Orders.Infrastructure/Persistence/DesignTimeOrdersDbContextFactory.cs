using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Starter.Orders.Infrastructure.Persistence;

/// <summary>
/// Used only by <c>dotnet ef</c> so migrations can be generated without starting the host.
/// Reads ConnectionStrings__Orders when set; the fallback points at the local compose database and
/// carries no credentials.
/// </summary>
public sealed class DesignTimeOrdersDbContextFactory : IDesignTimeDbContextFactory<OrdersDbContext>
{
    public OrdersDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Orders")
            ?? "Host=localhost;Port=5432;Database=starter";

        var options = new DbContextOptionsBuilder<OrdersDbContext>()
            .UseNpgsql(connectionString, npgsql => npgsql.MigrationsHistoryTable(DependencyInjection.MigrationsHistoryTable, OrdersDbContext.Schema))
            .Options;

        return new OrdersDbContext(options);
    }
}

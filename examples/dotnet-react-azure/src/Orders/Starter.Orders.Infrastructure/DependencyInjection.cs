using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Starter.Domain.Repositories;
using Starter.Orders.Infrastructure.Persistence;
using Starter.Orders.Infrastructure.Persistence.Repositories;
using Starter.Shared.Infrastructure.Messaging;

namespace Starter.Orders.Infrastructure;

public static class DependencyInjection
{
    public const string ConnectionStringName = "Orders";
    public const string MigrationsHistoryTable = "__EFMigrationsHistory";
    public const string ReadyTag = "ready";

    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddPersistence(configuration);

        services.AddScoped<OrderRepository>();
        services.AddScoped<IOrderRepository>(sp => sp.GetRequiredService<OrderRepository>());
        services.AddScoped<IOrderQueryRepository>(sp => sp.GetRequiredService<OrderRepository>());
        services.AddScoped<IDomainEventDispatcher, WolverineDomainEventDispatcher>();

        services.AddHealthChecks()
            .AddDbContextCheck<OrdersDbContext>("orders-db", tags: [ReadyTag]);

        return services;
    }

    /// <summary>
    /// Registers only the <see cref="OrdersDbContext"/>. The <c>--migrate</c> job uses this on its own,
    /// because it has no message bus and must not depend on anything beyond the database.
    /// </summary>
    public static IServiceCollection AddPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(configuration);

        // Resolved lazily so hosts/tests can provide ConnectionStrings:Orders at any configuration stage.
        services.AddDbContext<OrdersDbContext>((serviceProvider, options) =>
        {
            var connectionString = serviceProvider.GetRequiredService<IConfiguration>().GetConnectionString(ConnectionStringName);
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new InvalidOperationException($"Connection string '{ConnectionStringName}' is not configured.");

            options.UseNpgsql(connectionString, npgsql => npgsql.MigrationsHistoryTable(MigrationsHistoryTable, OrdersDbContext.Schema));
        });

        return services;
    }
}

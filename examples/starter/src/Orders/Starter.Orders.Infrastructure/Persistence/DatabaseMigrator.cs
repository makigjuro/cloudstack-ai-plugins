using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Starter.Orders.Infrastructure.Persistence;

/// <summary>
/// Applies pending EF Core migrations. Invoked by the host's <c>--migrate</c> mode, which runs as a
/// one-shot job (Azure Container Apps Job / docker compose service) before new revisions get traffic.
/// </summary>
public static partial class DatabaseMigrator
{
    public static async Task MigrateAsync(IServiceProvider services, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(services);

        await using var scope = services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(DatabaseMigrator));

        var pending = (await dbContext.Database.GetPendingMigrationsAsync(cancellationToken)).ToList();
        LogPendingMigrations(logger, pending.Count, string.Join(", ", pending));

        await dbContext.Database.MigrateAsync(cancellationToken);

        LogMigrationsApplied(logger);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Applying {Count} pending migration(s): {Migrations}")]
    private static partial void LogPendingMigrations(ILogger logger, int count, string migrations);

    [LoggerMessage(Level = LogLevel.Information, Message = "Database is up to date")]
    private static partial void LogMigrationsApplied(ILogger logger);
}
